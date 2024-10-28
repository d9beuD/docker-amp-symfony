build:
	docker compose --progress=plain build

up:
	docker compose up -d

logs:
	docker compose logs -f

stop:
	docker compose stop

down:
	docker compose down

restart: stop up

exec:
	docker compose exec apache /bin/bash

init-symfony:
	docker compose exec apache sh -c "./init-symfony.sh"

init: build up init-symfony

rm:
	docker compose down -v

prune:
	docker system prune -f --volumes
