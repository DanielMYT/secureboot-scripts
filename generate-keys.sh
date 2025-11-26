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
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout mykeys/private/db.key -out mykeys/public/db.crt -days 3650 -nodes -subj "/CN=$dbname/" -addext "extendedKeyUsage=codeSigning"

# Generate owner GUID.
$_uuidgen > mykeys/owner.guid

# Finishing message.
echo "Your newly generated keys and certificates were placed in 'mykeys/'."
echo "The owner GUID for your set is '$(cat mykeys/owner.guid)'."
echo "You can now run 'create-databases.sh' to proceed."
