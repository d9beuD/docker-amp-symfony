#!/bin/sh
set -eu

# Install Symfony project in new empty directory
echo "* Installing Symfony project in new empty directory"
case "${TYPE:-webapp}" in
  webapp) flag=--webapp ;;
  api)    flag=--api ;;
  *) echo "TYPE must be 'webapp' or 'api', got '${TYPE}'" >&2; exit 1 ;;
esac
symfony new my-project --version="${VERSION:-stable}" "$flag" --no-git

# Move all files from my-project to root directory
echo "* Moving files from my-project to root directory"
rsync -a my-project/ ./ \
    --exclude='compose.yaml' \
    --exclude='compose.override.yaml'

# Symfony's .gitignore replaced ours; keep its macOS entry
grep -qxF '.DS_Store' .gitignore || echo '.DS_Store' >> .gitignore

# Entrypoint of the prod image, which has no shell
mkdir -p src/Command
cp docker/symfony/EntrypointCommand.php src/Command/

echo "* Removing my-project directory"
rm -rf my-project

# Warm up cache
echo "* Warming up cache"
symfony console cache:clear

echo "Done."
