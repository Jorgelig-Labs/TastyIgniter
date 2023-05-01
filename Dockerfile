FROM php:7.4-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		unzip \
		openssl \
		libcurl4-openssl-dev \
		libjpeg-dev \
		libpng-dev \
		libmcrypt-dev \
		libxml2-dev \
		libonig-dev \
		libzip-dev \
        nodejs  \
        npm  \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-jpeg=/usr; \
	docker-php-ext-install -j$(nproc) pdo_mysql curl dom gd mbstring json tokenizer zip exif

RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite
# Establecer el directorio de trabajo
VOLUME /var/www/html

ARG TASTYIGNITER_VERSION
ENV VERSION=$TASTYIGNITER_VERSION

# Copiar el código de la aplicación al contenedor
COPY . .

# Copiar el archivo de variables de entorno
COPY .env .env

# Instalar dependencias de composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-dev --no-interaction --no-ansi

# Configurar permisos de archivo
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Copiar el script de ejecución
COPY "/infrastructure/docker-entrypoint.sh" "/usr/local/bin/"
COPY "/infrastructure/run.sh" "/usr/local/bin/"
COPY "/infrastructure/.htaccess" "/usr/src/tastyigniter/"


# Dar permisos de ejecución al script de ejecución
# RUN chmod 755 run.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/run.sh

# Iniciar la aplicación con PHP
# ENTRYPOINT  ["/usr/local/bin/docker-entrypoint.sh"]
ENTRYPOINT  ["/usr/local/bin/run.sh"]
CMD ["apache2-foreground"]
