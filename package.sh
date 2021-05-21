#!/usr/bin/env bash
set -e

# https://stedolan.github.io/jq/
mod_name=$(jq -r '.name' info.json)
mod_version=$(jq -r '.version' info.json)

# Create git tag for this version
git tag "$mod_version"

# Create zip with exclusions
zip -r "${mod_name}_${mod_version}.zip" . -x '*.git*' 'tests/*' 'package.sh' 'docs/*'
