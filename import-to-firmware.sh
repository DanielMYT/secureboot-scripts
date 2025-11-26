#!/usr/bin/env bash

# Don't exit on error, since we can catch errors ourself to inform the user.
set +e

# Expand PATH to contain efitools prebuilts.
export PATH="$PATH:$(readlink -f "$(dirname "$0")")/efitools/extracted/bin"

# Ensure this script is run as root (required for efi-updatevar).
if test $EUID -ne 0; then
  echo "This script must be run as root (use 'sudo')." >&2
  exit 1
fi

# Do not proceed if there is no 'final' directory containing authorized ESLs.
if test ! -f final/PK.auth || test ! -f final/KEK.auth || test ! -f final/db.auth; then
  echo "There is nothing to import." >&2
  echo "Place 'PK.auth', 'KEK,auth' and 'db.auth' in 'final/' directory." >&2
  echo "Or run 'create-databases.sh', which does this for you." >&2
  exit 1
fi

# Require the efi-updatevar program from efitools to be installed.
if ! command -v efi-updatevar &>/dev/null; then
  echo "This script requires the utilities from the 'efitools' package." >&2
  echo "You can run the following command to setup prebuilt efitools:" >&2
  echo >&2
  echo "        ./efitools/efitools-prebuilt.sh" >&2
  echo >&2
  echo "Then re-run $(basename "$0"). It will auto-find the prebuilts." >&2
  exit 1
fi

# Try to import PK (this will fail if not in setup mode).
echo "Installing Platform Key (PK)..."
efi-updatevar -f final/PK.auth PK
if test $? -ne 0; then
  echo "ERROR: Failed to install Platform Key (PK)! Exiting..." >&2
  echo "Please ensure you are in setup mode! See 'README.md' for details." >&2
  exit 1
fi

# Try to import KEK.
echo "Installing Key Exchange Keys (KEK)..."
efi-updatevar -f final/KEK.auth KEK
if test $? -ne 0; then
  echo "ERROR: Failed to install Key Exchange Keys (KEK)! Exiting..." >&2
  exit 1
fi

# Try to import db.
echo "Installing Authorized Signatures (db)..."
efi-updatevar -f final/db.auth db
if test $? -ne 0; then
  echo "ERROR: Failed to install Authorized Signatures (db)! Exiting..." >&2
fi

echo "All done!"
echo "You should now reboot and check secure boot is enabled in UEFI settings."
echo "Some firmwares may not automatically re-enable it after new PK is added."
echo "Once enabled, you should be good to go. Good show!"
