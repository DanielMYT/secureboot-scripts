#!/usr/bin/env bash

# Back up existing UEFI secure boot databases (KEK and db).
# Mainly useful for obtaining the OEM's KEK and db certificates.
# This script will write its output to the 'dumped/' directory.
# Non-Microsoft OEM certificates will be placed in 'dumped/oem-crt/'.

# Exit on error.
set -e

# Expand PATH to contain efitools prebuilts.
export PATH="$PATH:$(readlink -f "$(dirname "$0")")/efitools/extracted/bin"

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
  echo "You can run the following command to setup prebuilt efitools:" >&2
  echo >&2
  echo "        ./efitools/efitools-prebuilt.sh" >&2
  echo >&2
  echo "Then re-run $(basename "$0"). It will auto-find the prebuilts." >&2
  exit 1
fi

# Determine how we can best generate UUIDs.
if uuidgen &>/dev/null; then
  # uuidgen utility from util-linux.
  _uuidgen="uuidgen"
elif cat /proc/sys/kernel/random/uuid &>/dev/null; then
  # Inbuilt kernel generator (requires /proc to be mounted).
  _uuidgen="cat /proc/sys/kernel/random/uuid"
elif python3 -m uuid; then
  # The uuid module from Python 3.
  _uuidgen="python3 -m uuid"
else
  # No suitable UUID generator found.
  echo "No suitable UUID generation method was found." >&2
  echo "Please install uuidgen, OR mount /proc, OR install Python 3." >&2
  exit 1
fi
echo "NOTE: UUIDs will be generated using '$_uuidgen'."

# Which directories to include containing non-OEM certificates.
# This is for the OEM-certificate-isolating step below.
nocdirs=()
for n in mykeys/public extracerts.DEFAULT extracerts.OPTIONAL; do
  if test -d "$n"; then
    nocdirs+=("$n")
  fi
done

# Dump KEK and db (PK is not useful).
for v in KEK db; do
  vl="$(echo "$v" | tr '[:upper:]' '[:lower:]')"
  # Create output directories.
  mkdir -p dumped/ALL/"$v"{,/der,/crt}
  mkdir -p dumped/oem-crt/"$vl"
  # Dump the variable as an EFI signature list file.
  efi-readvar -v "$v" -o dumped/ALL/"$v"/"$v".esl
  # Extract DER certificates from the EFI signature list.
  sig-list-to-certs dumped/ALL/"$v"/{"$v".esl,der/"$v"}
  # Convert DER certificates to PEM format (.crt).
  while read -r d; do
    openssl x509 -inform der -in dumped/ALL/"$v"/der/"$d".der -out dumped/ALL/"$v"/crt/"$d".crt
  done < <(find dumped/ALL/"$v"/der -type f -name \*.der -exec basename {} ';' | sed 's/.der$//')
  # Pick out only the OEM certificates (non-Microsoft) from all dumped.
  if test ! -z "${nocdirs[0]}"; then
    oemname=0
    while read -r c; do
      matched=0
      while read -r n; do
        # Check if the certificate matches by getting fingerprint.
        if test "$(openssl x509 -in "$c" -noout -fingerprint)" = "$(openssl x509 -in "$n" -noout -fingerprint)"; then
          # It matches a non-OEM certificate, so it's not an OEM certificate.
          matched=1
          break
        fi
      done < <(find "${nocdirs[@]}" -type f -name \*.crt)
      if test "$matched" = "0"; then
        # Doesn't match any non-OEM certificates. So it's an OEM certificate.
        echo "NOTE: Found OEM cert: '$(openssl x509 -in "$c" -noout -subject | sed 's/^subject=//')'."
        cp "$c" dumped/oem-crt/"$vl"/oem-"$vl"-"$oemname".crt
        oemname=$((oemname + 1))
      fi
    done < <(find dumped/ALL/"$v"/crt -name \*.crt)
  fi
done

# Generate one "OEM" GUID for all OEM certificates.
# This is a best effort since we can't get original GUID from firmware.
oemguid="$($_uuidgen)"
echo "NOTE: Using randomly-generated GUID ($oemguid) for OEM certs."
while read -r o; do
  echo "$oemguid" > "$o".guid
done < <(find dumped/oem-crt -type f -name \*.crt)

# Finishing message.
echo
echo "Successfully dumped KEK and db certificates from firmware."
echo "All dumped certificates were placed in 'dumped/ALL/{db,KEK}/crt/'."
echo "OEM certificates (e.g. non-Microsoft) are at 'dumped/oem-crt/{db,kek}/'."
echo
echo "You ONLY need OEM certificates in your extracerts database."
echo "To copy them over, run the following command:"
echo
echo "        cp -rv dumped/oem-crt/{db,kek} extracerts/"
