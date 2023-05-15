# Airflow on local Kubernetes 
## Overview 
This is a side project to try out airflow v2 on kubernetes cluster which is running locally. So, What is airflow? *"Airflow is a platform that lets you build and run workflows. A workflow is represented as a DAG (a Directed Acyclic Graph), and contains individual pieces of work called Tasks, arranged with dependencies and data flows taken into account."* => [Architecture Overview](https://airflow.apache.org/docs/apache-airflow/stable/concepts/overview.html) OR the [OLD Architecture Overview with celery](https://medium.com/sicara/using-airflow-with-celery-workers-54cb5212d405)


## Prerequisite (on Macos)
- docker (requires minimum **4cores and 8GB memory** for running kubernetes cluster)
- kubernetes enable (using kinD or minikube)
- kubectl (`brew install kubectl`)
- k9s (optional `brew install k9s`)
- helm (`brew install helm`)

## Build docker image
You can use an [official airflow docker image](https://hub.docker.com/r/apache/airflow) or you can use your own custom airflow image. In this example, I create my own airflow image target to version `2.3.1` which is including some additional `airflow-providers` packages like : `airflow-provider-great-expectations`, `apache-airflow-providers-apache-spark`

- Build docker image:
  ```bash
  cd docker \
  docker build --no-cache -t {repo}/{image-name}:{tag} .
  # example: docker build --no-cache -t local/airflowv2:1.0.0 .
  ```

- Verify the airflow image has been created:
  ```bash
  docker image ls #OR 'docker images'
  ``` 

  ```bash
  # sameple output
  tle@trv3529~ docker images
  REPOSITORY                             TAG          IMAGE ID       CREATED        SIZE
  local/airflowv2                        1.0.3        5e5b1e0368b1   5 hours ago    2.4GB
  local/airflowv2                        1.0.2        97a83f004a3f   47 hours ago   2.4GB
  local/minio                            latest       f7a94b78f912   47 hours ago   1.15GB
  ```

## Deployment steps: 
I try to keep it simple

### MACOS and Linux:

~~Before start, please make sure the variables `AIRFLOW_IMAGE_NAME, AIRFLOW_IMAGE_TAG AIRFLOW_IMAGE_REPO, AIRFLOW_VERSION` in Makefile is compatible with those variables (`{repo}/{image-name}:{tag}`) are used when building docker image~~

Run `make install-all` and after the installation is finished (it takes a moment),
Airflow will already be running at:

* URL: http://localhost:8080
* User: `admin`
* Pass: `admin`

To stop it, run (from inside `airflowv2-kubernetes`):

    make uninstall-airflow

To bring airflow up again later, run:

    make install-airflow
  
Run `make help` for more details

### Windows: Not implemented yet

## Details explains in Make file steps:

- **Step 1: Create Kubernetes Airflow Cluster with  *kind* command:** `kind create cluster --name airflow-cluster --config kind-cluster.yaml`


- **Step 2: Create airflow namespace:** `kubectl create namespace airflow`

- **Step 3: load airflow image to airflow-cluster:**
  ```bash
  kind load docker-image {repo}/{image-name}:{tag} --name airflow-cluster 
  # Example, we will load the custom airflow image (tag 1.0.0) has been created on local repo with command: kind load docker-image local/airflowv2:1.0.0 --name airflow-cluster
  ```

- **Step 4 Optional: Set up `ssh-git-secret` to sync dag repository with your local airflow cluster.** What does that mean? Basically, when we want to add/edit an airflow dag, we need to re-deploy the whole airflow cluster with updated dags. In order to avoid that bottleneck, we will setup and `Sync` between airflow dags repo and our airflow. Everytime we makes change on airflow dags, after commit to the `master` branch, airflow cluster will have an interval check on git-repo to see if any new changes have been made. Then it will pull the latest update for all dags and reload it again into its execution context. The diagram below will indicate how it works. You can also prefer to this [Manage DAGs files](https://airflow.apache.org/docs/helm-chart/stable/manage-dags-files.html) for more details. 

  ```mermaid
  stateDiagram-v2

    local_development --> DAGs: commit
    state Host-Machine {
      state docker {
        state kubernetes(kind) {
          airflow_cluster-->DAGs: Git Sync
        }
      }
    }

    state GitRepo {
      DAGs
    }

  ```

  In order to do that, we need to create a `secret.yaml` file which will contain all sensitive data such as a password, a token, or a key. You can read it more detail from [here](https://kubernetes.io/docs/concepts/configuration/secret/). Now apply the secret config (with git-sync) to the cluster by running this command: 
  ```bash
  # update secret
  kubectl apply -f secret.yaml
  ```

- **Step 5: Apply Config Map**. What does that mean? => "A ConfigMap is an API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume..." you can check the detail from [here](https://kubernetes.io/docs/concepts/configuration/configmap/)
  ```bash
  # update configMap
  kubectl apply -f configMap.yaml
  ```

  - **Step 6: Apply Persistence Volume(pv) and Persistence Volume Claim(pvc)**. It help to mount volume from container to host machine
  ```bash
  kubectl apply -f ./chart/dags-volume.yaml -n airflow
	kubectl apply -f ./chart/logs-volume.yaml -n airflow
  ```

- **Step 7: Deploy airflow with default value.yaml for each airflow service running on kubernetes:**. 

  ```bash
  # add the official repository of the Apache Airflow Helm chart
  helm repo add apache-airflow https://airflow.apache.org

  # update the repo to get the latest version of it
  helm repo update

  # Check if airflow chart exist
  helm search repo airflow

  # deploy Airflow on Kubernetes with Helm install. The flag –debug allows to check if anything goes wrong during the deployment.

  # deploy default airlfow settings values
  helm install airflow apache-airflow/airflow --namespace airflow --debug
  ```

  In case we don't want to use all default settings from `value.yaml` provided by airflow-helm-chart, we can actually overwirte some of settings by creating a new file `overwrite-values.yaml`, and in which, you can add your own values. For example, you have created a custom airflow docker image on local (`local/airflowv2:1.0.0`)and you want to use that image for the deployment. All you need is just add these settings below to the `overwrite-values.yaml` file with following values:
  ```yaml
  # Default airflow repository -- overrides all the specific images below
  defaultAirflowRepository: local/airflowv2
  
  # Default airflow tag to deploy
  defaultAirflowTag: "1.0.2"
  ```
  Then deploy the helm chart with your `overwrite-values.yaml` file
  ```bash
  # deploy an overwrite vallues with custom airlfow docker image
  helm upgrade --install airflow apache-airflow/airflow -n airflow -f override-values.yaml --debug
  ```

  For more detail on overriding Helm chart values, please refer to this [link](https://all.docs.genesys.com/PrivateEdition/Current/PEGuide/HelmOverrides)

  
- **Step 8: Config external log on s3 (optional)**. Basically, the task execution will persit log to the pod where it's running. And the log will be gone if the pod get terminated once it finishes. Therefore, we need to send the log to an external storage such as : S3, Big Query... In this setup, we will [write log to Amazon S3](https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/logging/s3-task-handler.html) ([general architecture digram](https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/logging-architecture.html)). 
  
  Only config this setting if you have an object storage on your local (eg. minio, localstack, Azure Object Storage...)
  ```
  {"aws_access_key_id": "minio", "aws_secret_access_key": "minio123", "host": "http://host.docker.internal:9000"}
  ```

## Trouble shooting and debug
```bash
# get all pods in namespace: kubectl get pods -n {namespace}
kubectl get pods --namespace airflow

# ssh to container on pod: kubectl exec -n {namespace} -it {pod} -c {container} -- /bin/bash
kubectl exec -n airflow -it airflow-scheduler-6969ddc658-kdb42 -c scheduler -- /bin/bash

# debug on airflow deploy
kubectl describe pod podname

# Prune all docker volumes in case you running out of space when copy docker iamge to kubernetes
docker system prune --all --force --volumes

docker build --no-cache --build-arg AIRFLOW_VERSION=2.4.1 -t local/airflowv2:1.0.4 ./docker/. 

```


## References: 
- [Airflow on Kubernetes : Get started in 10 mins](https://marclamberti.com/blog/airflow-on-kubernetes-get-started-in-10-mins/#:~:text=To%20deploy%20Airflow%20on%20Kuberntes,is%20to%20create%20a%20namespace.&text=In%20the%20order%20of%20the,current%20version%20with%20search%20repo)
- [How to Setup Airflow Multi-Node Cluster with Celery & RabbitMQ](https://medium.com/@khatri_chetan/how-to-setup-airflow-multi-node-cluster-with-celery-rabbitmq-cfde7756bb6a)
- [KUBERNETES AIRFLOW – LOCAL DEVELOPMENT SETUP](https://christoph-caprano.de/kubernetes-airflow-local-development-setup/)
