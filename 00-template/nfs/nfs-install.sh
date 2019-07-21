#!/bin/bash

sudo apt-get update
sudo apt install nfs-kernel-server
sudo mkdir -p /data
sudo chown nobody:nogroup /data
sudo chmod 777 /data


# add ip address ranges

cat > /etc/exports <<EOF
/data 0.0.0.0/0(rw,sync,no_root_squash,no_subtree_check) 
EOF

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# firewall setup
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow from  0.0.0.0/0 to any port nfs

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

sudo ufw allow 9100

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter