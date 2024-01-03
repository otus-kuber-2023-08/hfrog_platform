#!/bin/bash
set -x
set -e

apt-get install -y haproxy jq

cat <<EOF > /etc/default/haproxy
CONFIG="/etc/haproxy"
EOF

cat <<EOF > /etc/haproxy/z-stats.cfg
listen stats
  mode http
  bind 127.0.0.1:8404
  stats enable
  stats uri /stats
EOF

# Add first master only at the beginning
master=$(jq -r '.internal_ip.value|with_entries(select(.key == "master-1"))|to_entries[]|join(" ")' terraform-output.json)

cat <<EOF > /etc/haproxy/z-apiserver.cfg
frontend fe-apiserver
  bind *:6443
  mode tcp
  option tcplog
  default_backend be-apiserver

backend be-apiserver
  mode tcp
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server $master:6443 check
EOF
systemctl restart haproxy.service
