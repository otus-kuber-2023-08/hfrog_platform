#!/bin/bash
set -x
set -e

function fetch_and_upload_file {
  filename=$1
  scp ubuntu@${MASTER1}:$filename .
  aws s3 --endpoint-url=https://storage.yandexcloud.net cp $filename s3://$BUCKET/k8s/$filename
}

aws s3 --endpoint-url=https://storage.yandexcloud.net cp s3://$BUCKET/terraform/terraform-output.json .
MASTER1=$(jq -r '.external_ip.value."master-1"' terraform-output.json)
scp -o StrictHostKeyChecking=no scripts/local_kubeadm_init.sh ubuntu@${MASTER1}:
LB1=$(jq -r '.external_ip.value."lb-1"' terraform-output.json)
ssh ubuntu@$MASTER1 sudo APISERVER_IP=$LB1 ./local_kubeadm_init.sh

fetch_and_upload_file admin.conf
