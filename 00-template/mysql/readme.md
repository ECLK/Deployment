#This guides thriugh setting up mysql server with custom @@datadir

sudo apt-get update
sudo apt install -y mysql-server

sudo mysql_secure_installation
# Provide password and related settings to secure mysql
    # Remove anonymous users - Y
    # Disallow root login remotely Y
    # Remove test database and access to it Y
    # Reload privilege tables now Y

### Changing data dir

# Check current data dir
mysql> select @@datadir;

# Stop mysql server
sudo systemctl stop mysql

# Sync current data dir to new one - new path is /mnt/mysql
sudo rsync -av /var/lib/mysql /mnt/mysql

# Backup current datadir
sudo mv /var/lib/mysql /var/lib/mysql.bak

## Pointing to new datadir
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf

# Change the line begins with datadir= and change the path
datadir=/mnt/mysql

## Configure AppArmor

# Edit apparmor alias
sudo vi /etc/apparmor.d/tunables/alias

# add this to bottom of the file
alias /var/lib/mysql/ -> /mnt/mysql/,

# Restart Apparmor service
sudo systemctl restart apparmor

# Restart mysql service
sudo systemctl start mysql