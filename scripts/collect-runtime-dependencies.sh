#!/usr/bin/env bash

set -euo pipefail

if (( $# != 1 )); then
  echo "usage: $0 <runtime-root>" >&2
  exit 64
fi

runtime_root="$(realpath "$1")"
runtime_lib="$runtime_root/usr/local/lib"
licenses_root="$runtime_root/usr/local/share/licenses/runtime-dependencies"
dependency_list="$(mktemp)"

test -d "$runtime_lib"
mkdir -p "$licenses_root"

# Libraries in this list are part of the host ABI or must match host hardware,
# display, audio, or driver stacks. This follows the AppImage community's
# excludelist, with the AArch64 loader added explicitly.
is_host_library() {
  case "$1" in
    ld-linux.so.2|ld-linux-x86-64.so.2|ld-linux-aarch64.so.1|\
    libanl.so.1|libBrokenLocale.so.1|libc.so.6|libdl.so.2|libm.so.6|libmvec.so.1|\
    libnss_compat.so.2|libnss_dns.so.2|libnss_files.so.2|libnss_hesiod.so.2|\
    libnss_nis.so.2|libnss_nisplus.so.2|libpthread.so.0|libresolv.so.2|librt.so.1|\
    libthread_db.so.1|libutil.so.1|libstdc++.so.6|libgcc_s.so.1|\
    libGL.so.1|libEGL.so.1|libGLdispatch.so.0|libGLX.so.0|libOpenGL.so.0|\
    libdrm.so.2|libglapi.so.0|libgbm.so.1|libxcb.so.1|libX11.so.6|\
    libX11-xcb.so.1|libwayland-client.so.0|libasound.so.2|libpipewire-0.3.so.0|\
    libfontconfig.so.1|libfreetype.so.6|libharfbuzz.so.0|libICE.so.6|libSM.so.6|\
    libusb-1.0.so.0|libuuid.so.1|libz.so.1|libgpg-error.so.0|libjack.so.0|\
    libxcb-dri2.so.0|libxcb-dri3.so.0|libfribidi.so.0|libgmp.so.10|\
    libcom_err.so.2|libexpat.so.1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

while IFS= read -r -d '' elf; do
  if file -b "$elf" | grep -q '^ELF '; then
    LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      lddtree -l "$elf" >> "$dependency_list"
  fi
done < <(find "$runtime_root" -type f -print0)

sort -u -o "$dependency_list" "$dependency_list"

while IFS= read -r dependency; do
  test -n "$dependency" || continue
  test -e "$dependency" || {
    echo "dependency did not resolve: $dependency" >&2
    exit 1
  }

  dependency_name="$(basename "$dependency")"
  if is_host_library "$dependency_name"; then
    printf 'Using host library: %s\n' "$dependency_name"
    continue
  fi

  if [[ "$dependency" == "$runtime_root"/* ]]; then
    continue
  fi

  destination="$runtime_lib/$dependency_name"
  cp --dereference --preserve=mode,timestamps "$dependency" "$destination"
  printf 'Bundled runtime dependency: %s\n' "$dependency_name"

  resolved_dependency="$(readlink -f "$dependency")"
  package="$(dpkg-query --search "$resolved_dependency" 2>/dev/null | head -n 1 | cut -d: -f1 || true)"
  if test -n "$package" && test -f "/usr/share/doc/$package/copyright"; then
    mkdir -p "$licenses_root/$package"
    cp "/usr/share/doc/$package/copyright" "$licenses_root/$package/copyright"
  fi
done < "$dependency_list"

# Every non-host dependency discovered from the original installed binaries
# must now be represented in the portable runtime directory.
while IFS= read -r dependency; do
  test -n "$dependency" || continue
  dependency_name="$(basename "$dependency")"
  is_host_library "$dependency_name" && continue
  test -e "$runtime_lib/$dependency_name" || find "$runtime_root" -name "$dependency_name" -print -quit | grep -q . || {
    echo "runtime dependency was not packaged: $dependency_name" >&2
    exit 1
  }
done < "$dependency_list"

printf 'Runtime dependency closure packaged successfully.\n'
