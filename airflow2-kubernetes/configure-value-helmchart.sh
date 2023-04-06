#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Default airflow repository -- overrides all the specific images below
DEFAULT_AIRFLOW_REPOSITORY='local\/airflow'

# Default airflow tag to deploy
DEFAULT_AIRFLOW_TAG="v2.5.2"

# Airflow version (Used to make some decisions based on Airflow Version being deployed)
AIRFLOW_VERSION="2.5.3"

config_override_value() {
  ### get information ready to replace template
  # local default_airflow_repository default_airflow_tag airflow_version
  local default_airflow_repository=$1
    default_airflow_tag=$2
    airflow_version=$3
    airflow_con="google-cloud-platform:\/\/?extra__google_cloud_platform__scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform"
  echo "You are going to custom override-values.yaml file for airflow helm chart deployment"
  ###


  echo "\nConfiguring ./chart/override-values.yaml file..."

  # creating override-values.yaml file
  cp ./chart/override-values.temp.yaml ./chart/override-values.yaml
  sed -i.bak -E "/defaultAirflowRepository:/s//defaultAirflowRepository: $default_airflow_repository/" ./chart/override-values.yaml 
  echo "...adding defaultAirflowRepository: $default_airflow_repository"
  sed -i.bak -E "/defaultAirflowTag:/s//defaultAirflowTag: $default_airflow_tag/" ./chart/override-values.yaml 
  echo "...adding defaultAirflowTag: $default_airflow_tag"
  sed -i.bak -E "/airflowVersion:/s//airflowVersion: $airflow_version/" ./chart/override-values.yaml 
  echo "...adding airflowVersion: $airflow_version"
  
  sed -i.bak -E "/^secret:/s//secret:\n  - envName: \"AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT\"\n    secretName: \"gcp-airflow-connections\"\n    secretKey: \"AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT\"/" ./chart/override-values.yaml 
  echo "...adding AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT to secret"
  sed -i.bak -E "/^extraSecrets:/s//extraSecrets:\n  gcp-airflow-connections:\n    stringData: |\n      AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT: '$airflow_con'/" ./chart/override-values.yaml 
  echo "...adding AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT to extraSecrets \n"
}

# Run the main funtion
config_override_value "${1:-$DEFAULT_AIRFLOW_REPOSITORY}" "${2:-$DEFAULT_AIRFLOW_TAG}" "${3:-$AIRFLOW_VERSION}"