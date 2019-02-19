FROM php:7.3-apache

RUN apt-get update && \
apt-get install -y wget nginx supervisor libapache2-mod-rpaf sudo git mc net-tools openssh-server mysql-client vim nano msmtp \
	cron gcc make libjpeg-dev libpng-dev libtiff-dev libvpx-dev libxpm-dev libfontconfig1-dev libxpm-dev checkinstall \
	libicu-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libxml2 \
        libxml2-dev \
        libcurl4-openssl-dev \
        libpspell-dev \
        libtidy-dev \
        libgeoip-dev \
        libxslt1-dev \
        libgmp-dev \
        libzip-dev 

WORKDIR /usr/src


RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN docker-php-ext-install gd  



RUN docker-php-ext-install pdo pdo_mysql zip bcmath ctype curl dom gettext \
    hash iconv json mbstring mysqli opcache posix pspell  session shmop simplexml  \
    soap sockets tidy tokenizer wddx xsl zip pdo pdo_mysql xml  xmlrpc xmlwriter exif intl gmp

RUN pecl install geoip-1.1.1  && echo "extension=geoip.so" >> /usr/local/etc/php/conf.d/geoip.ini 



RUN a2enmod rpaf rewrite
ADD apache-security.conf /etc/apache2/conf-enabled/security.conf

ADD supervisord.conf /etc/supervisor/


RUN useradd -m -d /home/sftpdev/ -s /bin/bash -o -g 33 -u 33 sftpdev; \
    echo "sftpdev ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers; \
    echo "www-data ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN ln -s /var/www/html /home/sftpdev/html -f

RUN mkdir /var/run/sshd; chmod 0755 /var/run/sshd
RUN sed -i "s/Listen 80/Listen 81/g" /etc/apache2/ports.conf

RUN rm -rf /etc/apache2/sites-enabled/*
ADD apache-default-vhost.conf /etc/apache2/sites-enabled/
ADD nginx.conf /etc/nginx/

RUN echo "DOCKER PHP_VERSION=$PHP_VERSION; BUILD DATE: `date -I`" > /etc/motd


RUN echo 'sendmail_path = "/usr/bin/msmtp -C /var/www/.msmtprc  -t"' > /usr/local/etc/php/conf.d/sendmail-msmtp.ini

WORKDIR /home/sftpdev

ADD start.sh /
CMD ["/start.sh"]


#COMPOSER
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer





RUN chown 33:33 /var/www/


#CLEAN
RUN apt-get remove -y gcc make libjpeg-dev libpng-dev libtiff-dev libvpx-dev libxpm-dev libfontconfig1-dev libxpm-dev checkinstall  libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libpspell-dev \
        libtidy-dev \
        libxslt1-dev \
        && rm -rf /var/lib/apt/lists/*

