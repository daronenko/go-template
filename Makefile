RED = \033[31m
GREEN = \033[32m
YELLOW = \033[33m
BLUE = \033[34m
RESET = \033[0m

DEPLOY_ROOT = ./deploy
DEPLOY_PATH = $(shell find $(DEPLOY_ROOT) -type d -mindepth 1 -maxdepth 1)

SERVICE_PATH = ./service

################################################################################
# Miscellaneous
################################################################################

.PHONY: help
## (default) Show help page.
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)";echo;sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|awk -F --- -v n=$$(tput cols) -v i=29 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n\n";}'

################################################################################
# Deploy
################################################################################

.PHONY: cluster
## Create `minikube` cluster and change context to it.
cluster:
	@minikube start
	@kubectl config use-context minikube

.PHONY: delete-cluster
## Delete `minikube` cluster.
delete-cluster:
	@minikube delete --profile minikube

.PHONY: deploy-apply
## Run `kubectl apply` for all k8s manifests.
deploy-apply:
	@for dir in $(DEPLOY_PATH); do \
		echo "$(GREEN)Processing kustomization in $$dir$(RESET)"; \
		kubectl apply -k $$dir; \
	done

.PHONY: port-forwarding
## Forward port to the cluster.
port-forwarding:
	@sudo kubectl -n ingress-nginx port-forward service/ingress-nginx-controller 443

DEFAULT_NAMESPACE_FLAG := --all-namespaces

.PHONY: deploy-delete-%
## Delete all resources of specified type in all namespaces by default.
## Available resources: pods, deployments, services, etc.
## Format: `deploy-delete-<resource> [namespace=<namespace>]`.
## Example: `deploy-delete-pods namespace=monitoring`.
deploy-delete-%:
	@echo "$(GREEN)Deleting resource: $*$(RESET)"
	@NAMESPACE_FLAG=$(DEFAULT_NAMESPACE_FLAG); \
	if [ -n "$${namespace}" ]; then \
		NAMESPACE_FLAG="--namespace=$${namespace}"; \
	fi; \
	\
	kubectl delete --all $* $$NAMESPACE_FLAG

.PHONY: deploy-delete-all
## Delete all resources of all types in all namespaces by default.
## Format: `deploy-delete-all [namespace=<namespace>]`.
deploy-delete-all: deploy-delete-pods deploy-delete-deployments deploy-delete-services deploy-delete-configmaps deploy-delete-pvc

.PHONY: deploy
## Run deploy script (`scripts/deploy.sh`).
deploy:
	@sh scripts/deploy.sh

################################################################################
# Database Migrations
################################################################################

service ?= undefined

MIGRATIONS_PATH = ./service/$(service)/internal/db/$*/migrations
MIGRATIONS_DEPLOY_PATH = ./deploy/$(service)/$*/migrations/migrations.yaml
MIGRATE_JOB_PATH = ./deploy/$(service)/$*/migrations/migrate-job.yaml

.PHONY: deploy-%-migration
## Copy all database migrations for specified database of microservice.
## Available databases: postgres, mysql, sqlite3, mssql, redshift, tidb,
## clickhouse, vertica, ydb.
## Format: `deploy-<database>-migration service=<service>`.
## Example: `deploy-postgres-migration service=hello`.
deploy-%-migration:
	@kubectl create configmap $(service)-$*-migrations-content --from-file=$(MIGRATIONS_PATH) --dry-run=client -o yaml > $(MIGRATIONS_PATH_DEPLOY)
	@echo "$(GREEN)File created: $(MIGRATIONS_DEPLOY_PATH)$(RESET)\n"

.PHONY: deploy-%-migrate
## Run k8s job that applies for specified database of microservice.
## Available databases: postgres, mysql, sqlite3, mssql, redshift, tidb,
## clickhouse, vertica, ydb.
## Format: `deploy-<database>-migrate service=<service>`.
## Example: `deploy-postgres-migrate service=hello`.
deploy-%-migrate:
	@kubectl apply -f $(MIGRATE_JOB_PATH)
	@echo "$(GREEN)Migrate job started...$(RESET)"

################################################################################
# Integration of Services
################################################################################

.PHONY: docker-%-all
## Run `make docker-%` command for all microservices.
## Available commands: start, stop, clean.
## Format: `docker-<command>-all`.
## Example: `docker-start-all`.
docker-%-all:
	@for dir in $(shell find service/* -maxdepth 0 -type d); do \
		echo "$(GREEN)Running 'make docker-$*' in $$dir...$(RESET)"; \
		$(MAKE) -C $$dir docker-$*; \
	done
