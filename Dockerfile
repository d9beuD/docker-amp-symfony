# syntax=docker/dockerfile:1.7

# Shared by the stages below, which re-declare the ones they use
ARG UID=1000
ARG GID=1000
# x-release-please-start-version
ARG APP_VERSION=3.0.0
# x-release-please-end

FROM dunglas/frankenphp:1-php8.4-trixie AS base

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends unzip git && \
	rm -rf /var/lib/apt/lists/*

ARG USER=appuser
ARG UID
ARG GID

# Common setup for dev and prod
RUN \
	set -eux; \
	if getent group "${GID}" >/dev/null; then \
		group_name="$(getent group "${GID}" | cut -d: -f1)"; \
	else \
		group_name="${USER}"; \
		groupadd --gid "${GID}" "${group_name}"; \
	fi; \
	useradd --uid "${UID}" --gid "${GID}" --create-home --shell /usr/sbin/nologin "${USER}"; \
	chown -R "${USER}:${group_name}" /config/caddy /data/caddy; \
	# :3000 is unprivileged, so drop the bind capability; lets the image run with cap_drop: ALL
	setcap -r /usr/local/bin/frankenphp

# Add PHP extensions here if needed
RUN install-php-extensions \
	intl \
    pdo_mysql \
    zip \
    pcntl

# Composer for PHP dependencies
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

COPY docker/caddy/Caddyfile /etc/caddy/Caddyfile

FROM base AS dev

# Development php.ini
RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini

# Symfony CLI needs a writable config/cache home
RUN mkdir -p /home/${USER}/.config/symfony-cli/cache /home/${USER}/.cache && \
	chown -R ${UID}:${GID} /home/${USER}

ENV HOME=/home/${USER} \
	XDG_CONFIG_HOME=/home/${USER}/.config \
	XDG_CACHE_HOME=/home/${USER}/.cache \
	XDG_DATA_HOME=/home/${USER}/.local/share

# Symfony CLI, and rsync for init-symfony.sh, only for dev
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash && \
    apt-get install -y symfony-cli rsync && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

USER ${USER}

# Builds the app; the prod stage below keeps only what it needs to run
FROM base AS prod-build

# Production php.ini
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY docker/php/php.ini $PHP_INI_DIR/conf.d/zz-prod-opcache.ini

COPY composer.json composer.lock /app/

RUN --mount=type=cache,target=/tmp/composer-cache \
    COMPOSER_CACHE_DIR=/tmp/composer-cache \
    composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

ENV APP_ENV=prod APP_DEBUG=0

COPY . /app

RUN mkdir -p /app/var/cache/prod/pools/system /app/var/log && \
	composer dump-autoload --no-dev --classmap-authoritative --no-interaction && \
	composer run-script post-install-cmd --no-interaction && \
	php /app/bin/console asset-map:compile && \
	chown -R "${UID}:${GID}" /app/var

# Shared libraries of frankenphp and every PHP extension, for the distroless stage
RUN apt-get update && apt-get install -y --no-install-recommends libtree && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p /tmp/libs && \
	for target in "$(command -v frankenphp)" \
		$(find "$(php -r 'echo ini_get("extension_dir");')" -maxdepth 2 -name '*.so'); do \
		libtree -pv "$target" 2>/dev/null | grep -oP '(?:── )\K/\S+(?= \[)' | while IFS= read -r lib; do \
			[ -f "$lib" ] && cp -n "$lib" /tmp/libs/; \
		done; \
	done

# No shell, no package manager: see "Hardening images" in the FrankenPHP Docker docs
# Debian 13 (trixie), same as the base image
FROM gcr.io/distroless/base-debian13 AS prod

ARG UID
ARG GID
ARG APP_VERSION

COPY --from=prod-build /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=prod-build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=prod-build /tmp/libs /usr/lib
COPY --from=prod-build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=prod-build /usr/local/etc/php/php.ini /usr/local/etc/php/php.ini
COPY --from=prod-build /etc/caddy/Caddyfile /etc/caddy/Caddyfile

# Caddy config and data must be writable by the app user
ENV XDG_CONFIG_HOME=/config XDG_DATA_HOME=/data
COPY --from=prod-build --chown=${UID}:${GID} /config /config
COPY --from=prod-build --chown=${UID}:${GID} /data /data

# The app stays root-owned, only var/ is writable
COPY --from=prod-build /app /app
COPY --from=prod-build --chown=${UID}:${GID} /app/var /app/var

ENV APP_ENV=prod APP_DEBUG=0
ENV APP_VERSION=${APP_VERSION}
# Worker mode, Symfony >= 7.4 runtime detects it natively
ENV FRANKENPHP_CONFIG="worker /app/public/index.php"

WORKDIR /app
# Numeric, so Kubernetes runAsNonRoot can check it
USER ${UID}:${GID}

EXPOSE 3000

# Warms the cache and runs migrations, then execs the CMD (absolute paths: no PATH lookup)
ENTRYPOINT ["/usr/local/bin/frankenphp", "php-cli", "/app/bin/console", "app:entrypoint", "--no-interaction", "--"]
CMD ["/usr/local/bin/frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
