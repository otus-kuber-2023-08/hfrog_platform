#!/bin/bash
set -x
set -e

sudo apt-get install -y awscli
mkdir ~/.aws

cat <<'EOF' > ~/.aws/config
[default]
region = ru-central1
EOF

cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF
chmod 600 ~/.aws/credentials
