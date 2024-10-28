# Init Git
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

# Install Symfony project in new empty directory
symfony new my-project --version="7.1.*" --webapp

# Move all files from my-project to root directory
rsync -a my-project/ ./ \
    --exclude='.git' \
    --exclude='compose.yaml' \
    --exclude='compose.override.yaml'
rm -rf my-project
