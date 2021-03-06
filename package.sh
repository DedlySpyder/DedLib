#!/usr/bin/env bash
set -e

# https://stedolan.github.io/jq/
mod_name=$(jq -r '.name' info.json)
mod_version=$(jq -r '.version' info.json)
mod_name_and_version="${mod_name}_${mod_version}"
mod_dir="$(basename "$(readlink -f "$(dirname "$0")")")"

# Create git tag for this version
git tag "$mod_version"

# Create zip with exclusions
cd ..
zip -r "${mod_name_and_version}.zip" "${mod_dir}" -x '*/*.git*' '*/package.sh' '*/docs/*' '*/*.iml'
cd -
