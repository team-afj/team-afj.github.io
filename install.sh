# Macos shenanigans
if [ "$(uname)" == "Darwin" ]; then
  export PATH="$(brew --prefix)/opt/php/bin:${PATH}"
fi

GRAV_VERSION=1.7.10

# Install GRAV
composer create-project getgrav/grav webroot/grav $GRAV_VERSION
