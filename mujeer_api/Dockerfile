FROM php:8.2-apache

# Install mysqli, pdo_mysql, and other needed extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql && \
    a2enmod rewrite

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-gd

# Set permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]