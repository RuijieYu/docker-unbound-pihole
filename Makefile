UNBOUND_VERSION := 1.15.0
UNBOUND_DOCKERFILE := vendor/docker-unbound/$(UNBOUND_VERSION)/Dockerfile

.PHONY: start
start: docker-compose.yml $(UNBOUND_DOCKERFILE)
	sudo docker compose up --build --detach

.PHONY: stop
stop:
	sudo docker compose down

.PHONY: build
build: docker-compose.yml $(UNBOUND_DOCKERFILE)
	sudo docker compose build

.PHONY: logs-pihole
logs-pihole:
	sudo docker logs dup-pihole
