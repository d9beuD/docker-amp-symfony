build:
	docker compose --progress=plain build

up:
	docker compose up -d

logs:
	docker compose logs -f

stop:
	docker compose stop

restart: stop up

exec:
	docker compose exec apache /bin/bash
