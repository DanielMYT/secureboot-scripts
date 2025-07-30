#!/usr/bin/env bash

# Generates the new secure boot databases suitable for importing into firmware.
# Does this by combining certs and signing as necessary.
# This script will write its output to the 'final' folder.

# Exit on error.
set -e

# Do not run if there is an existing 'final' or 'finalwork' directory.
if test -e final; then
  echo "Remove the existing 'final' directory before running this." >&2
  exit 1
fi

if test -e finalwork; then
  echo "Remove the existing 'finalwork' directory before running this." >&2
  exit 1
fi

# Do not run if mykeys do not exist.
if test ! -e mykeys/private/PK.key || test ! -e mykeys/private/KEK.key || test ! -e mykeys/private/db.key || test ! -e mykeys/public/PK.crt || test ! -e mykeys/public/KEK.crt || test ! -e mykeys/public/db.crt; then
  echo "Your PK, KEK and db keys/certs must be in the 'mykeys' directory." >&2
  echo "Run 'generate-keys.sh' if you need to generate them." >&2
  echo "If you already have keys, see README.md for the directory layout." >&2
  exit 1
fi

# Require efitools to be installed.
if ! command -v cert-to-efi-sig-list &>/dev/null || ! command -v sign-efi-sig-list &>/dev/null; then
  echo "This script requires the utilities from the 'efitools' package." >&2
  exit 1
fi

# Set up array to list additional certs that should be included.
extrakeks=()
extradbs=()

# Only include additional certs if the directory exists.
if test -d extracerts/kek; then
  while read -r line; do
    echo "NOTE: Including extra KEK certificate '${line/extracerts\/kek\//}'."
    extrakeks+=("$line")
  done < <(find extracerts/kek -type f -name \*.crt | sort -u)
fi
if test -d extracerts/db; then
  while read -r line; do
    echo "NOTE: Including extra db certificate '${line/extracerts\/db\//}'."
    extradbs+=("$line")
  done < <(find extracerts/db -type f -name \*.crt | sort -u)
fi

# Show a notice if no additional KEK or db certificates are used.
if test -z "${extrakeks[0]}"; then
  echo "WARNING: Not including any additional KEK certificates." >&2
fi
if test -z "${extradbs[0]}"; then
  echo "WARNING: Not including any additional db certificates." >&2
fi

# Create directories we need.
mkdir -p finalwork/{esl/{split/{KEK,db},combined},auth}

# Create combined ESL for PK (as there is only one PK certificate).
cert-to-efi-sig-list -g "$(uuidgen)" mykeys/public/PK.crt finalwork/esl/combined/PK.esl

# Create split ESLs for each KEK and DB.
cert-to-efi-sig-list -g "$(uuidgen)" mykeys/public/KEK.crt finalwork/esl/split/KEK/0000_KEK.esl
for c in "${extrakeks[@]}"; do
  o="$(echo "$c" | sed -e 's|^extracerts/kek/||' -e 's|.crt$||' -e 's|/|_|g')"
  cert-to-efi-sig-list -g "$(uuidgen)" "$c" finalwork/esl/split/KEK/"$o".esl
done
cert-to-efi-sig-list -g "$(uuidgen)" mykeys/public/db.crt finalwork/esl/split/db/0000_db.esl
for c in "${extradbs[@]}"; do
  o="$(echo "$c" | sed -e 's|^extracerts/db/||' -e 's|.crt$||' -e 's|/|_|g')"
  cert-to-efi-sig-list -g "$(uuidgen)" "$c" finalwork/esl/split/db/"$o".esl
done

# Merge ESLs.
cat finalwork/esl/split/KEK/*.esl > finalwork/esl/combined/KEK.esl
cat finalwork/esl/split/db/*.esl > finalwork/esl/combined/db.esl

# PK is signed by itself, KEK is signed by PK, db is signed by KEK.
sign-efi-sig-list -k mykeys/private/PK.key -c mykeys/public/PK.crt PK finalwork/{esl/combined/PK.esl,auth/PK.auth}
sign-efi-sig-list -k mykeys/private/PK.key -c mykeys/public/PK.crt KEK finalwork/{esl/combined/KEK.esl,auth/KEK.auth}
sign-efi-sig-list -k mykeys/private/KEK.key -c mykeys/public/KEK.crt db finalwork/{esl/combined/db.esl,auth/db.auth}

# Move final produced assets into 'final' directory.
mkdir -p final
cp finalwork/auth/* final/

# Clean up finalwork directory.
rm -rf finalwork

echo "The new final secure boot databases were placed in 'final/'."
echo "You can now run 'import-to-firmware.sh' to proceed."
echo "However you must be booted in setup mode - see README.md for info."
