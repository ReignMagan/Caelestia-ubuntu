#!/usr/bin/env bash
set -euo pipefail
if (( EUID == 0 )); then echo 'Build as your normal user, not with sudo.' >&2; exit 1; fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../.." && pwd)
base="$HOME/.local/share/caelestia-ubuntu"
prefix="$base/runtime"
sources="$base/sources"
jobs=${CAELESTIA_BUILD_JOBS:-2}
mkdir -p "$sources" "$prefix" "$base/bin"
export CMAKE_PREFIX_PATH="$prefix${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fetch() {
 local name=$1 url=$2 revision=$3 path="$sources/$1"
 if [[ ! -d "$path/.git" ]]; then git clone --depth 1 "$url" "$path"; fi
 if [[ $(git -C "$path" rev-parse HEAD) != "$revision" ]]; then
  git -C "$path" fetch --depth 1 origin "$revision"
  git -C "$path" checkout --detach "$revision"
 fi
}
fetch quickshell https://git.outfoxxed.me/quickshell/quickshell.git 11ca60be22b063478ed9586ca1d7f92f0f261caf
fetch m3shapes https://github.com/soramanew/m3shapes.git 32ad9ce328bb77ed349b40a3be10ee9ea610b8ab
fetch cava https://github.com/LukashonakV/cava.git f03278ef9e5e7948fb206453d2f02758f8db216c
fetch cli https://github.com/caelestia-dots/cli.git ffaf093d5a486506709b881e0a057cd51c7babb6
(
 cd "$sources/cava"
 ./autogen.sh
 ./configure --prefix="$prefix" --libdir="$prefix/lib"
 make -j"$jobs"
 make install
)
cmake -S "$sources/quickshell" -B "$base/build/quickshell" -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" \
 -DCMAKE_INSTALL_LIBDIR=lib -DINSTALL_QML_PREFIX=lib/qt6/qml \
 -DX11=OFF -DI3=OFF -DCRASH_HANDLER=OFF
cmake --build "$base/build/quickshell" --parallel "$jobs"
cmake --install "$base/build/quickshell"
ln -sfn quickshell "$prefix/bin/qs"
cmake -S "$sources/m3shapes" -B "$base/build/m3shapes" -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" \
 -DCMAKE_INSTALL_LIBDIR=lib -DINSTALL_QMLDIR=lib/qt6/qml
cmake --build "$base/build/m3shapes" --parallel "$jobs"
cmake --install "$base/build/m3shapes"
cmake -S "$repo" -B "$base/build/shell" -G Ninja \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" \
 -DVERSION=1.0.0 -DGIT_REVISION="$(git -C "$repo" rev-parse HEAD)" \
 -DDISTRIBUTOR=Ubuntu -DCMAKE_INSTALL_LIBDIR=lib \
 -DINSTALL_QMLDIR=lib/qt6/qml -DINSTALL_LIBDIR=lib/caelestia \
 -DINSTALL_QSCONFDIR="$HOME/.config/caelestia-ubuntu/quickshell/caelestia"
cmake --build "$base/build/shell" --parallel "$jobs"
cmake --install "$base/build/shell"
python3 -m venv "$base/venv"
# Isolated Python environment; no sudo pip or system Python changes.
PIP_CACHE_DIR="$base/cache/pip" "$base/venv/bin/pip" install "$sources/cli"
bash "$here/install-user.sh"
echo 'Built the independent Caelestia runtime. Run the validation before registering its login session.'
