#!bin/bash

sudo ufw allow http
sudo ufw allow https
sudo ufw allow 6443/tcp  # apiserver
sudo ufw allow 7000/tcp  # stats
sudo ufw allow 9101/tcp  # metrics exporter
sudo ufw allow 9100/tcp  # node exporter

sudo apt-get -y install haproxy
systemctl enable haproxy
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
systemctl enable haproxy-exporter
systemctl restart haproxy-exporter

# node exporter

wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz

tar xvfz node_exporter-0.17.0.linux-amd64.tar.gz
sudo cp node_exporter-0.17.0.linux-amd64/node_exporter /usr/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
EnvironmentFile=/etc/sysconfig/node_exporter
ExecStart=/usr/sbin/node_exporter $OPTIONS

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter