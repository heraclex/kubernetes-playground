# Airflow on Kubernetes
This is a side project to test airflow v2 on kubernetes

- Create Kubernetes Cluster (KinD): `kind create cluster --name airflow-cluster --config kind-cluster.yaml`
- Create airflow namespace: `kubectl create namespace airflow`

```bash
# add the official repository of the Apache Airflow Helm chart
helm repo add apache-airflow https://airflow.apache.org
# update the repo to get the latest version of it
helm repo update
# Check if airflow chart exist
helm search repo airflow
# deploy Airflow on Kubernetes with Helm install. The flag –debug allows to check if anything goes wrong during the deployment.
helm install airflow apache-airflow/airflow --namespace airflow --debug
```
