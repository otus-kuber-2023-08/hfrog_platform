#!/bin/bash
set -x
set -e

cd terraform
terraform apply -auto-approve -var="ssh-keys='$SSH_KEYS'"

terraform state pull | jq .outputs > terraform-output.json
aws s3 --endpoint-url=https://storage.yandexcloud.net cp terraform-output.json s3://$BUCKET/terraform/terraform-output.json
