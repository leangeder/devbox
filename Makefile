.PHONY: services create update $(APP_NAME) $(APP_ENV)

UNAME := $(shell uname -s | tr A-Z a-z)
ifeq ($(OS),Windows_NT)
	print "Please download this file and install it:\nhttps://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe"
	UNAME := windows_nt
endif
ENV := minikube
TIMESTAMP = $(shell date +%s )
CONTAINER := us.gcr.io/beamery
REPO := vault-init
GO_VERSION := 1.10.2
HOME := $(shell echo $$HOME)
PATH_BEAMERY_ROOT := $(HOME)/beamery
PATH_BEAMERY_FOLDER := $(PATH_BEAMERY_ROOT)/devops-kubernetes-beamery
PATH_BEAMERY_META := $(PATH_BEAMERY_ROOT)/beamery-meta
PATH_ROOT_DOCKER_FOLDER := /tmp/devops-docker-images
PATH_TEMPLATE := templates
PATH_DESTINATION := deployment
# PATH_ENVIRONMENT := $(shell echo ./environments/$(ENV).yaml)
PATH_PROJECT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.meta-git: /usr/local/bin/meta-git
.minikube: /usr/local/bin/minikube
.kubectl: /usr/local/bin/kubectl
.vortex: /usr/local/bin/vortex
.go: /usr/local/bin/go

/usr/local/bin/meta-git: $(PATH_BEAMERY_ROOT)
	@git clone git@github.com:SeedJobs/meta-git $(PATH_BEAMERY_ROOT)/meta-git
	@$(PATH_BEAMERY_ROOT)/meta-git/meta-git install

/usr/local/bin/minikube: /usr/local/bin/kubectl
	@curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-$(UNAME)-amd64
	@chmod +x minikube
	@sudo mv minikube /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe
endif

/usr/local/bin/kubectl: 
	@curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(UNAME)/amd64/kubectl
	@chmod +x kubectl
	@sudo mv kubectl /usr/local/bin/
ifeq ($(UNAME),windows_nt)
	@curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/windows/amd64/kubectl.exe
endif

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

$(PATH_BEAMERY_ROOT):
	@mkdir -p $(PATH_BEAMERY_ROOT)

.up:
ifeq (0,$(shell minikube status | grep Running | wc -l))
	mkdir -p $$HOME/minikube_storage
	minikube config set WantReportErrorPrompt false
	minikube start --memory=6144 --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"

	# minikube start --memory=6144 --mount --mount-string=$$HOME/minikube_storage:/tmp/hostpath-provisioner --extra-config=apiserver.authorization-mode=RBAC --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
	minikube addons enable heapster
	# minikube addons enable ingress
	minikube addons disable ingress
endif

delete: 
	kubectl delete -R -f $(PATH_PROJECT)/deployment/
	kubectl delete -R -f $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/

.storage: .vortex .kubectl
	@rm -rf $(PATH_DESTINATION)/storages/
	@vortex --template $(PATH_TEMPLATE)/services/storages/ --output $(PATH_DESTINATION)/services/storages/ -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/storages/ --overwrite

services: .up .storage .es .mongodb .redis .rabbitmq .monstache
# 	@rm -rf $(PATH_DESTINATION)/services/mongodb/
# 	@vortex --template $(PATH_TEMPLATE)/services/mongodb --output $(PATH_DESTINATION)/services/mongodb/ -varpath $(PATH_ENVIRONMENT)
# 	@kubectl apply -f $(PATH_DESTINATION)/services/mongodb/namespace.yaml --overwrite
# 	@rm -f $(PATH_DESTINATION)/services/mongodb/namespace.yaml
# 	@kubectl replace -f $(PATH_DESTINATION)/services/mongodb/ --force --validate

.es:
	@rm -rf $(PATH_DESTINATION)/services/es/
	@kubectl create configmap config-jobs --namespace={{.elasticsearch.namespace}} --from-file=$(PATH_PROJECT)/templates/services/es/rebuildElasticsearchIndices.sh --from-file=$(PATH_PROJECT)/templates/services/es/files/mappings_Seed_Activities.json --from-file=$(PATH_PROJECT)/templates/services/es/files/mappings_Seed_Contacts.json --from-file=$(PATH_PROJECT)/templates/services/es/files/mappings_Seed_Events.json --from-file=$(PATH_PROJECT)/templates/services/es/files/mappings_Seed_Organisations.json --from-file=$(PATH_PROJECT)/templates/services/es/files/mappings_Seed_VacancyActivities.json --dry-run -o yaml > $(PATH_PROJECT)/templates/services/es/config_job.yaml
	@vortex --template $(PATH_TEMPLATE)/services/es --output $(PATH_DESTINATION)/services/es -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/es/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/es/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/es/ --force --validate

.mongodb:
	@rm -rf $(PATH_DESTINATION)/services/mongodb/
	@vortex --template $(PATH_TEMPLATE)/services/mongodb --output $(PATH_DESTINATION)/services/mongodb -varpath  environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/mongodb/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/mongodb/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/mongodb/ --force --validate

.redis:
	@rm -rf $(PATH_DESTINATION)/services/redis/
	@vortex --template $(PATH_TEMPLATE)/services/redis --output $(PATH_DESTINATION)/services/redis -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/redis/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/redis/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/redis/ --force --validate

.rabbitmq:
	@rm -rf $(PATH_DESTINATION)/services/rabbitmq/
	@vortex --template $(PATH_TEMPLATE)/services/rabbitmq --output $(PATH_DESTINATION)/services/rabbitmq -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/rabbitmq/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/rabbitmq/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/rabbitmq/ --force --validate

.monstache:
	@rm -rf $(PATH_DESTINATION)/services/monstache/
	@vortex --template $(PATH_TEMPLATE)/services/monstache --output $(PATH_DESTINATION)/services/monstache -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/monstache/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/monstache/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/monstache/ --force --validate

.linkerd:
	@rm -rf $(PATH_DESTINATION)/services/linkerd/
	@vortex --template $(PATH_TEMPLATE)/services/linkerd --output $(PATH_DESTINATION)/services/linkerd -varpath environments/services/$(ENV).yaml
	@kubectl apply -f $(PATH_DESTINATION)/services/linkerd/namespace.yaml --overwrite
	@rm -f $(PATH_DESTINATION)/services/linkerd/namespace.yaml
	@kubectl replace -f $(PATH_DESTINATION)/services/linkerd/ --force --validate

.istio:
	rm -rf $(PATH_DESTINATION)/services/istio/
	vortex --template $(PATH_TEMPLATE)/services/istio --output $(PATH_DESTINATION)/services/istio -varpath environments/services/$(ENV).yaml
	kubectl apply -f $(PATH_DESTINATION)/services/istio/namespace.yaml --overwrite
	rm -f $(PATH_DESTINATION)/services/istio/namespace.yaml
	kubectl replace -f $(PATH_DESTINATION)/services/istio/ --force --validate

ifeq (create,$(firstword $(MAKECMDGOALS)))
  APP_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  APP_NAME := $(firstword $(APP_ARGS))
  APP_ENV := $(lastword $(APP_ARGS))
  APP_CONTAINER := $(CONTAINER)-$(APP_ENV)/$(APP_NAME):v-master-bleedingedge
endif
ifeq (update,$(firstword $(MAKECMDGOALS)))
  APP_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  APP_NAME := $(firstword $(APP_ARGS))
  APP_CONTAINER := $(APP_NAME):$(TIMESTAMP)
endif

$(PATH_ROOT_DOCKER_FOLDER):
	@git clone git@github.com:SeedJobs/devops-docker-images.git $(PATH_ROOT_DOCKER_FOLDER)

.baseimage: $(PATH_ROOT_DOCKER_FOLDER)
	@eval $$(minikube docker-env); cd $(PATH_ROOT_DOCKER_FOLDER); docker build -t $(CONTAINER)-$(APP_ENV)/devops-node:latest -f node.Dockerfile .
	@eval $$(minikube docker-env); cd $(PATH_ROOT_DOCKER_FOLDER); docker build -t $(CONTAINER)-$(APP_ENV)/devops-nginx:latest -f nginx.Dockerfile .

$(PATH_BEAMERY_META):
	@git clone git@github.com:SeedJobs/beamery-meta.git $(PATH_BEAMERY_META)
	@cd $(PATH_BEAMERY_META); meta-git pull

$(PATH_BEAMERY_FOLDER):
	@git clone git@github.com:SeedJobs/devops-kubernetes-beamery.git $(PATH_BEAMERY_FOLDER)

update: $(PATH_ROOT_DOCKER_FOLDER) $(PATH_BEAMERY_META)
	@eval $$(minikube docker-env); cd $(PATH_BEAMERY_META)/$(APP_NAME); docker build -t $(APP_CONTAINER) -f Dockerfile .;
	@kubectl set image -f $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/$(APP_NAME)/deployment.yaml $(APP_NAME)=$(APP_NAME):$(TIMESTAMP)

create: .baseimage $(PATH_BEAMERY_META)
	eval $$(minikube docker-env); cd $(PATH_BEAMERY_META)/$(APP_NAME); docker build -t $(APP_CONTAINER) -f Dockerfile .
	ln -sf $(PATH_BEAMERY_FOLDER)/$(PATH_TEMPLATE)/$(APP_NAME) $(PATH_TEMPLATE)/apps/
	mkdir -p environments/apps/$(APP_NAME)
	ln -sf $(PATH_BEAMERY_FOLDER)/environments/$(APP_ENV).yaml environments/apps/$(APP_NAME)/$(APP_ENV).yaml
	vortex --template $(PATH_TEMPLATE)/apps/$(APP_NAME)/ --output $(PATH_DESTINATION)/apps/$(APP_NAME)/ -varpath environments/apps/$(APP_NAME)/$(APP_ENV).yaml
	openssl req -subj '/CN=*/' -x509 -batch -nodes -newkey rsa:2048 -keyout /tmp/lumberjack.key -out /tmp/lumberjack.crt
	-kubectl delete secret lumberjack-ssl --namespace=$(APP_ENV)
	-kubectl create ns $$(grep namespace $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/$(APP_NAME)/deployment.yaml | cut -d ' ' -f 4)
	-kubectl label namespace $$(grep namespace $(PATH_BEAMERY_FOLDER)/$(PATH_DESTINATION)/$(APP_NAME)/deployment.yaml | cut -d ' ' -f 4) istio-injection=enabled --overwrite
	kubectl create secret tls lumberjack-ssl --cert=/tmp/lumberjack.crt --key=/tmp/lumberjack.key --namespace=$(APP_ENV)
	kubectl replace -f $(PATH_DESTINATION)/apps/$(APP_NAME)/ --force
