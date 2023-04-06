

# create spark cluster
```bash
kind create cluster --name spark-cluster --config kind-cluster.yaml
```

# build spark docker image to run on kubernetes

```bash

cd $SPARK_HOME
# build spark images to {local} repo and tag v3.2.1-j11 with -n no cache

bin/docker-image-tool.sh -r local -t v3.2.1-j11 -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile -n build

# Create a jump pod using the Spark driver container and service account
kubectl run spark-test-pod -it --rm=true \
  --namespace=spark \
  --image=local/spark:v3.3.2 \
  --command -- /bin/bash

kubectl delete pod spark-test-pod --namespace=spark
```

# create driver service account
```bash
# Create spark-driver service account
kubectl create serviceaccount spark-driver --namespace=<insert-namespace-name-here>

# Create a cluster and namespace "role-binding" to grant the account administrative privileges
kubectl create rolebinding spark-driver-rb --clusterrole=cluster-admin --serviceaccount={namespace}:spark-driver
```

# create executor service account
```bash
# Create Spark executor account
kubectl create serviceaccount spark-executor --namespace=<insert-namespace-name-here>

# Create rolebinding to offer "edit" privileges
kubectl create rolebinding spark-executor-rb --clusterrole=edit --serviceaccount={namespace}:spark-executor
```

# verify service service service account 
```bash
kubectl get serviceaccounts
kubectl describe serviceaccounts spark-driver

kubectl config use-context <insert-cluster-name-here>
kubectl config set-context --current --namespace=<insert-namespace-name-here>
```

# load spark docker image to the cluster
```bash
kind load docker-image local/spark:v3.2.1-j11 --name spark-cluster
kind load docker-image local/spark-py:v3.2.1-j11 --name spark-cluster
```

# spark
```bash
# get cluster infor
kubectl cluster-info

#   --conf spark.kubernetes.authenticate.subdmission.caCertFile=local:///var/run/secrets/kubernetes.io/serviceaccount/ca.crt  \
#   --conf spark.kubernetes.authenticate.submission.oauthTokenFile=local:///var/run/secrets/kubernetes.io/serviceaccount/token  \
# submit spark
$SPARK_HOME/bin/spark-submit \
  --master k8s://https://127.0.0.1:58441 \
  --deploy-mode cluster \
  --name spark-pi \
  --conf spark.executor.instances=4 \
  --conf spark.driver.memory=1g \
  --conf spark.executor.memory=1g \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark-driver  \
  --conf spark.kubernetes.container.image=local/spark:v3.3.2 \
  --conf spark.kubernetes.namespace=spark \
  --class org.apache.spark.examples.SparkPi \
  local:///opt/spark/examples/jars/spark-examples_2.12-3.3.2.jar



  kubectl create clusterrolebinding spark-clusterrolebinding --clusterrole=edit --serviceaccount=spark:spark-driver --namespace=spark  

# get log from pod
kubectl -n {namespace} logs {pod-id}
```





REF
https://www.oak-tree.tech/blog/spark-kubernetes-primer


