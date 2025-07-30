#!/usr/bin/env bash

# Back up existing UEFI secure boot databases, including PK, KEK and db.
# Mainly useful for obtaining the OEM's KEK and db certificates.
# This script will write its output to the 'dumped' folder.

# Exit on error.
set -e

# Do not run if there is an existing 'dumped' directory.
if test -e dumped; then
  echo "Remove the existing 'dumped' directory before running this script." >&2
  exit 1
fi

# Require OpenSSL and efitools to be installed.
if ! command -v openssl &>/dev/null; then
  echo "This script requires the openssl command-line utility." >&2
  exit 1
fi
if ! command -v efi-readvar &>/dev/null || ! command -v sig-list-to-certs &>/dev/null; then
  echo "This script requires the utilities from the 'efitools' package." >&2
  exit 1
fi

# Do the same process for each database.
for v in KEK db; do
  # Create output directories.
  mkdir -p dumped/"$v"{,/der,/crt}
  # Dump the variable as an EFI signature list file.
  efi-readvar -v "$v" -o dumped/"$v"/"$v".esl
  # Extract DER certificates from the EFI signature list.
  sig-list-to-certs dumped/"$v"/{"$v".esl,der/"$v"}
  # Convert DER certificates to PEM format (.crt).
  while read -r d; do
    openssl x509 -inform der -in dumped/"$v"/der/"$d".der -out dumped/"$v"/crt/"$d".crt
  done < <(find dumped/"$v"/der -type f -name \*.der -exec basename {} ';' | sed 's/.der$//')
done
