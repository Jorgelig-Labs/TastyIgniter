admin:
		clear; echo "Escribe password para el usuario admin:";docker-compose exec app php artisan igniter:passwd admin

extensions:
		bash bin/extensions.sh
