FROM php:8.2-fpm-alpine

# Install extensions
RUN apk add --no-cache nginx git unzip libzip-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-gd

RUN chown -R www-data:www-data /var/www/html

# Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD sh -c "php-fpm && nginx -g 'daemon off;'"
