#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mapfile -t packages < "$here/dependencies.txt"
if (( EUID == 0 )); then
 apt-get -y --no-install-recommends --no-upgrade --no-remove install "${packages[@]}"
else
 sudo apt-get -y --no-install-recommends --no-upgrade --no-remove install "${packages[@]}"
fi
