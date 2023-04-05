#!/usr/bin/env bash

set -o errexit
set -o pipefail

# global variables
DEFAULT_VERSION="1.0"

main() {
  ### get parameters
  local default_version=$1
  echo "You are going to init and run default_version:$default_version on local kubernetes with kind"
  ###

  # echo "Verifying google-cloud-cli config on local..."
  # local gcloud_path airflow_gcloud_path
  #   gcloud_path=$(gcloud info --format=json | grep global_config_dir | cut -d ':' -f 2 | tr -d '," ' | sed 's/\//\\&/g')   
  #   airflow_gcloud_path=$(echo /home/airflow/.config/gcloud | sed 's/\//\\&/g')

  # if [[ -z $gcloud_path ]]; then
  #   echo "> Error reading gcloud config"
  #   exit 1
  # fi

  echo "Configuring main-kind-cluster.yaml file..."

  # creating kind-cluster.config file
  cp main-kind-cluster.temp.yaml main-kind-cluster.yaml

  # Add volume mount for gcloud
  # sed -i.bak -E "/^  extraMounts:/s//  extraMounts:\n    - hostPath: $gcloud_path\n      containerPath: $airflow_gcloud_path/" kind-cluster.yaml  
}

# Run the main funtion
main "${1:-$DEFAULT_VERSION}"