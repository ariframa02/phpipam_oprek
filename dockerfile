FROM ubuntu:latest
MAINTAINER kulioprek

ENV WEB_REPO /usr/share/nginx/html/phpIPAM
ENV TZ="Asia/Jakarta"

ARG DEBIAN_FRONTEND=noninteractive

# Install timezone
RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Install nginx
RUN apt-get install -y nginx
COPY ./config/nginx/phpipam.conf /etc/nginx/conf.d/phpipam.conf
RUN rm -rf /etc/nginx/sites-enabled/default 
RUN nginx -t

#Install php versi 7.4ping
RUN apt-get -y install software-properties-common && \
    add-apt-repository ppa:ondrej/php

RUN apt-get update && apt-get install -y php7.4 \
    php7.4-fpm php7.4-cli php7.4-json php7.4-common \
    php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring \
    php7.4-curl php7.4-xml php7.4-bcmath php-pear php7.4-gmp

RUN mkdir /run/php/ 
RUN php -v

#Install phpIPAM
RUN apt-get install -y git
RUN git clone https://github.com/phpipam/phpipam.git /usr/share/nginx/html/phpIPAM
COPY ./config/mariadb/config.php /usr/share/nginx/html/phpIPAM/
RUN chown www-data -R /usr/share/nginx/html/phpIPAM && \
    chown www-data /usr/share/nginx/html/phpIPAM/app/admin/import-export/upload && \
    chown www-data /usr/share/nginx/html/phpIPAM/app/subnets/import-subnet/upload && \
    chown www-data /usr/share/nginx/html/phpIPAM/css/images/logo

#Menambahkan phpinfo untuk pengecekan versi
COPY ./config/nginx/info.php /usr/share/nginx/html/phpIPAM/

#Membuka port http
EXPOSE 80

#Menjalankan php-fpm dan nginx
CMD /etc/init.d/php7.4-fpm start -F && nginx -g "daemon off;"
