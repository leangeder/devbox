.PHONY: service create update $(APP_NAME) $(APP_ENV) apps $(SERVICE_NAME) $(SERVICE_ENV)
.DEFAULT_GOAL := help

UNAME := $(shell uname -s | tr A-Z a-z)
ifeq ($(OS),Windows_NT)
	UNAME := windows_nt
endif
TIMESTAMP = $(shell date +%s )
CONTAINER := us.gcr.io/beamery
GO_VERSION := 1.10.2
HOME := $(shell echo $$HOME)
PATH_BEAMERY_ROOT := $(dir $(realpath $(shell meta-git location)))
PATH_BEAMERY_FOLDER := $(PATH_BEAMERY_ROOT)/devops-kubernetes-beamery
PATH_BEAMERY_META := $(PATH_BEAMERY_ROOT)/beamery-meta
PATH_ROOT_DOCKER_FOLDER := /tmp/devops-docker-images
PATH_PROJECT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH_TEMPLATE := templates
PATH_DESTINATION := deployment
SERVICE_LIST=$(shell find $(PATH_TEMPLATE)/services/ -maxdepth 1 -mindepth 1 -not -name ".*" -printf '%P\n')
APP_LIST=$(shell find $(PATH_BEAMERY_FOLDER)/$(PATH_TEMPLATE)/ -maxdepth 1 -mindepth 1 -type d -not -name ".*" -printf '%P\n')
SERVICE_ENV := dev
APP_ENV := dev

/usr/local/bin/meta-git:
	@mkdir -p $(PATH_BEAMERY_ROOT)
	@git clone git@github.com:SeedJobs/meta-git $(PATH_BEAMERY_ROOT)/meta-git
	@$(PATH_BEAMERY_ROOT)/meta-git/meta-git install

/usr/local/bin/minikube: $(PATH_BEAMERY_META)
	@curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-$(UNAME)-amd64
	@chmod +x minikube
	@sudo mv minikube /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe
endif

/usr/local/bin/kubectl:
	@curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(UNAME)/amd64/kubectl
	@chmod +x kubectl
	@sudo mv kubectl /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/windows/amd64/kubectl.exe
endif

/usr/local/bin/istioctl:
	@mkdir bin
	@cd bin; curl -L https://git.io/getLatestIstio | sh -
	@ln -sf bin/*/bin/istioctl /usr/local/bin/istioctl

/usr/local/bin/vortex:
	@sudo rm -rf /tmp/vortex
	@git clone git@github.com:AlexsJones/vortex.git /tmp/vortex
	@docker run --rm -ti -v /tmp/vortex/:/go -e GOBIN="/go/bin" -w /go golang:1.8.3 sh -c 'go get -v && go build -v -o vortex && chmod +x vortex'
	@sudo mv /tmp/vortex/vortex /usr/local/bin/

/usr/local/bin/go:
	@curl -Lo go$(GO_VERSION).tar.gz https://dl.google.com/go/go$(GO_VERSION).$(UNAME)-amd64.tar.gz
	@tar -C /usr/local -xzf go$(GO_VERSION).tar.gz
	@rm -f go$(GO_VERSION).tar.gz
	@ln -s /usr/local/lib/go/bin/go /usr/local/bin/go

ifeq (create,$(firstword $(MAKECMDGOALS)))
  APP_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  APP_NAME := $(firstword $(APP_ARGS))
ifneq ($(APP_NAME),$(lastword $(APP_ARGS)))
  APP_ENV := $(lastword $(APP_ARGS))
endif
ifeq (apps,$(APP_NAME))
  APP_NAME = $(APP_LIST)
endif
endif
ifeq (update,$(firstword $(MAKECMDGOALS)))
  APP_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  APP_NAME := $(firstword $(APP_ARGS))
ifeq (apps,$(APP_NAME))
  APP_NAME = $(APP_LIST)
endif
endif
ifeq (service,$(firstword $(MAKECMDGOALS)))
  SERVICE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  SERVICE_NAME := $(firstword $(SERVICE_ARGS))
ifneq ($(SERVICE_NAME),$(lastword $(SERVICE_ARGS)))
  SERVICE_ENV := $(lastword $(SERVICE_ARGS))
endif
ifeq (,$(SERVICE_NAME))
  SERVICE_NAME := $(SERVICE_LIST)
endif
endif

.baseimage: up $(PATH_ROOT_DOCKER_FOLDER)
	eval $$(minikube docker-env); cd $(PATH_ROOT_DOCKER_FOLDER); docker build -t $(CONTAINER)-preview/devops-node:latest -f node.Dockerfile .
	eval $$(minikube docker-env); cd $(PATH_ROOT_DOCKER_FOLDER); docker build -t $(CONTAINER)-preview/devops-nginx:latest -f nginx.Dockerfile .

$(PATH_ROOT_DOCKER_FOLDER):
	git clone git@github.com:SeedJobs/devops-docker-images.git $(PATH_ROOT_DOCKER_FOLDER)

$(PATH_BEAMERY_META):
	git clone git@github.com:SeedJobs/beamery-meta.git $(PATH_BEAMERY_META)
	cd $(PATH_BEAMERY_META); meta-git pull

$(PATH_BEAMERY_FOLDER):
	git clone git@github.com:SeedJobs/devops-kubernetes-beamery.git $(PATH_BEAMERY_FOLDER)

up: /usr/local/bin/kubectl /usr/local/bin/go /usr/local/bin/vortex /usr/local/bin/meta-git /usr/local/bin/minikube $(PATH_BEAMERY_FOLDER)
ifeq (0,$(shell minikube status | grep Running | wc -l))
	minikube config set WantReportErrorPrompt false
	minikube start --memory=6144 --extra-config=apiserver.authorization-mode=RBAC --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
	-minikube addons disable ingress
	-minikube addons disable heapster
endif

delete:
	kubectl delete -R -f $(PATH_PROJECT)/$(PATH_DESTINATION/ --force

$(SERVICE_ENV):;

$(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$(SERVICE_NAME) $(PATH_PROJECT)/environments/services/$(SERVICE_NAME): #| $(PATH_BEAMERY_ROOT)/devops-kubernetes-$(SERVICE_NAME)
ifeq (,$(wildcard $(PATH_BEAMERY_ROOT)/devops-kubernetes-$(SERVICE_NAME)/.*))
	git clone git@github.com:SeedJobs/devops-kubernetes-$(SERVICE_NAME).git $(PATH_BEAMERY_ROOT)/devops-kubernetes-$(SERVICE_NAME)
	cd $(PATH_BEAMERY_ROOT)/devops-kubernetes-$(SERVICE_NAME); git checkout features/add_minikube_support
endif
	mkdir -p $(PATH_PROJECT)/$(PATH_TEMPLATE)/services
	mkdir -p $(PATH_PROJECT)/environments/services
	ln -sf $(PATH_BEAMERY_ROOT)devops-kubernetes-$(SERVICE_NAME)/$(PATH_TEMPLATE) $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$(SERVICE_NAME)
	ln -sf $(PATH_BEAMERY_ROOT)devops-kubernetes-$(SERVICE_NAME)/environments $(PATH_PROJECT)/environments/services/$(SERVICE_NAME)

ifneq (mongodb,$(SERVICE_NAME))
ifneq (elasticsearch,$(SERVICE_NAME))
$(SERVICE_NAME): $(PATH_PROJECT)/environments/services/$(SERVICE_NAME) $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$(SERVICE_NAME) up
	rm -rf $(PATH_DESTINATION)/services/$@/
	vortex --template $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$@/ --output $(PATH_DESTINATION)/services/$@/ -varpath $(PATH_PROJECT)/environments/services/$@/$(SERVICE_ENV).yaml
	-kubectl apply -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml --overwrite
	rm -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml
	kubectl replace -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/ --force --validate
endif
endif

elasticsearch: $(PATH_PROJECT)/environments/services/$(SERVICE_NAME) $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$(SERVICE_NAME) up
	rm -rf $(PATH_DESTINATION)/services/$@/
	mkdir -p $(PATH_PROJECT)/files
	rm -f $(PATH_PROJECT)/files/$@
	ln -s $(PATH_BEAMERY_ROOT)devops-kubernetes-$@/files $(PATH_PROJECT)/files/$@
	kubectl create configmap config-jobs --namespace={{.namespace}} --from-file=$(PATH_TEMPLATE)/services/$@/rebuildElasticsearchIndices.sh --from-file=$(PATH_PROJECT)/files/$@/mappings_Seed_Activities.json --from-file=$(PATH_PROJECT)/files/$@/mappings_Seed_Contacts.json --from-file=$(PATH_PROJECT)/files/$@/mappings_Seed_Events.json --from-file=$(PATH_PROJECT)/files/$@/mappings_Seed_Organisations.json --from-file=$(PATH_PROJECT)/files/$@/mappings_Seed_VacancyActivities.json --dry-run -o yaml > $(PATH_TEMPLATE)/services/$@/config_job.yaml
	vortex --template $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$@/ --output $(PATH_DESTINATION)/services/$@/ -varpath $(PATH_PROJECT)/environments/services/$@/$(SERVICE_ENV).yaml
	-kubectl apply -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml --overwrite
	rm -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml
	kubectl replace -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/ --force --validate

mongodb: $(PATH_PROJECT)/environments/services/$(SERVICE_NAME) $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$(SERVICE_NAME) up
	rm -rf $(PATH_DESTINATION)/services/$@/
	TMPFILE=$$(mktemp); openssl rand -base64 741 > $$TMPFILE; kubectl create secret generic shared-bootstrap-data --from-file=internal-auth-mongodb-keyfile=$$TMPFILE --dry-run --namespace={{.namespace}} -o yaml > $(PATH_TEMPLATE)/services/$@/secret.yaml; rm $${TMPFILE}
	vortex --template $(PATH_PROJECT)/$(PATH_TEMPLATE)/services/$@/ --output $(PATH_DESTINATION)/services/$@/ -varpath $(PATH_PROJECT)/environments/services/$@/$(SERVICE_ENV).yaml
	-kubectl apply -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml --overwrite
	rm -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/namespace.yaml
	kubectl replace -f $(PATH_PROJECT)/$(PATH_DESTINATION)/services/$@/ --force --validate

update:

create: .baseimage $(PATH_BEAMERY_FOLDER);

apps: $(APP_LIST);

service: $(SERVICE_NAME) $(SERVICE_ENV);

$(APP_NAME):
ifeq (update,$(firstword $(MAKECMDGOALS)))
	eval $$(minikube docker-env); cd $(PATH_BEAMERY_META)/$@; docker build -t $@:$(TIMESTAMP) -f Dockerfile .;
	kubectl set image -f $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/$@/deployment.yaml $@=$@:$(TIMESTAMP)
else
	eval $$(minikube docker-env); cd $(PATH_BEAMERY_META)/$@; docker build -t $(CONTAINER)-$(APP_ENV)/$@:v-master-bleedingedge -f Dockerfile .;
	mkdir -p $(PATH_PROJECT)/environments/apps/$@
	ln -sf $(PATH_BEAMERY_FOLDER)/environments/$(APP_ENV).yaml $(PATH_PROJECT)/environments/apps/$@/$(APP_ENV).yaml
	mkdir -p $(PATH_PROJECT)/$(PATH_TEMPLATE)/apps/
	rm -f $(PATH_PROJECT)/$(PATH_TEMPLATE)/apps/$@
	ln -s $(PATH_BEAMERY_FOLDER)/$(PATH_TEMPLATE)/$@ $(PATH_PROJECT)/$(PATH_TEMPLATE)/apps/$@
	vortex --template $(PATH_PROJECT)/$(PATH_TEMPLATE)/apps/$@/ --output $(PATH_DESTINATION)/apps/$@/ -varpath $(PATH_PROJECT)/environments/apps/$@/$(APP_ENV).yaml
	openssl req -subj '/CN=*/' -x509 -batch -nodes -newkey rsa:2048 -keyout /tmp/lumberjack.key -out /tmp/lumberjack.crt
	-kubectl delete secret lumberjack-ssl --namespace=$(APP_ENV)
	-kubectl create ns $$(grep namespace $(PATH_PROJECT)/$(PATH_DESTINATION)/apps/$@/deployment.yaml | cut -d ' ' -f 4)
	-kubectl label namespace $$(grep namespace $(PATH_PROJECT)/$(PATH_DESTINATION)/apps/$@/deployment.yaml | cut -d ' ' -f 4) istio-injection=enabled --overwrite
ifeq (1,$(shell kubectl get pod --all-namespaces -l istio=pilot --no-headers | tail -n 1 | wc -l))
	kubectl label namespace $$(grep namespace $(PATH_PROJECT)/$(PATH_DESTINATION)/apps/$@/deployment.yaml | cut -d ' ' -f 4) istio-injection=enabled --overwrite
endif
	kubectl create secret tls lumberjack-ssl --cert=/tmp/lumberjack.crt --key=/tmp/lumberjack.key --namespace=$(APP_ENV)
	kubectl replace -f $(PATH_PROJECT)/$(PATH_DESTINATION)/apps/$@/ --force

	kubectl set image -f $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/$@/deployment.yaml $@=$(CONTAINER)-$(APP_ENV)/$@:v-master-bleedingedge
	kubectl get deployment --namespace=$(APP_ENV) -o yaml | istioctl kube-inject -f - | kubectl apply -f -
endif

help:
	@printf "\033[36m%-30s\033[0m %s\n" "service" "Set all services present on the folder templates/services/."
	@printf "\033[36m%-30s\033[0m %s\n" "service SERVICE_NAME" "Set SERVICE present on the folder templates/services/. If not present it will try to download from the repo"
	@printf "\033[36m%-30s\033[0m %s\n" "service SERVICE_NAME ENV" "Set SERVICE present on the folder templates/services/, with the setting of the ENV. If not present it will try to download from the repo"
	@printf "\033[36m%-30s\033[0m %s\n" "create apps ENV" "Set all applications based on folder list present on template folder in repository devops-kubernetes-beamery and Dockerfile presents on beamery-meta."
	@printf "\033[36m%-30s\033[0m %s\n" "create APP_NAME ENV" "Build and set specific application for specific environement"
	@printf "\033[36m%-30s\033[0m %s\n" "update apps" "Build and update Docker image for all applications"
	@printf "\033[36m%-30s\033[0m %s\n" "update APP_NAME" "Build and update docker image for specific applications"
