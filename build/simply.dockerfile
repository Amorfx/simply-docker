FROM php:8.1-fpm as base
LABEL name=simply
LABEL intermediate=true

# Install essential packages
RUN apt-get update \
  && apt-get install -y \
    build-essential \
    curl \
    git \
    gnupg \
    less \
    nano \
    vim \
    unzip \
    zip \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

FROM base as php
LABEL name=simply
LABEL intermediate=true

# Install php extensions and related packages
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync \
  && install-php-extensions \
    @composer \
    exif \
    gd \ 
    memcached \
    mysqli \
    pcntl \
    pdo_mysql \
    zip \
  && apt-get update \
  && apt-get install -y \
    gifsicle \
    jpegoptim \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libmemcached-dev \
    locales \
    lua-zlib-dev \
    optipng \
    pngquant \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

FROM php as simply
LABEL name=simply

# Install nginx & supervisor
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash \
  && apt-get update \
  && apt-get install -y \
    nginx \
    nodejs \
    supervisor \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && npm install -g yarn

# Configure nginx, php-fpm and supervisor
COPY ./build/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./build/nginx/sites-enabled /etc/nginx/conf.d
COPY ./build/nginx/sites-enabled /etc/nginx/sites-enabled
COPY ./build/php/8.1/fpm/pool.d /etc/php/8.1/fpm/pool.d
COPY ./build/supervisor/supervisord.conf /etc/supervisord.conf

# WordPress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/bin/_wp;
COPY ./build/bin/wp.sh /srv/wp.sh
RUN chmod +x /srv/wp.sh \
  && mv /srv/wp.sh /usr/bin/wp

# Installation helper
COPY ./build/bin/simply-install.sh /srv/simply-install.sh
RUN chmod +x /srv/simply-install.sh

WORKDIR /srv/simply
CMD ["/srv/simply-install.sh"]
