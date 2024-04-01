#!/bin/bash

sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb http://repo.pritunl.com/stable/apt jammy main
EOF

# Import signing key from keyserver
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
# Alternative import from download if keyserver offline
curl https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc | sudo apt-key add -

sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list << EOF
deb https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse
EOF

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

sudo apt update
sudo apt --assume-yes upgrade

# WireGuard server support and additional tools
sudo apt -y install wireguard wireguard-tools unzip curl

### Install AWS cli ###
curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip awscliv2.zip
aws/install
rm -rf awscliv2.zip aws /usr/local/aws-cli/v2/*/dist/aws_completer /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index /usr/local/aws-cli/v2/*/dist/awscli/examples

### Disabling firewall ###
sudo ufw disable


#Increase Open File Limit
sudo sh -c 'echo "* hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 64000" >> /etc/security/limits.conf'


### Creating logs and data folders ###

mongodb_data_dir='/data/mongodb/data'
mongodb_logs_dir='/data/mongodb/logs'
pritunl_logs_dir='/data/pritunl/logs'

for path in $mongodb_data_dir $mongodb_logs_dir $pritunl_logs_dir; do mkdir -p $path; done

### Install Mongodb and Pritunl ###
sudo apt-get -y install pritunl mongodb-org

### Configuring mongodb ###

cat <<EOF > /etc/mongodb.conf
dbpath=$mongodb_data_dir

logpath="$mongodb_logs_dir/mongodb.log"

logappend=true

bind_ip = 127.0.0.1
port = 27017

journal=true
EOF


###  Configuring pritunl ###
cat <<EOF > /etc/pritunl.conf
{
    "mongodb_uri": "mongodb://localhost:27017/pritunl",
    "log_path": "$pritunl_logs_dir/pritunl.log",
    "static_cache": true,
    "temp_path": "/tmp/pritunl_eca0e913050344e18fc02ccbf9b74976",
    "bind_addr": "0.0.0.0",
    "www_path": "/usr/share/pritunl/www",
    "local_address_interface": "auto",
    "port": 443
}
EOF


# Starting mongodb and Pritunl
sudo systemctl enable mongod pritunl
sudo systemctl start mongod pritunl

sudo sleep 30

# Enable possibility to enable Let's Encrypt SSL
sudo pritunl set app.redirect_server true


# Updating secret with pritunl setup credentials
credentials=$(pritunl default-password)
username=$(echo "$credentials" | grep -o 'username: "[^"]*"' | sed 's/username: "//;s/"//')
password=$(echo "$credentials" | grep -o 'password: "[^"]*"' | sed 's/password: "//;s/"//')
setup_key=$(pritunl setup-key)

secret="{\"username\":\"$username\",\"password\":\"$password\",\"setup-key\":\"$setup_key\"}"

aws secretsmanager put-secret-value --secret-id ${credentials_secret} --secret-string $secret



reboot