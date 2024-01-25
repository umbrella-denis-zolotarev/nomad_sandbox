#!make

DOCKER_COMPOSE_CMD = docker-compose

# docker

build:
	$(DOCKER_COMPOSE_CMD) build --no-cache

status:
	$(DOCKER_COMPOSE_CMD) ps
up:
	$(DOCKER_COMPOSE_CMD) up -d
	@$(MAKE) --no-print-directory status
stop:
	$(DOCKER_COMPOSE_CMD) stop
	@$(MAKE) status

restart: stop up


# logs
logs-nomad:
	$(DOCKER_COMPOSE_CMD) logs -f nomad_in_docker


# bash/sh
console-nomad:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker bash

console-consul:
	$(DOCKER_COMPOSE_CMD) exec consul_server sh

nomad-node-status:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad node status

####
#### job sandbox
####

## можно подменить JOB_POSTFIX на другой из комментов, тогда команды ниже будут с другими джобами работать
JOB_POSTFIX=nginx
#JOB_POSTFIX=redis
JOB_NAME=job-$(JOB_POSTFIX)
JOB_PATH=/demo_jobs/job.$(JOB_POSTFIX).nomad
NOMAD_ADDRESS=-address=http://nomad_in_docker:4646
# проверить конфиг джобы
job-validate:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad validate $(NOMAD_ADDRESS) $(JOB_PATH)
# запустить/перезапустить джобу
job-run:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad run $(NOMAD_ADDRESS) $(JOB_PATH)
# список запущенных джоб
job-status:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad job status $(NOMAD_ADDRESS)
# остановить джобу по имени
job-stop:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad job stop $(NOMAD_ADDRESS) $(JOB_NAME)
# история запуска джобы (alloc - это инфо о запуске)
job-allocs:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad job allocs $(NOMAD_ADDRESS) $(JOB_NAME)
# получение последнего ид запуска джобы
FIND_ALLOC_ID_QUERY=nomad job allocs $(NOMAD_ADDRESS) $(JOB_NAME) | grep running | awk '{print $$1}'
ALLOC_ID ?= $(shell ($(DOCKER_COMPOSE_CMD) exec nomad_in_docker $(FIND_ALLOC_ID_QUERY)))
job-last-alloc-id:
	@echo $(ALLOC_ID)
# статус последнего запуска джобы
job-last-alloc-status:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad alloc status $(NOMAD_ADDRESS) $(ALLOC_ID)

####
#### other jobs
####
job-run-redis:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker nomad run $(NOMAD_ADDRESS) /demo_jobs/job.redis.nomad

# dev
nomad-generate-gossip-secret:
	$(DOCKER_COMPOSE_CMD) exec nomad_in_docker openssl rand -base64 16
whoami:
	$(DOCKER_COMPOSE_CMD) exec --user nobody nomad_in_docker whoami
users:
	$(DOCKER_COMPOSE_CMD) exec --user nobody nomad_in_docker cat /etc/passwd
