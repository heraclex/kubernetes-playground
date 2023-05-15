# All Targets
.DEFAULT_GOAL := help
.PHONY: uninstall-all install-all help

create-spark-namespace:
	@echo "> Create namespace $(namespace)..."
	kubectl create namespace $(namespace)
create-service-account-and-role-biding: 
	@echo "> Create service-account spark-driver ..."
	kubectl create serviceaccount spark-driver --namespace=$(namespace)
	@echo "> Create a cluster and namespace 'role-binding' to grant the account administrative privileges..."
	kubectl create rolebinding spark-driver-rb --clusterrole=cluster-admin --serviceaccount=$(namespace):spark-driver

	@echo "> Create service-account  spark-executor..."
	kubectl create serviceaccount spark-executor --namespace=$(namespace)
	@echo "> Create a cluster and namespace 'role-binding' to grant the account administrative privileges..."
	kubectl create rolebinding spark-executor-rb --clusterrole=cluster-admin --serviceaccount=$(namespace):spark-executor
	
	@echo "> show serviceaccounts:"
	kubectl get serviceaccounts --namespace=$(namespace)
docker-build-spark-image:
	cd $(SPARK_HOME) && bin/docker-image-tool.sh -r local -t 3.2.1 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile -n build
	
