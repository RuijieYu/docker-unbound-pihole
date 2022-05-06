#!/bin/sh -e
# -*- fill-column: 80; -*-
# (Note that --long-option=parameter not allowed)
#
# $0 [options] [--] command [args...]
#
# Options:
## -t <interval> | --repeat <interval>
### <interval> is a time interval value acceptable from sleep(1); default = 1m
## -s <errcodes> | --success <errcodes>
### <errcodes> is a comma-separated integers as acceptable return
### codes treated as success.  When a command fails, $0 exits.

REPEAT=1m
SUCCESS=

while :; do
    case "$1" in
    -t | --repeat)
        REPEAT="$2"
        shift
        ;;
    -s | --success)
        SUCCESS="$2"
        shift
        ;;
    - | --)
        shift
        break
        ;;
    esac
    shift
done

# now "$@" should be the array of full command

# run in a protected environment to check for return code
# "$@" : full command
protect() {
    # do not exit right away; save return code
    set +e
    "$@"
    ret="$?"
    set -e

    # use comma as temporary IFS and check if success
    OLD_IFS="$IFS" IFS=,
    is_success $SUCCESS
    IFS="$OLD_IFS"
}

# $ret = return code, $@ = success codes
is_success() {
    # it is native success -> success
    test "$ret" -ne 0 || return 0

    # no more success codes -> fail
    test "$#" -gt 0 || return "$ret"

    # first is match
    test "$ret" -ne "$1" || return 0

    # rest of list
    shift
    is_success "$@"
}

do_sleep() { sleep "$REPEAT"; }

main() {
    while :; do
        protect "$@"
        do_sleep
    done
}

main "$@"
