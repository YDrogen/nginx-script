#!/bin/bash
nginx_version=1.13.6
NPS_VERSION=1.12.34.3-stable

apt-get install git build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev zip unzip mysql-server -y
wget http://nginx.org/download/nginx-$nginx_version.tar.gz
wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}.zip
unzip v${NPS_VERSION}.zip
cd ngx_pagespeed-${NPS_VERSION}/
NPS_RELEASE_NUMBER=${NPS_VERSION/beta/}
NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})
cd /root/
git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli
git submodule update --init --recursive
cd /root/
tar -zxvf nginx-$nginx_version.tar.gz
cd nginx-$nginx_version
./configure \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-threads \
	--add-module=/root/ngx_pagespeed-$NPS_VERSION \
	--add-module=/root/ngx_brotli \
	--with-http_v2_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module
make
make install

PURGE_EXPECT_WHEN_DONE=1
CURRENT_MYSQL_PASSWORD='root'
NEW_MYSQL_PASSWORD='root'
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -n "${1}" -a -z "${2}" ]; then
    # Setup root password
    CURRENT_MYSQL_PASSWORD=''
    NEW_MYSQL_PASSWORD="${1}"
elif [ -n "${1}" -a -n "${2}" ]; then
    # Change existens root password
    CURRENT_MYSQL_PASSWORD="${1}"
    NEW_MYSQL_PASSWORD="${2}"
else
    echo "Usage:"
    echo "  Setup mysql root password: ${0} 'your_new_root_password'"
    echo "  Change mysql root password: ${0} 'your_old_root_password' 'your_new_root_password'"
    exit 1
fi

#
# Check is expect package installed
#
if [ $(dpkg-query -W -f='${Status}' expect 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Can't find expect. Trying install it..."
    aptitude -y install expect

fi

SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

#
# Execution mysql_secure_installation
#
echo "${SECURE_MYSQL}"

if [ "${PURGE_EXPECT_WHEN_DONE}" -eq 1 ]; then
    # Uninstalling expect package
    aptitude -y purge expect
fi

cd /root/
curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
chmod +x nodesource_setup.sh
./nodesource_setup.sh
apt-get install nodejs -y
npm i -g pm2
npm i -g supervisor
