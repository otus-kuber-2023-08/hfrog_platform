#!/bin/bash
set -x
set -e

function wait_for_readiness {
  echo Waiting for node readiness
  i=0
  while ! kubectl get nodes | grep -qw Ready; do
    sleep 1
    i=$(( i + 1 ))
    [ $i -ge 60 ] && break
  done || true
}

kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint $APISERVER_IP:6443

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

cp /etc/kubernetes/admin.conf ~ubuntu && chown ubuntu: ~ubuntu/admin.conf

wait_for_readiness
kubectl get nodes -o wide
