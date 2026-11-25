# Docker AMP Symfony

The purpose of this template project is to provide a quick and easy way to get
a Symfony project up and running with Docker. This project uses
[FrankenPHP](https://frankenphp.dev) (PHP served by Caddy), MariaDB and
phpMyAdmin.

## Requirements

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Make](https://www.gnu.org/software/make/manual/make.html) (optional — [install `make` for Windows](https://stackoverflow.com/questions/2532234/how-to-run-a-makefile-in-windows))

## Usage

The database credentials come from the `MARIADB_ROOT_PASSWORD`, `MARIADB_USER`,
`MARIADB_PASSWORD` and `MARIADB_DATABASE` environment variables. Export them in
your shell, or change their defaults in `compose.yaml`.

Docker Compose names the containers after the project folder, so rename the
folder to something meaningful before you start.

Then, you can run the following command if you have `make`.

It will:
- Build the containers
- Start the containers
- Create a new Symfony project in an empty directory
- Move the Symfony project to the root directory
- Remove the temporary project directory
- Clear the Symfony cache

```bash
make init
```

By default it installs the latest stable Symfony as a full web app
(`--webapp`). Choose another project type or version with `TYPE` and `VERSION`:

```bash
make init TYPE=api                 # API project (--api, API Platform)
make init VERSION=lts              # a version, or lts, stable, next, previous
make init TYPE=api VERSION="7.4.*"
```

### Or, step by step

You can run the following command to build the containers:

```bash
make build # or `docker compose build --build-arg UID=$(id -u) --build-arg GID=$(id -g)` if you don't have `make`
```

An image with [PHP](https://www.php.net), [FrankenPHP](https://frankenphp.dev), [Composer](https://getcomposer.org) and [Symfony CLI](https://symfony.com/download) ready to use will be built.

After that, you can run the following command to start the containers:

```bash
make up # or `docker compose up -d` if you don't have `make`
```

FrankenPHP should be ready to serve, but you don't have a Symfony project yet.
You can create one by entering the `app` container:

```bash
make exec # or `docker compose exec app bash` if you don't have `make`
          # it will open a bash session inside the container
```

Then, you can create a new Symfony project in the root directory by running the `init-symfony.sh` script:

```bash
./init-symfony.sh                        # or: TYPE=api VERSION=lts ./init-symfony.sh
```

You can now access:
- your Symfony project at `http://localhost:8000`
- phpMyAdmin at `http://localhost:8080`

Remember that every time you want to run a Symfony command, you should run it
inside the container thanks to the `make exec` command.

## Production image

```bash
make build-prod
```

It builds the `prod` target as the separate `app-prod` service, so it never
replaces the dev image used by `make up`.

The prod image runs FrankenPHP in [worker mode](https://frankenphp.dev/docs/worker/):
the Symfony kernel boots once and stays in memory between requests. Change it
with the `FRANKENPHP_CONFIG` environment variable, for example in your
hosting panel:

- `worker /app/public/index.php 8` sets the number of workers.
- An empty value goes back to classic mode.

Services that keep state between requests must implement `ResetInterface`.
Dev stays in classic mode, so code changes show up without a restart.

After `make init`, check that the prod image really starts:

```bash
make smoke-prod
```

It builds the prod image, starts it once against the dev database on
`http://localhost:8001`, prints its last log lines, removes the container and
fails if the app does not answer or answers with a 5xx error.

The prod image runs as the non-root `appuser` (numeric `UID:GID`), with no
Linux capability, so it works with `cap_drop: ALL` and Kubernetes
`runAsNonRoot`. A volume mounted on `/app/var` must be writable by that UID:
named volumes are, a bind mount owned by root is not. With a read-only root
filesystem, also mount `/config` and `/data`, where Caddy keeps its state.

It is built on [distroless](https://github.com/GoogleContainerTools/distroless),
as in FrankenPHP's [hardening guide](https://frankenphp.dev/docs/docker/#hardening-images):
no shell, no package manager, no `php` binary. So:

- On start, `bin/console app:entrypoint` warms the cache, runs the Doctrine
  migrations, then hands over to the server. `make init` copies this command
  to `src/Command/EntrypointCommand.php`; for a project created before, copy
  it from `docker/symfony/`.
- Run console commands with `frankenphp php-cli`, for example
  `docker compose --profile prod run --rm --entrypoint /usr/local/bin/frankenphp app-prod php-cli bin/console about`.
- To debug inside the image, build the `prod-build` target instead: it has a
  shell and the same app.
- A PHP extension added to `install-php-extensions` gets its shared libraries
  copied automatically; `make smoke-prod` tells you if one is missing.

## Cleaning up

- `make rm-containers` removes this project's containers and keeps the database.
- `make rm-all` also removes the volumes, **including the database**.
