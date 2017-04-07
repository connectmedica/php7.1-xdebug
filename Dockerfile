FROM php:7.1-apache

# Install PHP extensions
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update && apt-get install -y \
      libicu-dev \
      libpq-dev \
      libmcrypt-dev \
      mysql-client \
      libmysqlclient-dev \
      ruby-full \
      nodejs \
      git \
    && rm -r /var/lib/apt/lists/* \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-install \
      intl \
      mbstring \
      mcrypt \
      mysqli \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      zip \
      opcache \
      bcmath

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# SASS compiler
RUN su -c "gem install sass"

# Install Xdebug
RUN curl -fsSL 'https://xdebug.org/files/xdebug-2.5.1.tgz' -o xdebug.tar.gz \
    && mkdir -p xdebug \
    && tar -xf xdebug.tar.gz -C xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && ( \
    cd xdebug \
    && phpize \
    && ./configure --enable-xdebug \
    && make -j$(nproc) \
    && make install \
    ) \
    && rm -r xdebug \
    && docker-php-ext-enable xdebug

# Put apache config
COPY apache-vhost.conf /etc/apache2/sites-available/custom-vhost.conf
RUN a2dissite 000-default.conf && a2ensite custom-vhost.conf && a2enmod rewrite

# Change uid and gid of apache to docker user uid/gid
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN composer global require "hirak/prestissimo:^0.3"

WORKDIR /var/www/html 
