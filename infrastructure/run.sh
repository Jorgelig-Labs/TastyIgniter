#!/bin/bash

chown -R www-data:www-data /var/www/html
composer install
php artisan key:generate  --force
php artisan migrate --seed
npm install && npm run dev

exec "$@"
