FROM 	debian:10

RUN	apt-get update -y \
	&& apt-get upgrade -y \
	&& apt-get -y install wget \
	&& apt-get -y install php-fpm php-mysql php-mbstring php-zip php-gd php-xml php-pear php-gettext php-cgi \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini \ 
	&& apt-get -y install mariadb-server mariadb-client \
	&& apt-get -y install nginx

COPY 	srcs/default /etc/nginx/sites-enabled/

RUN 	/etc/init.d/mysql start

COPY 	srcs/user_create.sh /

RUN	wget https://wordpress.org/latest.tar.gz \
	&& tar xpf latest.tar.gz \
	&& rm -rf /var/www/html	\
	&& cp -r wordpress /var/www/html \
	&& chown -R www-data:www-data /var/www/html \
	&& find /var/www/html -type d -exec chmod 755 {} \; \
	&& find /var/www/html -type f -exec chmod 644 {} \; \
	&& rm latest.tar.gz

RUN 	wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-english.tar.gz \
	&& mkdir /var/www/html/phpmyadmin \
	&& tar -zxvf phpMyAdmin-4.9.0.1-english.tar.gz -C /var/www/html/phpmyadmin \
	&& rm phpMyAdmin-4.9.0.1-english.tar.gz
COPY 	srcs/config.inc.php /var/www/html/phpmyadmin
RUN 	chmod 660 /var/www/html/phpmyadmin/config.inc.php \
	&& chown -R www-data:www-data /var/www/html/phpmyadmin

COPY 	srcs/info.php ./root/
RUN 	cp ./root/info.php /var/www/html/ \
	&& chown -R www-data:www-data /var/www/html/info.php

RUN 	openssl req -x509 -subj "/C=FR/ST=IDF/L=Paris/O=SuperCompany/OU=NVM/CN=IamRoot/emailAddress=who@cares.com" -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt \
	&& openssl dhparam -out /etc/nginx/dhparam.pem 2048

RUN 	service mysql start \ 	
	&& sh user_create.sh

COPY 	srcs/self-signed.conf /etc/nginx/snippets/ 
COPY 	srcs/ssl-params.conf /etc/nginx/snippets/

RUN 	apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

CMD ["sh","-c", "service php7.3-fpm start ; nginx -s reload ; service php7.3-fpm restart ; service mysql restart ; service nginx restart ; tail -f /dev/null"]
