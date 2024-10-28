FROM php:8.3.11-apache

WORKDIR /var/www
ENV DEBIAN_FRONTEND noninteractive
ENV WWW_ROOT="/var/www"

# Install dependencies
RUN apt-get clean && apt-get update -y --allow-insecure-repositories
RUN apt-get install -y \
    git \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libpng-dev \
    libzip-dev \
    unzip \
    sudo \
    zip

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    mbstring \
    opcache \
    pdo_mysql \
    zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
RUN apt-get install symfony-cli
RUN symfony server:ca:install

# Configure Apache
ADD docker/apache/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

RUN a2enmod rewrite
RUN a2enmod remoteip
RUN a2enmod ssl

CMD ["/entrypoint.sh"]

EXPOSE 80