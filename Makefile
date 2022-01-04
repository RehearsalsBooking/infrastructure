#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

SHELL = /bin/sh

docker_bin := $(shell command -v docker 2> /dev/null)
docker_compose_bin := $(shell command -v docker-compose 2> /dev/null)
docker_compose_base_yml := base/docker-compose.build.yml
docker_compose_prod_yml := docker-compose.yml
backend_service := backend
backend_demo_service := backend-demo
frontend_service := frontend
frontend_demo_service := frontend-demo
landing_service := landing

.PHONY : help pull build push login test clean \
         app-pull app app-push\
         sources-pull sources sources-push\
         nginx-pull nginx nginx-push\
         up down restart shell install
.DEFAULT_GOAL := help

# --- [ Development tasks ] -------------------------------------------------------------------------------------------
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

update-base: ## Build and push base containers
	$(docker_compose_bin) --file "$(docker_compose_base_yml)" pull
	$(docker_compose_bin) --file "$(docker_compose_base_yml)" build --no-cache
	$(docker_compose_bin) --file "$(docker_compose_base_yml)" push


deploy: check-environment
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" pull
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" down -v --remove-orphans
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" up -d

	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan storage:link
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan migrate --force
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan config:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan route:cache

	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan migrate:fresh --force --seed
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan config:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan route:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan key:generate

deploy-backend: check-environment
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" pull
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" up -d --no-deps "$(backend_service) $(backend_demo_service)"

	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan storage:link
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan migrate --force
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan config:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_service)" php artisan route:cache

	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan migrate:fresh --force --seed
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan config:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan route:cache
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" exec -T "$(backend_demo_service)" php artisan key:generate

deploy-frontend: check-environment
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" pull
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" up -d --no-deps "$(frontend_service) $(frontend_demo_service)"

deploy-landing: check-environment
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" pull
	$(docker_compose_bin) --file "$(docker_compose_prod_yml)" up -d --no-deps "$(landing_service)"

check-environment:
ifeq ("$(wildcard .env)","")
	- @echo Copying ".env.example";
	- cp .env.example .env
endif
ifeq ("$(wildcard .env.backend)","")
	- @echo Copying ".env.backend.example";
	- cp .env.backend.example .env.backend
endif
ifeq ("$(wildcard .env.backend-demo)","")
	- @echo Copying ".env.backend-demo.example";
	- cp .env.backend-demo.example .env.backend-demo
endif
