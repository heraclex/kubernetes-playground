# Airflow on Kubernetes
This is a side project to test airflow v2 on kubernetes

Prerequisite:
- kubernetes (using kinD or minikube)
- kubectl
- k9s (optional)
- helm

Deployment steps:
- Step1: Create Kubernetes Cluster (KinD): `kind create cluster --name airflow-cluster --config kind-cluster.yaml`
- Step2: Create airflow namespace: `kubectl create namespace airflow`
- Step3: Build custom docker image: 
  ```bash
  # build airflow docker image
  docker build -t local/airflowv2:1.0.2 .
  # load airflow docker image to airflow-cluster
  kind load docker-image {name}:{tag} --name airflow-cluster 
  ```
- Step 4: Deploy airflow to kubernetes using helm deployment

  ```bash
  # add the official repository of the Apache Airflow Helm chart
  helm repo add apache-airflow https://airflow.apache.org
  # update the repo to get the latest version of it
  helm repo update
  # Check if airflow chart exist
  helm search repo airflow

  # deploy Airflow on Kubernetes with Helm install. The flag –debug allows to check if anything goes wrong during the deployment.

  # using default airlfow
  helm install airflow apache-airflow/airflow --namespace airflow --debug

  # using custom airlfow docker image
  helm upgrade --install airflow apache-airflow/airflow -n airflow -f override-values.yaml --debug
  ```
- Step 5: Apply git sync to airflow cluster
  ```bash
  # update secret
  kubectl apply -f secret.yaml
  # update configMap
  kubectl apply -f configMap.yaml
  ```
- Step6: Config external log on s3
  ```
  {"aws_access_key_id": "airflow", "aws_secret_access_key": "airflow123", "host": "host.docker.internal:9001"}
  ```

Ref: 
- https://marclamberti.com/blog/airflow-on-kubernetes-get-started-in-10-mins/#:~:text=To%20deploy%20Airflow%20on%20Kuberntes,is%20to%20create%20a%20namespace.&text=In%20the%20order%20of%20the,current%20version%20with%20search%20repo
- https://airflow.apache.org/docs/helm-chart/stable/manage-dags-files.html
