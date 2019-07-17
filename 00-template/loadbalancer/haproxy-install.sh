#!bin/bash

sudo ufw allow http
sudo ufw allow https
sudo ufw allow 6443/tcp  # apiserver
sudo ufw allow 7000/tcp  # stats
sudo ufw allow 9101/tcp  # metrics exporter

sudo apt-get -y install haproxy
sudo service haproxy restart

## setup ha proxy exporter
wget https://github.com/prometheus/haproxy_exporter/releases/download/v0.10.0/haproxy_exporter-0.10.0.freebsd-amd64.tar.gz
tar xvzf haproxy_exporter-0.10.0.freebsd-amd64.tar.gz 

cp haproxy_exporter-0.10.0.freebsd-amd64/haproxy_exporter /usr/local/bin/

cat > /etc/systemd/system/haproxy-exporter.service <<EOF
[Unit]
Description=Export HA Proxy metrics to prometheus
After=syslog.target network.target

[Service]
Type=simple

User=root
Group=root

ExecStart=/usr/local/bin/haproxy_exporter --haproxy.scrape-uri="http://localhost:7000/;csv" 

KillMode=process

TimeoutSec=30

Restart=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart haproxy-exporter