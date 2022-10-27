#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Default airflow repository -- overrides all the specific images below
DEFAULT_AIRFLOW_REPOSITORY='local\/airflowv2'

# Default airflow tag to deploy
DEFAULT_AIRFLOW_TAG="1.0.0"

# Airflow version (Used to make some decisions based on Airflow Version being deployed)
AIRFLOW_VERSION="2.3.0"

config_override_value() {
  ### get information ready to replace template
  # local default_airflow_repository default_airflow_tag airflow_version
  local default_airflow_repository=$1
    default_airflow_tag=$2
    airflow_version=$3
  echo "You are going to custom override-values.yaml file for airflow helm chart deployment"
  ###


  echo "Configuring ./chart/override-values.yaml file..."

  # creating kind-cluster.config file
  cp ./chart/override-values.temp.yaml ./chart/override-values.yaml
  sed -i.bak -E "/defaultAirflowRepository:/s//defaultAirflowRepository: $default_airflow_repository/" ./chart/override-values.yaml 
  echo "...defaultAirflowRepository: $default_airflow_repository"
  sed -i.bak -E "/defaultAirflowTag:/s//defaultAirflowTag: $default_airflow_tag/" ./chart/override-values.yaml 
  echo "...defaultAirflowTag: $default_airflow_tag"
  sed -i.bak -E "/airflowVersion:/s//airflowVersion: $airflow_version/" ./chart/override-values.yaml 
  echo "...airflowVersion: $airflow_version"
}

# Run the main funtion
config_override_value "${1:-$DEFAULT_AIRFLOW_REPOSITORY}" "${2:-$DEFAULT_AIRFLOW_TAG}" "${3:-$AIRFLOW_VERSION}"