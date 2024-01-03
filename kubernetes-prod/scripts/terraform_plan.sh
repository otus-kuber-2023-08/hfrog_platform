#!/bin/bash
set -x
set -e

cd terraform
terraform plan -var="ssh-keys='$SSH_KEYS'"
