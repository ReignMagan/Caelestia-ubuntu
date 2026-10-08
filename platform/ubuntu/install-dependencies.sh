#!/usr/bin/env bash
set -euo pipefail
source /etc/os-release
if [[ ${ID:-} != ubuntu || ${VERSION_ID:-} != 26.04 ]]; then
 echo 'This dependency installer supports Ubuntu 26.04 only. See README.md for the tested scope.' >&2
 exit 1
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mapfile -t packages < "$here/dependencies.txt"
if (( EUID == 0 )); then
 apt-get -y --no-install-recommends --no-upgrade --no-remove install "${packages[@]}"
else
 sudo apt-get -y --no-install-recommends --no-upgrade --no-remove install "${packages[@]}"
fi
