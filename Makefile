
initializing-kubernetes:
	@echo "> Configuring main-kind-cluster..."
	bash ./configure-main-kind-cluster.sh $(AIRFLOW_VERSION)
	@echo "> Initializing kubernetes (on kind cluster)..."
	kind create cluster --name local-spark-airflow-cluster --config main-kind-cluster.yaml

docker-build-airflow-image:
	@echo "> Build docker image 'airflow' version:$(AIRFLOW_VERSION) with tag:${AIRFLOW_IMAGE_TAG}"
	docker build --no-cache --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) -t ${AIRFLOW_IMAGE_FULLNAME} ./airflow2-kubernetes/docker/.

docker-build-airflow-image:
	@echo "> Build docker image 'spark' version:$(SPARK_VERSION) with tag:${SPARK_IMAGE_TAG}"
	docker build --no-cache --build-arg AIRFLOW_VERSION=$(SPARK_VERSION) -t ${SPARK_IMAGE_FULLNAME} ./spark3-kubernetes-docker/.

brew-install-prerequisite:
	brew install kubectl
	brew install k9s
	brew install helm