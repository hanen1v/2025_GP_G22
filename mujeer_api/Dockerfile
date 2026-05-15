FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    php8.1 \
    php8.1-mysql \
    php8.1-zip \
    php8.1-curl \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-gd \
    php8.1-intl \
    libapache2-mod-php8.1 \
    git \
    unzip \
    curl \
    && apt-get clean

RUN a2enmod php8.1 rewrite

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . /var/www/html/

WORKDIR /var/www/html

RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --no-dev \
    --optimize-autoloader \
    --ignore-platform-req=ext-gd \
    --ignore-platform-req=ext-mbstring

RUN chown -R www-data:www-data /var/www/html \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]