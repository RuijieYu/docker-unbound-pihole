UNBOUND_VERSION = 1.15.0
UNBOUND_DOCKERFILE = vendor/docker-unbound/$(UNBOUND_VERSION)/Dockerfile

PIHOLE_ADLIST_LOCAL_FILE = adlists.list
PIHOLE_ADLIST_DEST_FILE = pihole/etc/adlists.list

ADLIST_DOCKERFILE = assets/pihole-adlist.containerfile

DUP_COMPONENTS = unbound pihole
DUP_FILES = docker-compose.yml Makefile
DUP_FILES += $(UNBOUND_DOCKERFILE)
# DUP_FILES += $(ADLIST_DOCKERFILE)

.PHONY: start
start: .start
.start: $(UNBOUND_DOCKERFILE) $(DUP_COMPONENTS)
	sudo docker compose up --build --detach --remove-orphans
	@touch $@

.PHONY: stop
stop:
	sudo docker compose down
	$(RM) .start

.PHONY: restart
restart:
	sudo docker compose restart
	touch .start

.PHONY: build
build: docker-compose.yml $(UNBOUND_DOCKERFILE) Makefile
	sudo docker compose build

.PHONY: $(patsubst %,logs-%,$(DUP_COMPONENTS))
$(patsubst %,logs-%,$(DUP_COMPONENTS)): logs-%: start
	sudo docker logs dup-$*

.PHONY: $(patsubst %,shell-%,$(DUP_COMPONENTS))
$(patsubst %,shell-%,$(DUP_COMPONENTS)): shell-%: start
	sudo docker exec -it dup-$* bash

.PHONY: passwd-pihole
passwd-pihole: passwd-%: start
	sudo docker exec -it dup-$* pihole -a -p

# # apparently dest-file is overwritten randomly, so DEST newer than LOCAL
# # if DEST newer than TAG, then run?
# .PHONY: adlist
# adlist:
# .adlist: $(PIHOLE_ADLIST_LOCAL_FILE)
#	touch .adlist
# $(PIHOLE_ADLIST_LOCAL_FILE): $(PIHOLE_ADLIST_DEST_FILE)
#	touch $(PIHOLE_ADLIST_LOCAL_FILE)
#	sudo install -Dvm0444 $(PIHOLE_ADLIST_LOCAL_FILE) -T $(PIHOLE_ADLIST_DEST_FILE)
#	touch $(PIHOLE_ADLIST_LOCAL_FILE)

# $(MAKE) stop
