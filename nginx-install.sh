#!/bin/bash
nginx_version=1.13.6
NPS_VERSION=1.12.34.2-stable

apt-get install git build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev zip unzip -y
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
	--add-module=/root/ngx_pagespeed-$NPS__VERSION \
	--add-module=/root/ngx_brotli \
	--with-http_v2_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module
make
make install
