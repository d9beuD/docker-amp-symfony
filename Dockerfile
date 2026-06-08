FROM php:8.5-fpm

WORKDIR /var/www

# Updating packages and installing dependencies in a single layer with cache cleaning
RUN apt-get update -y --allow-insecure-repositories && \
    apt-get install -y --no-install-recommends \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libzip-dev \
        rsync \
        unzip \
        sudo \
        zip && \
        apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
        gd \
        intl \
        mbstring \
        pdo_mysql \
        zip

# Installation of Composer to install PHP packages
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Installation of Symfony CLI with cache cleaning
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt-get install -y symfony-cli && \
    symfony server:ca:install && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
