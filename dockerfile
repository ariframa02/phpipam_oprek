FROM ubuntu:latest
MAINTAINER Arif

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
RUN rm -rf /etc/nginx/sites-enabled/default
COPY ./config/nginx/phpIPAM /etc/nginx/sites-enabled

#Menambahkan phpinfo untuk pengecekan versi
COPY ./config/nginx/info.php /usr/share/nginx/html/
RUN nginx -t

#Install php versi 7.4
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
# COPY ./config/mariadb/config.php /usr/share/nginx/html/phpIPAM/
# RUN chown www-data /usr/share/nginx/html/phpIPAM/app/admin/import-export/upload && \
#    chown www-data /usr/share/nginx/html/phpIPAM/app/subnets/import-subnet/upload && \
#    chown www-data /usr/share/nginx/html/phpIPAM/css/images/logo
ENV PHPIPAM_BASE /
RUN cp ${WEB_REPO}/config.dist.php ${WEB_REPO}/config.php && \
    chown www-data /usr/share/nginx/html/phpIPAM/app/admin/import-export/upload && \
    chown www-data /usr/share/nginx/html/phpIPAM/app/subnets/import-subnet/upload && \
    chown www-data /usr/share/nginx/html/phpIPAM/css/images/logo && \
    echo "\$db['webhost'] = '%';" >> ${WEB_REPO}/config.php && \
    sed -i -e "s/\['host'\] = '127.0.0.1'/\['host'\] = getenv(\"MYSQL_ENV_MYSQL_HOST\") ?: \"labs_database\"/" \
    -e "s/\['user'\] = 'phpipam'/\['user'\] = getenv(\"MYSQL_ENV_MYSQL_USER\") ?: \"root\"/" \
    -e "s/\['name'\] = 'phpipam'/\['name'\] = getenv(\"MYSQL_ENV_MYSQL_DB\") ?: \"phpipam\"/" \
    -e "s/\['pass'\] = 'phpipamadmin'/\['pass'\] = getenv(\"MYSQL_ENV_MYSQL_ROOT_PASSWORD\")/" \
    -e "s/\['port'\] = 3306;/\['port'\] = 3306;\n\n\$password_file = getenv(\"MYSQL_ENV_MYSQL_PASSWORD_FILE\");\nif(file_exists(\$password_file))\n\$db\['pass'\] = preg_replace(\"\/\\\\s+\/\", \"\", file_get_contents(\$password_file));/" \
    -e "s/define('BASE', \"\/\")/define('BASE', getenv(\"PHPIPAM_BASE\"))/" \
    -e "s/\$gmaps_api_key.*/\$gmaps_api_key = getenv(\"GMAPS_API_KEY\") ?: \"\";/" \
    -e "s/\$gmaps_api_geocode_key.*/\$gmaps_api_geocode_key = getenv(\"GMAPS_API_GEOCODE_KEY\") ?: \"\";/" \
    ${WEB_REPO}/config.php

#Membuka port http
EXPOSE 80

#Menjalankan php-fpm dan nginx
CMD /etc/init.d/php7.4-fpm start -F && nginx -g "daemon off;"
