#!/bin/sh -e
#  -*- fill-column: 80; -*-
#
# Since pihole v5, updates to the adlist are done directly to the underlying
# SQLite database.  The script should only be run after the gravity.db file is
# created -- and will automatically run `pihole -g` when something has been
# inserted into the database because of this script.
#
# ref:
# https://discourse.pi-hole.net/t/restoring-default-pi-hole-adlist-s/32323
#
# Return codes:
## 4
### SQLite3 error
## 8
### DB file absent
## 10
### adlists file absent or unable to read
## 12
### (unlikely) cannot write to temp file generated from `mktemp`
#
# $1 = name of a NL-separated file, each with a comment or a URL to a file
# $2 = name of gravity database file, default /etc/pihole/gravity.db
# $3 = (internal) file to save temporary query for inspection
# $NO_SQL_UPDATE = (internal) do not execute sql

show_help() {
    echo "$0 <adlists> <dbfile>"
    exit
}

case "$1" in
'' | -h | --help) show_help ;;
esac

readonly ADLISTS="${1:-/etc/pihole/update-adlists.list}"
readonly DB_FILE="${2:-/etc/pihole/gravity.db}"
readonly SAVE_QUERY_FILE="$3"

readonly QCOMMENT="\"migrated from '$(basename "$ADLISTS")' using '$(basename "$0")'\""

readonly QUERY_FILE="$(mktemp)"
exec 3>"$QUERY_FILE" || exit 12

# the comma after each row -- I don't see a way to update global variables in
# busybox sh, so use a file to simulate it
readonly PREFIX_FILE="$(mktemp)"

# sqlite insert or ignore.  ref: https://stackoverflow.com/a/19343100
echo 'INSERT OR IGNORE INTO adlist(address,comment)VALUES' >&3

# $1 = url
query_append() {
    cat "$PREFIX_FILE"
    echo "(\"$1\",$QCOMMENT)"
    echo , >"$PREFIX_FILE"
} >&3

query_exec() {
    echo \; >&3
    exec 3>&-

    # maybe save query
    save_query

    # do not update gravity when asked not to
    test -n "$NO_SQL_UPDATE" || {
        { # when sql fails, exit 4
            sqlite3 -bail -cmd '.changes on' -nofollow "$DB_FILE" <"$QUERY_FILE" || return 4
        } |
            { # when something has changed, update pihole
                grep -Pq '^changes:[[:space:]]*0[[:space:]]' || pihole -g
            }
    }
}

ensure_db() { test -f "$DB_FILE" -a -r "$DB_FILE" -a -w "$DB_FILE" || return 8; }

save_query() {
    # save query when requested
    test -z "$SAVE_QUERY_FILE" ||
        cp -T "$QUERY_FILE" "$SAVE_QUERY_FILE"
}

populate() {
    # fail if ADLISTS file cannot be opened
    exec <"$1" || return 10
    # fail if DBFILE is problematic
    ensure_db

    # ignore comment lines
    { grep -P '^[[:space:]]*[^#]' || :; } |
        # ignore '"'; ignore backslash (sanitize inputs)
        { grep -ve \" -e \\ || :; } |
        while read url; do query_append "$url"; done

    query_exec
}

populate "$ADLISTS"
