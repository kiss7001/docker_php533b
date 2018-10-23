FROM centos:6.6
MAINTAINER wooyoung Kim <kiss7001@nate.com>

# 패키지 설치
RUN yum update ; yum install -y \
      wget

RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
RUN rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

RUN yum update ; yum install -y \
      httpd \
      php \
      php-devel \
      php-mysql \
      ld-linux.so.2 \
      sendmail \
      php-soap \
      php-gd \
      php-imap \
      php-mcrypt* \
      php-pecl-ssh2 \
      php-mbstring

RUN yum clean all

RUN cp /etc/php.ini /etc/php.ini.ori
RUN cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.ori

RUN sed -i "s/^#ServerName www.example.com:80$/ServerName www.rosettakorea.com/" /etc/httpd/conf/httpd.conf
RUN sed -i "s/^DirectoryIndex index.html index.html.var$/DirectoryIndex index.html index.php index.html.var/" /etc/httpd/conf/httpd.conf
RUN sed -i "s/AllowOverride None$/AllowOverride All/" /etc/httpd/conf/httpd.conf

RUN sed -i "s/^register_long_arrays = Off$/register_long_arrays = On/" /etc/php.ini
RUN sed -i "s/^;date.timezone =$/date.timezone = \"Asia\/Seoul\"/" /etc/php.ini
RUN sed -i "s/^error_reporting = E_ALL \& ~E_DEPRECATED$/error_reporting = E_ALL \& ~E_NOTICE/" /etc/php.ini
RUN sed -i "s/^short_open_tag = Off$/short_open_tag = On/" /etc/php.ini
RUN sed -i "s/^post_max_size = 8M$/post_max_size = 800M/" /etc/php.ini
RUN sed -i "s/^upload_max_filesize = 2M$/upload_max_filesize = 800M/" /etc/php.ini

VOLUME ["/var/www/html","/data"]

RUN \
  # Create script to use as new entrypoint, which
  # 1. Creates a localhost entry for container hostname in /etc/hosts
  # 2. Restarts sendmail to discover this entry
  # 3. Calls original docker-entrypoint.sh
 echo '#!/bin/bash' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 && echo 'set -euo pipefail' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 && echo 'echo "127.0.0.1 $(hostname) localhost localhost.localdomain" >> /etc/hosts' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 && echo 'service sendmail start' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 && echo '/usr/sbin/apachectl -D FOREGROUND' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 #&& echo 'exec docker-entrypoint.sh "$@"' >> /usr/local/bin/docker-entrypoint-wrapper.sh \
 && chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]

EXPOSE 80
