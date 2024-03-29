FROM php:8.1-fpm-alpine

# Install modules
RUN set -xe && apk update && apk add --no-cache \
    shadow \
    libzip \
    bash \
    curl \
    icu-dev \
    libmcrypt-dev \
    libxml2-dev \
    postgresql-libs \
    postgresql-dev \
    libzip-dev \
    pcre-dev \
    git \
    autoconf \
    g++ \
    make \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    freetype \
    libpng \
    libjpeg-turbo \
    freetype-dev \
    libpng-dev \
    zlib \
    libjpeg-turbo-dev \
    && rm -rf /var/cache/apk/*

RUN docker-php-ext-configure gd \
         --enable-gd \
         --with-freetype \
         --with-jpeg && \
    docker-php-ext-install intl pdo pgsql pdo_pgsql zip sockets exif gd

# Logs
RUN mkdir -p /var/log/php8-fpm && \
    chown -R www-data:www-data /var/log/php8-fpm

# Install composer && global asset plugin
ENV COMPOSER_HOME $HOME/.composer
ENV PATH $HOME/.composer/vendor/bin:$PATH
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
