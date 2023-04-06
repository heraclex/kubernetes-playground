#SHELL := /usr/bin/env bash

# Check OS
# TODO: Need to work on it for Windows
ifeq ($(OS),Windows_NT)
CHECKING := $(error $(OS) is not supported.)
endif

# Check required executables: bash curl sed gcloud docker docker-compose
REQUIRED_TOOLS = bash curl sed docker docker-compose kubectl k9s helm
CHECKING := $(foreach exec,$(REQUIRED_TOOLS), $(if $(shell which $(exec)),0,$(error "$(exec) not found")))

# Check if user has logged in
# LOCAL_GCLOUD_USER := $(shell gcloud info --format=json | grep account | cut -d ':' -f 2 | tr -d '," \n')
# CHECKING :=
#     ifeq ($(LOCAL_GCLOUD_USER),null)
#         $(error gcloud user has not been set. Please run `gcloud auth login`.)
#     endif


LOCAL_DOCKER_IMG_REPO=local
# Airflow macros
AIRFLOW_IMAGE_NAME=airflow
AIRFLOW_VERSION=2.5.2
AIRFLOW_IMAGE_FULLNAME=${LOCAL_DOCKER_IMG_REPO}/${AIRFLOW_IMAGE_NAME}:${AIRFLOW_VERSION}
AIRFLOW_NAMESPACE=airflow

# Spark macros
SPARK_IMAGE_NAME=spark
SPARK_VERSION=3.3.2
SPARK_IMAGE_FULLNAME=${LOCAL_DOCKER_IMG_REPO}/${SPARK_IMAGE_NAME}:${SPARK_VERSION}
SPARK_NAMESPACE=spark

CLUSTER_NAME=local-spark-airflow-cluster

# All Targets
.DEFAULT_GOAL := help
.PHONY: uninstall-all install-all help

initializing-spark-airflow-cluster:
	@echo "> Configuring main-kind-cluster..."
	bash ./configure-main-kind-cluster.sh
	
	@echo "> Initializing kubernetes ${CLUSTER_NAME} (on kind)..."
	kind create cluster --name ${CLUSTER_NAME} --config main-kind-cluster.yaml
	
	@echo "> Create namespace '${AIRFLOW_NAMESPACE}'..."
	kubectl create namespace ${AIRFLOW_NAMESPACE}

	@echo "> Create namespace '${SPARK_NAMESPACE}'..."
	kubectl create namespace ${SPARK_NAMESPACE}

uninstall-spark-airflow-cluster: 
	@echo "> Delete ${CLUSTER_NAME}..."
	kind delete cluster --name ${CLUSTER_NAME}

docker-build-airflow-image:
	@echo "> Build docker image 'airflow' version:$(AIRFLOW_VERSION)"
	docker build --no-cache --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) -t $(AIRFLOW_IMAGE_FULLNAME) ./airflow2-kubernetes/docker/.
upload-airflow-image:
	@echo "> Upload airflow ${AIRFLOW_IMAGE_FULLNAME} to ${CLUSTER_NAME}..."
	kind load docker-image ${AIRFLOW_IMAGE_FULLNAME} --name ${CLUSTER_NAME}


### docker build --no-cache --build-arg SPARK_VERSION=$(SPARK_VERSION) -t ${SPARK_IMAGE_FULLNAME} ./spark3-kubernetes/docker/.
docker-build-spark-image:
	@echo "> Build docker image 'spark' version:$(SPARK_VERSION) with tag:${SPARK_VERSION}"
	cd $(SPARK_HOME) && bin/docker-image-tool.sh -r $(LOCAL_DOCKER_IMG_REPO) -t v$(SPARK_VERSION) -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile -n build
upload-spark-image:
	@echo "> Upload spark: ${LOCAL_DOCKER_IMG_REPO}/${SPARK_IMAGE_NAME}:${SPARK_VERSION} to ${CLUSTER_NAME} ..."
	kind load docker-image ${LOCAL_DOCKER_IMG_REPO}/${SPARK_IMAGE_NAME}:${SPARK_VERSION} --name ${CLUSTER_NAME}
	@echo "> Upload spark-py: ${LOCAL_DOCKER_IMG_REPO}/${SPARK_IMAGE_NAME}-py:${SPARK_VERSION} image to ${CLUSTER_NAME} ..."
	kind load docker-image ${LOCAL_DOCKER_IMG_REPO}/${SPARK_IMAGE_NAME}-py:${SPARK_VERSION} --name ${CLUSTER_NAME}

build-upload-spark-airflow-images: docker-build-spark-image docker-build-airflow-image upload-spark-image upload-airflow-image

# A ServiceAccount provides an identity for processes that run in a Pod.
# https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/
create-spark-service-account-and-role-biding: 
	@echo "> Create service-account spark-driver ..."
	kubectl create serviceaccount spark-driver --namespace=$(SPARK_NAMESPACE)
	@echo "> Create a cluster and namespace 'role-binding' to grant the account administrative privileges..."
	kubectl create rolebinding spark-driver-rb --clusterrole=cluster-admin --serviceaccount=$(SPARK_NAMESPACE):spark-driver

	@echo "> Create service-account  spark-executor..."
	kubectl create serviceaccount spark-executor --namespace=$(SPARK_NAMESPACE)
	@echo "> Create a cluster and namespace 'role-binding' to grant the account administrative privileges..."
	kubectl create rolebinding spark-executor-rb --clusterrole=cluster-admin --serviceaccount=$(SPARK_NAMESPACE):spark-executor
	
	@echo "> show serviceaccounts:"
	kubectl get serviceaccounts --namespace=$(SPARK_NAMESPACE)
### https://stackoverflow.com/questions/55498702/how-to-fix-forbiddenconfigured-service-account-doesnt-have-access-with-spark
### https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes/issues/113
	@echo "> Create clusterrolebinding and namespace 'role-binding' to grant the account administrative privileges..."
	kubectl create clusterrolebinding spark-clusterrolebinding --clusterrole=edit --serviceaccount=$(SPARK_NAMESPACE):spark-driver --namespace=$(SPARK_NAMESPACE)

brew-install-prerequisite:
	brew install kubectl
	brew install k9s
	brew install helm