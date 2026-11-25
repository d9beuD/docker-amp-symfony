build:
	docker compose build --build-arg UID=$$(id -u) --build-arg GID=$$(id -g)

# Separate app-prod service, so the prod image never replaces the dev image
build-prod:
	docker compose --profile prod build app-prod --build-arg UID=$$(id -u) --build-arg GID=$$(id -g)

# Start the prod image once against the dev database.
# Fails on no answer or a 5xx; 404 is fine (a fresh app has no route at /).
smoke-prod: build-prod
	docker compose --profile prod up -d app-prod
	@code=000; for i in $$(seq 60); do \
		code=$$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8001/ || true); \
		[ "$$code" != 000 ] && break; sleep 1; \
	done; \
	docker compose --profile prod logs --tail 20 app-prod; \
	docker compose --profile prod rm -sf app-prod; \
	echo "smoke-prod: HTTP $$code"; \
	[ "$$code" != 000 ] && [ "$$code" -lt 500 ]

up:
	docker compose up -d

logs:
	docker compose logs -f

stop:
	docker compose stop

restart: stop up

exec:
	docker compose exec app /bin/bash

# Override on the command line: make init TYPE=api VERSION="7.4.*"
# Plain = so a stray TYPE/VERSION in the shell environment is ignored
TYPE = webapp
VERSION = stable

init-symfony:
	docker compose exec -e TYPE='$(TYPE)' -e VERSION='$(VERSION)' app ./init-symfony.sh

init: build up init-symfony

# Command to remove Symfony project files only
rm-symfony:
	docker compose exec app sh -c \
	"rm -rf \
	./assets \
	./bin \
	./config \
	./migrations \
	./public/index.php \
	./src \
	./templates \
	./tests \
	./translations \
	./var \
	./vendor \
	./composer.json \
	./composer.lock \
	./symfony.lock \
	./phpunit.xml.dist \
	./.env \
	./.env.test \
	./.gitignore \
	./importmap.php"

# Remove this project's containers
rm-containers:
	docker compose down

# Remove this project's containers AND volumes: deletes the database
rm-all:
	docker compose down -v
