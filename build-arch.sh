#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
# @created     : Friday Nov 24, 2023 19:06:13 -03
#
# @description : 
######################################################################

set -e

function msg()
{
  echo "${FUNCNAME[1]}" "$@"
}

function fetch_ryujinx()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Fetch latest release
  read -r url_ryujinx < <(wget -qO - "https://api.github.com/repos/Ryujinx/release-channel-master/releases" \
    | jq -r '.[].assets.[].browser_download_url | match(".*/ryujinx.*linux_x64.tar.gz$").string' \
    | sort -V \
    | tail -n1)
  wget "$url_ryujinx"

  # Extract files
  mkdir -p ryujinx/bin
  tar xf ryujinx-*linux_x64.tar.gz --strip-components=1 -C ryujinx/bin

  # Remove tarball
  rm ryujinx*.tar.gz
}

function fetch_flatimage()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Fetch container
  if ! [ -f "$BUILD_DIR/arch.tar.xz" ]; then
    wget "$(wget -qO - "https://api.github.com/repos/ruanformigoni/flatimage/releases/latest" \
      | jq -r '.assets.[].browser_download_url | match(".*arch.tar.xz$").string')"
  fi

  # Extract container
  rm -f "$IMAGE"

  tar xf arch.tar.xz

  # FIM_COMPRESSION_LEVEL
  export FIM_COMPRESSION_LEVEL=6

  # Resize
  "$IMAGE" fim-resize 3G

  # Update
  "$IMAGE" fim-root fakechroot pacman -Syu --noconfirm

  # Install dependencies
  "$IMAGE" fim-root fakechroot pacman -S libxkbcommon libxkbcommon-x11 \
    lib32-libxkbcommon lib32-libxkbcommon-x11 libsm lib32-libsm fontconfig \
    lib32-fontconfig noto-fonts --noconfirm

  # Install video packages
  "$IMAGE" fim-root fakechroot pacman -S xorg-server mesa lib32-mesa \
    glxinfo pcre xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon \
    xf86-video-intel vulkan-intel lib32-vulkan-intel vulkan-tools --noconfirm

  # Gameimage dependencies
  "$IMAGE" fim-root fakechroot pacman -S libappindicator-gtk3 \
    lib32-libappindicator-gtk3 --noconfirm

  # Compress self
  "$IMAGE" fim-compress
}


function compress_ryujinx()
{
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  # Copy ryujinx runner
  cp "$SCRIPT_DIR"/boot.sh "$BUILD_DIR"/ryujinx/boot

  # Compress ryujinx
  "$IMAGE" fim-exec mkdwarfs -i "$BUILD_DIR"/ryujinx -o "$BUILD_DIR/ryujinx.dwarfs"
}

function hooks_add()
{
  msg "${IMAGE:?IMAGE is undefined}"
  msg "${SCRIPT_DIR:?SCRIPT_DIR is undefined}"

  "$IMAGE" fim-hook-add-pre "$SCRIPT_DIR"/hook-ryujinx.sh
}

function configure_flatimage()
{
  msg "${IMAGE:?IMAGE is undefined}"

  # Set default command
  # shellcheck disable=2016
  "$IMAGE" fim-cmd '"$FIM_BINARY_RYUJINX"'

  # Set perms
  "$IMAGE" fim-perms-set wayland,x11,pulseaudio,gpu,session_bus,input,usb

  # Set up /usr overlay
  #shellcheck disable=2016
  "$IMAGE" fim-dwarfs-overlayfs usr '"${FIM_DIR_BINARY}"/."${FIM_BASENAME_BINARY}".config/overlays/usr'

  # Set up ryujinx overlay
  #shellcheck disable=2016
  "$IMAGE" fim-config-set dwarfs.overlay.ryujinx '"${FIM_DIR_BINARY}"/."${FIM_BASENAME_BINARY}".config/overlays/ryujinx'

  # Set up HOME
  #shellcheck disable=2016
  "$IMAGE" fim-config-set home '"${FIM_DIR_BINARY}"'
}

function package()
{
  msg "${SCRIPT_DIR:?SCRIPT_DIR is undefined}"
  msg "${BUILD_DIR:?BUILD_DIR is undefined}"

  local dir_dist="$SCRIPT_DIR"/dist

  mkdir -p "$dir_dist" && cd "$dir_dist"

  # Move binaries to dist dir
  mv "$BUILD_DIR"/arch.flatimage ryujinx.flatimage
  mv "$BUILD_DIR"/ryujinx.dwarfs .

  # Compress
  tar -cf ryujinx.tar ryujinx.flatimage
  xz -3zv ryujinx.tar

  # Create sha256sum
  sha256sum ryujinx.flatimage > ryujinx.flatimage.sha256sum
  sha256sum ryujinx.tar.xz > ryujinx.tar.xz.sha256sum
  sha256sum ryujinx.dwarfs > ryujinx.dwarfs.sha256sum

  # Only distribute tarball
  rm ryujinx.flatimage
}

function main()
{
  # shellcheck disable=2155
  export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  export BUILD_DIR="$SCRIPT_DIR/build"

  # Re-create build dir
  rm -rf "$BUILD_DIR"; mkdir "$BUILD_DIR"; cd "$BUILD_DIR"

  # Container file path
  export IMAGE="$BUILD_DIR/arch.flatimage"

  fetch_ryujinx
  fetch_flatimage
  compress_ryujinx
  hooks_add
  configure_flatimage
  package
}

main "$@"

# // cmd: !./%

#  vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
