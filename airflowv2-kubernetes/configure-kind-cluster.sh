#!/usr/bin/env bash

set -o errexit
set -o pipefail

# global variables
AIRFLOW_DEFAULT_VERSION="2.4.xx"

main() {
  ### download and configure docker-compose and the airflow command script
  local airflow_version=$1
  echo "You are going to init and run airflow version:$airflow_version on kubernetes with kind"
  ###

  echo "Verifying google-cloud-cli config on local..."
  local gcloud_path airflow_gcloud_path
    gcloud_path=$(gcloud info --format=json | grep global_config_dir | cut -d ':' -f 2 | tr -d '," ' | sed 's/\//\\&/g')   
    airflow_gcloud_path=$(echo /home/airflow/.config/gcloud | sed 's/\//\\&/g')
    airflow_con="google-cloud-platform:\/\/?extra__google_cloud_platform__scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform"

  if [[ -z $gcloud_path ]]; then
    echo "> Error reading gcloud config"
    exit 1
  fi

  echo "Configuring kind-cluster.yaml file..."

  # creating kind-cluster.config file
  cp kind-cluster.temp.yaml kind-cluster.yaml

  # Add volume mount for gcloud
  sed -i.bak -E "/^  extraMounts:/s//  extraMounts:\n    - hostPath: $gcloud_path\n      containerPath: $airflow_gcloud_path/" kind-cluster.yaml  
}

# Run the main funtion
main "${1:-$AIRFLOW_DEFAULT_VERSION}"