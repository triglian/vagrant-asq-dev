#!/bin/bash

MONGODB_VER=2.6.1
NODE_VER=0.11.13
REDIS_VER=2.8.19
 
echo "Provisioning virtual machine..."

echo "updating apt-get"
apt-get update > /dev/null

echo "installing build-essential"
apt-get install build-essential -y > /dev/null

echo "Installing Git"
apt-get install git -y > /dev/null
 
echo "Installing Nginx"
apt-get install nginx -y > /dev/null

echo "Configuring Nginx"
cp -u /vagrant/conf/nginx/asq /etc/nginx/sites-available/asq
ln -s /etc/nginx/sites-available/asq /etc/nginx/sites-enabled/asq
cp -u /vagrant/conf/nginx/asq-ssl /etc/nginx/sites-available/asq-ssl
# remove default from enabled
rm /etc/nginx/sites-enabled/default

service nginx reload

echo "Installing mongodb"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 > /dev/null
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get update > /dev/null
apt-get install -y mongodb-org=$MONGODB_VER mongodb-org-server=$MONGODB_VER mongodb-org-shell=$MONGODB_VER mongodb-org-mongos=$MONGODB_VER mongodb-org-tools=2.6.1 > /dev/null

echo "Installing nvm"
export HOME=/home/vagrant
curl  --silent https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
echo "source ~/.nvm/nvm.sh" >> /home/vagrant/.bashrc
source /home/vagrant/.nvm/nvm.sh

echo "Installing Node.js"
nvm install $NODE_VER > /dev/null

echo "Setting $NODE_VER as the default"
nvm alias default $NODE_VER
nvm use default

echo "Installing Redis"

apt-get -y install make > /dev/null

mkdir /opt/redis
cd /opt/redis
wget -q http://download.redis.io/releases/redis-${REDIS_VER}.tar.gz
# Only update newer files
tar -xz --keep-newer-files -f redis-${REDIS_VER}.tar.gz > /dev/null

cd redis-${REDIS_VER}
make -s > /dev/null 
make -s install > /dev/null
mkdir -p /etc/redis
mkdir /var/redis
chmod -R 777 /var/redis
useradd redis

echo "Configuring redis"
cp -u /vagrant/conf/redis/redis.conf /etc/redis/6379.conf
cp -u /vagrant/conf/redis/redis.init.d /etc/init.d/redis_6379

update-rc.d redis_6379 defaults > /dev/null

echo "starting redis"
chmod a+x /etc/init.d/redis_6379
/etc/init.d/redis_6379 start > /dev/null