#!/bin/bash
set -x
set -e

mv terraform/dot.terraformrc ~/.terraformrc

cd terraform
terraform init -backend-config="bucket=$BUCKET"
cat .terraform.lock.hcl
