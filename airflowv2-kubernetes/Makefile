#SHELL := /usr/bin/env bash

# Check OS
# TODO: Need to work on it for Windows
ifeq ($(OS),Windows_NT)
CHECKING := $(error $(OS) is not supported.)
endif

# Check required executables: bash curl sed gcloud docker docker-compose
REQUIRED_TOOLS = bash curl sed docker docker-compose
CHECKING := $(foreach exec,$(REQUIRED_TOOLS), $(if $(shell which $(exec)),0,$(error "$(exec) not found")))

# Check if user has logged in
# LOCAL_GCLOUD_USER := $(shell gcloud info --format=json | grep account | cut -d ':' -f 2 | tr -d '," \n')
# CHECKING :=
#     ifeq ($(LOCAL_GCLOUD_USER),null)
#         $(error gcloud user has not been set. Please run `gcloud auth login`.)
#     endif

# Airflow macros
AIRFLOW_IMAGE_REPO=local
AIRFLOW_IMAGE_NAME=airflowv2
AIRFLOW_IMAGE_TAG=1.0.4
AIRFLOW_IMAGE_FULLNAME=${AIRFLOW_IMAGE_REPO}/${AIRFLOW_IMAGE_NAME}:${AIRFLOW_IMAGE_TAG}
AIRFLOW_VERSION=2.5.2

# All Targets
.DEFAULT_GOAL := help
.PHONY: uninstall-all install-all help

uninstall-all: delete-airflow-namespace delete-kubernetes-cluster delete-airflow-docker-image
uninstall-kubernetes: delete-airflow-namespace delete-kubernetes-cluster
uninstall-airflow: delete-airflow-namespace
delete-airflow-namespace:
	@echo "> Delete namespace airflow..."
	kubectl delete namespace airflow
delete-kubernetes-cluster:
	@echo "> Delete kubernetes(kind) cluster..."
	kind delete cluster --name airflow-cluster
delete-airflow-docker-image:
	@echo "> Delete docker image ${AIRFLOW_IMAGE_FULLNAME}"
	docker image rm -f ${AIRFLOW_IMAGE_FULLNAME}

check: 
	@echo "> Check is not implemented yet"
install-all: brew-install-prerequisite docker-build-airflow-image create-config-files create-kubernetes loading-airflow-image run-config-afcluster start-afcluster
install-kubernetes-airflow: create-config-files create-kubernetes loading-airflow-image run-config-afcluster start-afcluster
install-airflow: create-config-files run-config-afcluster start-afcluster
help:
	@echo "Commands:"
	@echo "  install-all    - setup and run the airflow stack on kubernetes"
	@echo "  uninstall-all      - stop all kubernetes cluster and delete docker images"
	@echo "  uninstall-kubernetes      - remove kubernetes cluster"
	@echo "  uninstall-airflow      - remove airflow cluster from kubernetes"
	@echo "  create-config-files	- generate Kubernetes config files and airflow helm chart"
	@echo "  run-config-afcluster	- configure airflow cluster"
	@echo "  loading-airflow-image	- loading airflow image to kubernetes cluster"

create-kubernetes:
	@echo "> Initializing kubernetes (kind)..."
	kind create cluster --name airflow-cluster --config kind-cluster.yaml

loading-airflow-image:
	@echo "> Loading airflow image to kubernetes(kind) ..."
	kind load docker-image ${AIRFLOW_IMAGE_FULLNAME} --name airflow-cluster

run-config-afcluster:
	@echo "> Configuring 'airflow' cluster..."
	kubectl create namespace airflow
	kubectl apply -f ./chart/secret.yaml -n airflow
	kubectl apply -f ./chart/configMap.yaml -n airflow
	kubectl apply -f ./chart/dags-volume.yaml -n airflow
	kubectl apply -f ./chart/logs-volume.yaml -n airflow

# helm repo add apache-airflow https://airflow.apache.org
start-afcluster:
	@echo "> Starting 'airflow' cluster..."
	helm upgrade --install airflow apache-airflow/airflow --namespace airflow -f ./chart/override-values.yaml --debug
	@echo "> Mounting 'svc/airflow-webserver'" to port 8080
	kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

create-config-files:
	@echo "> Configuring 'airflow' on kind kubernetes and command..."
	bash ./configure-kind-cluster.sh $(AIRFLOW_VERSION)
	@echo "> Configuring 'airflow-helmchart'..."
	bash ./configure-value-helmchart.sh '${AIRFLOW_IMAGE_REPO}\/${AIRFLOW_IMAGE_NAME}' ${AIRFLOW_IMAGE_TAG} ${AIRFLOW_VERSION}

docker-build-airflow-image:
	@echo "> Build docker image 'airflow' version:$(AIRFLOW_VERSION) with tag:${AIRFLOW_IMAGE_TAG}"
	docker build --no-cache --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) -t ${AIRFLOW_IMAGE_FULLNAME} ./docker/.
	@echo "> Show docker images"
	docker images 

brew-install-prerequisite:
	brew install kubectl
	brew install k9s
	brew install helm
	
