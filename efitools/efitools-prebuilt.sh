#!/usr/bin/env bash

# Extracts prebuilt and standalone binaries of efitools.
# For distributions which do not provide efitools themselves.
# Limitation is that this is currently only supported on x86_64.

# Exit on error.
set -e

# Where are we? We want to download alongside the script.
here="$(readlink -f "$(dirname "$0")")"

# Require x86_64 system.
if test "$(uname -m)" != "x86_64"; then
  echo "Sorry! Prebuilt efitools currently only supports x86_64 systems." >&2
  echo "Please install the 'efitools' package from your distribution." >&2
  exit 1
fi

# Starting message.
echo -e "\e[1;33mSetting up prebuilt efitools binary package...\e[0m"

# Remove existing extracted directory.
rm -rf "$here"/extracted

# Set up the working directory to use.
mkdir -p "$here"/extracted

# Concatenate all parts of the package and decode from base64.
cat "$here"/distrib/xa[a-x] | base64 -d > "$here"/extracted/package.tar.xz

# Verify checksum of restored package.
echo "369f0b30d4f3ae00ae8d3b63c88f49b66caa38cbf0a5a9f908104f963feac8fb $here/extracted/package.tar.xz" | sha256sum -c

# Extract package.
tar -xf "$here"/extracted/package.tar.xz -C "$here"/extracted --strip-components=1

# Finishing message.
echo -e "\e[1;33mSuccessfully set up prebuilt efitools binaries at:\e[0m"
echo -e "\e[1;32m$here/extracted/bin\e[0m"
echo -e "\e[1;33mScripts in this repository will find it automatically.\e[0m"
echo -e "\e[1;33mYou can, however, still add to PATH if desired.\e[0m"
