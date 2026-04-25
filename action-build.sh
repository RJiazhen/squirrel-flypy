#!/usr/bin/env bash

set -e

target="${1:-release}"

# export BUILD_UNIVERSAL=1

# preinstall
./action-install.sh

# build dependencies
# make deps

# In release CI, the workflow passes `archive` here. That target builds Squirrel
# Flypy, signs Sparkle update metadata, and leaves release artifacts in `package/`
# for the GitHub Release upload step.
make "${target}"

echo 'Installer package:'
find package -type f -name '*.pkg' -or -name '*.zip'
