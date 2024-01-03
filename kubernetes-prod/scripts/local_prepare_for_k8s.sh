#!/bin/bash
set -x
set -e

apt-get install -y containerd
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: ""
timeout: 0
debug: false
pull-image-on-create: false
disable-pull-on-run: false
EOF

apt-get install -y apt-transport-https ca-certificates curl gpg
[ -d /etc/apt/keyrings ] || mkdir /etc/apt/keyrings
[ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ] && rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubelet kubeadm kubectl

cat <<EOF > /etc/sysctl.d/90-k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
systemctl restart systemd-sysctl.service

cat <<EOF > /etc/modules-load.d/br_netfilter.conf
br_netfilter
EOF
systemctl restart systemd-modules-load.service
