#!/bin/sh
set -eu

APP_RUNTIME_ENV="${APP_ENV:-prod}"

mkdir -p \
	"/app/var/cache/${APP_RUNTIME_ENV}/pools/system" \
	/app/var/log

php /app/bin/console cache:warmup --env="${APP_RUNTIME_ENV}" --no-debug --no-interaction
php /app/bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

exec "$@"
