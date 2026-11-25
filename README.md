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

After `make init`, check that the prod image really starts:

```bash
make smoke-prod
```

It builds the prod image, starts it once against the dev database on
`http://localhost:8001`, prints its last log lines, removes the container and
fails if the app does not answer or answers with a 5xx error.

## Cleaning up

- `make rm-containers` removes this project's containers and keeps the database.
- `make rm-all` also removes the volumes, **including the database**.
