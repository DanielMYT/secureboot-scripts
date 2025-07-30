#!/usr/bin/env bash

# Generates the keys and certificates for PK, KEK and db.
# This script will write its output to the 'mykeys' folder.

# Exit on error.
set -e

# Do not run if there is an existing 'mykeys' directory.
if test -e mykeys; then
  echo "Remove the existing 'mykeys' directory before running this script." >&2
  exit 1
fi

# Require OpenSSL to be installed.
if ! command -v openssl &>/dev/null; then
  echo "This script requires the openssl command-line utility." >&2
  exit 1
fi

# Ask for name of PK, KEK and DB keys to be entered by the user.
while true; do
  read -rp "Enter the common name (CN) for Platform Key (PK): " pkname
  if test ! -z "$pkname"; then
    break
  fi
done
while true; do
  read -rp "Enter the common name (CN) for Key Exchange Key (KEK): " kekname
  if test ! -z "$kekname"; then
    break
  fi
done
while true; do
  read -rp "Enter the common name (CN) for UEFI Signing Key (db): " dbname
  if test ! -z "$dbname"; then
    break
  fi
done

# Create directories.
mkdir -p mykeys/{private,public}

# Generate PK, KEK and db keys.
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout mykeys/private/PK.key -out mykeys/public/PK.crt -days 3650 -nodes -subj "/CN=$pkname/"
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout mykeys/private/KEK.key -out mykeys/public/KEK.crt -days 3650 -nodes -subj "/CN=$kekname/"
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout mykeys/private/db.key -out mykeys/public/db.crt -days 3650 -nodes -subj "/CN=$dbname/"

# Finishing message.
echo "Your newly generated keys and certificates were placed in 'mykeys/'."
echo "You can now run 'create-databases.sh' to proceed."
