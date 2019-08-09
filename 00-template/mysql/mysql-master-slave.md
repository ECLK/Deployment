### Setup mysql server first

## Configure Master

# Edit mysql config
sudo vi /etc/mysql/my.cnf

# Add or edit following lines
    [mysqld]
    bind-address = 12.34.56.789 # Server IP Address
    server-id = 1
    log_bin = /var/log/mysql/mysql-bin.log
    binlog_do_db = elect_db # Database name - Can add multiple lines for multiple databases

# Restart mysql service
sudo systemctl restart mysql

## Open up mysql shell

# Create replication user
GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' IDENTIFIED BY 'password';

FLUSH PRIVILEGES;

## lock database before creating a dump and record log position 
use elect_db;

FLUSH TABLES WITH READ LOCK;

SHOW MASTER STATUS; # Record log position value from the result

## Open a new tab on terminal and log in to same instance

# Create a db dump
mysqldump -u root -p elect_db > elect_db.sql

# On previous tab
UNLOCK TABLES;

QUIT;


## Configure Slave

## Login to mysql shell

# Create db
CREATE DATABASE elect_db;

EXIT;

# Restore db dump
mysql -u root -p elect_db < elect_db.sql


# Edit mysql config
sudo vi /etc/mysql/my.cnf

# Add or edit following lines
    [mysqld]
    server-id = 2
    relay-log = /var/log/mysql/mysql-relay-bin.log
    log_bin = /var/log/mysql/mysql-bin.log
    binlog_do_db = elect_db # Database name - Can add multiple lines for multiple databases


# Restart mysql service
sudo systemctl restart mysql

## Login to mysql shell

CHANGE MASTER TO MASTER_HOST='12.34.56.789',MASTER_USER='slave_user', MASTER_PASSWORD='password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=  107;


# Start slave
START SLAVE;

SHOW SLAVE STATUS\G