#SHELL := /usr/bin/env bash

# Check OS
ifeq ($(OS),Windows_NT)
CHECKING := $(error $(OS) is not supported.)
endif

# Check required executables
REQUIRED_TOOLS = bash curl sed gcloud docker docker-compose
CHECKING := $(foreach exec,$(REQUIRED_TOOLS), $(if $(shell which $(exec)),0,$(error "$(exec) not found")))

# Check if user has logged in
LOCAL_GCLOUD_USER := $(shell gcloud info --format=json | grep account | cut -d ':' -f 2 | tr -d '," \n')
CHECKING :=
    ifeq ($(LOCAL_GCLOUD_USER),null)
        $(error gcloud user has not been set. Please run `gcloud auth login`.)
    endif

# Airflow macros
AIRFLOW_IMAGE_REPO=local
AIRFLOW_IMAGE_NAME=airflowv2
AIRFLOW_IMAGE_TAG=1.0.4
AIRFLOW_IMAGE_VERSION=${AIRFLOW_IMAGE_REPO}/${AIRFLOW_IMAGE_NAME}:${AIRFLOW_IMAGE_TAG}
AIRFLOW_VERSION=2.4.1

# All Targets
.DEFAULT_GOAL := help
.PHONY: clean setup check configure help
clean: 
	@echo "> Stop airflow on kubernetes (kind)..."
	kind delete cluster --name airflow-cluster
check: @echo "> Check is not implemented yet"
install: configure init-kubernetes loading-airflow-image config-airflow-cluster start-airflow-cluster check print-info
help:
	@echo "Commands:"
	@echo "  install    - setup and run the airflow stack on kubernetes"
	@echo "  clean      - stop all kubernetes cluster"
	@echo "  configure  - configure kind-cluster file"

init-kubernetes:
	@echo "> Initializing kubernetes (kind)..."
	kind create cluster --name airflow-cluster --config kind-cluster.yaml

loading-airflow-image:
	@echo "> Loading airflow image to kubernetes ..."
	kind load docker-image ${AIRFLOW_IMAGE_VERSION} --name airflow-cluster

config-airflow-cluster:
	@echo "> Configuring 'airflow' cluster..."
	kubectl create namespace airflow
	kubectl apply -f ./chart/secret.yaml
	kubectl apply -f ./chart/configMap.yaml

start-airflow-cluster:
	@echo "> Starting 'airflow' cluster..."
	helm upgrade --install airflow apache-airflow/airflow -n airflow -f ./chart/override-values.yaml --debug

print-info:
	@echo "> You can open http://localhost:8080"
	@echo "> Username and password both set to be 'admin'"

build-airflow-image:
	@echo "> Configuring 'airflow' on kind kubernetes and command..."
	docker build --no-cache -t ${AIRFLOW_IMAGE_VERSION} ./docker/.

configure:
	@echo "> Configuring 'airflow' on kind kubernetes and command..."
	bash ./configure-kind-cluster.sh $(AIRFLOW_VERSION)
	@echo "> Configuring 'airfflow-helmchart'..."
	bash ./configure-value-helmchart.sh '${AIRFLOW_IMAGE_REPO}\/${AIRFLOW_IMAGE_NAME}' ${AIRFLOW_IMAGE_TAG} ${AIRFLOW_VERSION}
	
