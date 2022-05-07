PROJECT_NAME = dup

UNBOUND_VERSION = 1.15.0
UNBOUND_DOCKERFILE = vendor/docker-unbound/$(UNBOUND_VERSION)/Dockerfile

DUP_COMPONENTS = unbound pihole
DUP_FILES = docker-compose.yml Makefile
DUP_FILES += $(UNBOUND_DOCKERFILE)

.DEFAULT_GOAL: start

.PHONY: start build
start build: %: .stages/% | .stages/

.stages/start: build
	sudo docker compose -p $(PROJECT_NAME) up --detach --remove-orphans
	@touch $@

.PHONY: stop
stop: | .stages/
	sudo docker compose -p $(PROJECT_NAME) down
	$(RM) .stages/start

.PHONY: restart
restart: | .stages/
	sudo docker compose -p $(PROJECT_NAME) restart
	touch .stages/start

.PHONY: build
.stages/build: $(UNBOUND_DOCKERFILE) $(DUP_COMPONENTS) | .stages/
	sudo docker compose -p $(PROJECT_NAME) build --parallel

.PHONY: $(patsubst %,logs-%,$(DUP_COMPONENTS))
$(patsubst %,logs-%,$(DUP_COMPONENTS)): logs-%: start
	sudo docker logs dup-$*

.PHONY: $(patsubst %,shell-%,$(DUP_COMPONENTS))
$(patsubst %,shell-%,$(DUP_COMPONENTS)): shell-%: start
	sudo docker exec -it dup-$* bash

.PHONY: passwd-pihole
passwd-pihole: passwd-%: start
	sudo docker exec -it dup-$* pihole -a -p

%/:
	mkdir -p $@
