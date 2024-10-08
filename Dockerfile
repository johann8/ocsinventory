FROM centos:centos7

ENV OCS_VERSION 2.12.3

LABEL maintainer="contact@ocsinventory-ng.org" \
      version="${OCS_VERSION}" \
      description="OCS Inventory docker image"

ARG YUM_FLAGS="-y"

ENV APACHE_RUN_USER=apache APACHE_RUN_GROUP=apache \
    APACHE_LOG_DIR=/var/log/httpd APACHE_PID_FILE=/var/run/httpd.pid APACHE_RUN_DIR=/var/run/httpd APACHE_LOCK_DIR=/var/lock/httpd \
    OCS_DB_SERVER=dbsrv OCS_DB_PORT=3306 OCS_DB_USER=ocs OCS_DB_PASS=ocs OCS_DB_NAME=ocsweb \
    OCS_LOG_DIR=/var/log/ocsinventory-server OCS_VARLIB_DIR=/var/lib/ocsinventory-reports/ OCS_WEBCONSOLE_DIR=/usr/share/ocsinventory-reports \
    OCS_PERLEXT_DIR=/etc/ocsinventory-server/perl/ OCS_PLUGINSEXT_DIR=/etc/ocsinventory-server/plugins/ \
    OCS_SSL_ENABLED=0 OCS_SSL_WEB_MODE=DISABLED OCS_SSL_COM_MODE=DISABLED OCS_SSL_KEY=/path/to/key OCS_SSL_CERT=/path/to/cert OCS_SSL_CA=/path/to/ca \
    TZ=Europe/Paris

VOLUME /var/lib/ocsinventory-reports /etc/ocsinventory-server /usr/share/ocsinventory-reports/ocsreports/extensions

RUN sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-* && \
    sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*

RUN yum ${YUM_FLAGS} install wget \
    curl \
    yum-utils \
    tar \
    make \
    yum ${YUM_FLAGS} install epel-release ; \
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ; \
    wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm ; \
    rpm -Uvh remi-release-7.rpm ; \
    yum-config-manager --enable remi-php74 ; \
    #yum-config-manager --enable remi-php80 ; \
    yum ${YUM_FLAGS} update ; \
    yum ${YUM_FLAGS} install perl \
    perl-XML-Simple \
    perl-Compress-Zlib \
    perl-DBI perl-DBD-MySQL \
    perl-Net-IP \
    perl-Apache2-SOAP \
    perl-Archive-Zip \
    perl-Mojolicious \
    perl-Plack \
    perl-XML-Entities \
    perl-Switch \
    perl-Apache-DBI \
    httpd \
    php \
    php-cli \
    php-ldap \
    php-gd \
    php-imap \
    php-pdo \
    php-pear \
    php-mbstring \
    php-intl \
    php-mysqlnd \
    php-xml \
    php-xmlrpc \
    php-pecl-mysql \
    php-pecl-mcrypt \
    php-pecl-apcu \
    php-json \
    php-fpm \
    php-soap \
    php-zip \
    php-opcache ;

RUN wget https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/${OCS_VERSION}/OCSNG_UNIX_SERVER-${OCS_VERSION}.tar.gz -P /tmp && \
    tar xzf /tmp/OCSNG_UNIX_SERVER-${OCS_VERSION}.tar.gz -C /tmp;

RUN cd /tmp/OCSNG_UNIX_SERVER-${OCS_VERSION}/Apache/ && \
    perl Makefile.PL && \
    make && \
    make install ;

WORKDIR /etc/httpd/conf.d

# Redirect Apache2 Logs to stdout e stderr
# https://github.com/docker-library/httpd/blob/5f92ab18146f41d1d324e99c5e197bdeda65d063/2.4/Dockerfile#L202
RUN sed -ri \
      -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
      -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
      -e 's!^(\s*TransferLog)\s+\S+!\1 /proc/self/fd/1!g' \
      "/etc/httpd/conf/httpd.conf"

COPY conf/ /tmp/conf
COPY ./scripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

EXPOSE 80 443

# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#entrypoint
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
