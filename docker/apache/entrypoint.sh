#!/bin/bash -xe

OWNER_UID="$(stat -c %u ${WWW_ROOT})"
OWNER_GID="$(stat -c %g ${WWW_ROOT})"
if [[ "$OWNER_UID" != "0" ]]; then
    usermod -o --uid ${OWNER_UID} www-data
fi
if [[ "$OWNER_GID" != "0" ]]; then
    groupmod -o --gid ${OWNER_GID} www-data
fi

apache2-foreground
