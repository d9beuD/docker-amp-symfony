#!/bin/sh
set -eu

# Install Symfony project in new empty directory
echo "* Installing Symfony project in new empty directory"
symfony new my-project --version="8.1.*" --webapp --no-git

# Move all files from my-project to root directory
echo "* Moving files from my-project to root directory"
rsync -a my-project/ ./ \
    --exclude='compose.yaml' \
    --exclude='compose.override.yaml'

echo "* Removing my-project directory"
rm -rf my-project

# Warm up cache
echo "* Warming up cache"
symfony console cache:clear

echo "Done."
