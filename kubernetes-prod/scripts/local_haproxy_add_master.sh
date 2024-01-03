#!/bin/bash
set -x
set -e

if ! grep -q "${ADD_MASTER}:" /etc/haproxy/z-apiserver.cfg; then
  echo "  server $ADD_MASTER:6443 check" >> /etc/haproxy/z-apiserver.cfg
  systemctl restart haproxy.service
fi
