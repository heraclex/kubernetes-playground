#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Default airflow repository -- overrides all the specific images below
DEFAULT_AIRFLOW_REPOSITORY='local\/airflowv2'

# Default airflow tag to deploy
DEFAULT_AIRFLOW_TAG="1.0.0"

# Airflow version (Used to make some decisions based on Airflow Version being deployed)
AIRFLOW_VERSION="2.3.0"

# https://airflow.apache.org/docs/helm-chart/stable/production-guide.html#production-guide-knownhosts
GIT_SYNC_KNOWN_HOST="github.com"
GIT_SYNC_KNOWN_HOST_PUBLIC_KEY=$(ssh-keyscan -t rsa $GIT_SYNC_KNOWN_HOST)

config_override_value() {
  ### get information ready to replace template
  # local default_airflow_repository default_airflow_tag airflow_version
  local default_airflow_repository=$1
    default_airflow_tag=$2
    airflow_version=$3
    git_sync_known_host_public_key=$4

    airflow_con="google-cloud-platform:\/\/?extra__google_cloud_platform__scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform"
  echo "You are going to custom override-values.yaml file for airflow helm chart deployment"
  ###


  echo "\nConfiguring ./chart/override-values.yaml file..."

  # creating override-values.yaml file
  cp ./chart/override-values.temp.yaml ./chart/override-values.yaml

  sed -i.bak -E "/defaultAirflowRepository:/s//defaultAirflowRepository: $default_airflow_repository/" ./chart/override-values.yaml 
  echo "...added defaultAirflowRepository: $default_airflow_repository"
  sed -i.bak -E "/defaultAirflowTag:/s//defaultAirflowTag: $default_airflow_tag/" ./chart/override-values.yaml 
  echo "...added defaultAirflowTag: $default_airflow_tag"
  sed -i.bak -E "/airflowVersion:/s//airflowVersion: $airflow_version/" ./chart/override-values.yaml 
  echo "...added airflowVersion: $airflow_version"

  
  
  sed -i.bak -E "/^secret:/s//secret:\n  - envName: \"AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT\"\n    secretName: \"gcp-airflow-connections\"\n    secretKey: \"AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT\"/" ./chart/override-values.yaml 
  echo "...added AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT to secret"
  sed -i.bak -E "/^extraSecrets:/s//extraSecrets:\n  gcp-airflow-connections:\n    stringData: |\n      AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT: '$airflow_con'/" ./chart/override-values.yaml 
  echo "...added AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT to extraSecrets \n"

  # yq eval '.dags.gitSync.knownHosts = load_str("github_public_key.txt")' -i ./chart/override-values.yaml 

  # yq w ./chart/override-values.yaml  .dags.gitSync.knownHosts "\n ${git_sync_known_host_public_key}" 

  # yq eval .dags.gitSync.knownHosts = $git_sync_known_host_public_key  ./chart/override-values.yaml 

  # echo "$git_sync_known_host_public_key" | tr "/" /
  # '//\/'
  echo "$git_sync_known_host_public_key" | tr '/' "xxxxxx"
  # sed -i.bak -e "/^\([[:space:]]*knownHosts: \).*/s//\1|\n      s/\${aaa}/" ./chart/override-values.yaml 


}

# Run the main funtion
config_override_value "${1:-$DEFAULT_AIRFLOW_REPOSITORY}" "${2:-$DEFAULT_AIRFLOW_TAG}" "${3:-$AIRFLOW_VERSION}" "${4:-$GIT_SYNC_KNOWN_HOST_PUBLIC_KEY}"