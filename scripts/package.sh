#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mod_dir="$repo_root/QualityFullMonty"
version=$(python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("QualityFullMonty/info.json").read_text())["version"])')
archive_name="QualityFullMonty_${version}.zip"

mkdir -p "$repo_root/dist"
rm -f "$repo_root/dist/$archive_name"

cd "$repo_root"
zip -qr "dist/$archive_name" QualityFullMonty

echo "dist/$archive_name"

