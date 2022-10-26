#!/usr/bin/env bash

set -o errexit
set -o pipefail

# global variables
AIRFLOW_DEFAULT_VERSION="2.4.1"

main() {
  ### download and configure docker-compose and the airflow command script
  local airflow_version=$1
  ###

  local gcloud_path airflow_gcloud_path
    gcloud_path=$(gcloud info --format=json | grep global_config_dir | cut -d ':' -f 2 | tr -d '," ' | sed 's/\//\\&/g')   airflow_gcloud_path=$(echo /home/airflow/.config/gcloud | sed 's/\//\\&/g')
    airflow_con="google-cloud-platform:\/\/?extra__google_cloud_platform__scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform"

  if [[ -z $gcloud_path ]]; then
    echo "> Error reading gcloud config"
    exit 1
  fi

#   set -o xtrace
#   echo "> Upgrading 'airflow' docker-compose and command..."
#   curl -LfO "https://airflow.apache.org/docs/apache-airflow/$airflow_version/docker-compose.yaml"
#   curl -LfO "https://airflow.apache.org/docs/apache-airflow/$airflow_version/airflow.sh"
#   chmod +x airflow.sh

#  # Add volume mount for gcloud
#   sed -i.bak -E "/^  volumes:/s//  volumes:\n    - $gcloud_path:$airflow_gcloud_path/" docker-compose.yaml
  cp kind-cluster.temp.yaml kind-cluster.yaml
  sed -i.bak -E "/^  extraMounts:/s//  extraMounts:\n    - hostPath: $gcloud_path\n      containerPath: $airflow_gcloud_path/" kind-cluster.yaml
#   sed -i.bak -E "/^  extraMounts:/s//  extraMounts:\n    - hostPath: $gcloud_path/" kind-cluster.yaml
  
}

# Run the main funtion
main "${1:-$DEFAULT_VERSION}"