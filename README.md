# Docker Unbound + PiHole

## Build and Deployment

To build:

``` console
$ make build # build the entire project, or:
$ docker compose build --pull --parallel # flags optional
```

To run after build:

``` console
$ make start # start the entire project, or:
$ docker compose up --detach --remove-orphans # flags optional
```

## Components
See the following links to docker images for how to configure the components in use.

[Docker image (subtree at "/vendor/docker-unbound")](https://github.com/MatthewVance/unbound-docker) for [unbound](https://github.com/NLnetLabs/unbound).

[Docker image](https://github.com/pi-hole/docker-pi-hole) for [pihole](https://github.com/pi-hole/pi-hole).
