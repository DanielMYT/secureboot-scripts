NOTE: This README file is ignored by create-databases.sh as it does not contain
the .crt or .crt.guid file extension.

Adding the MassOS secure boot certificates to your Authorized Signatures list
should no longer be needed, as newer builds of MassOS use a Microsoft-signed
shim, and support the MassOS certificate being enrolled in shim's MokList,
rather than into the UEFI firmware itself. However they are still provided here
in case you still want to add them to your Authorized Signatures list. This can
bypass the need (at runtime) for manually importing the MassOS certificate via
MokManager.

The 2025 certificates are only needed if you want to boot an outdated build
from 2025 or earlier. All new builds starting from 2026 and onwards are or will
be signed with the newer 2026 certificate. If you don't need to boot a 2025
build, then we recommend NOT adding the 2025 certificate, and ONLY adding the
2026 certificate.

For more information, please visit the following documentation page:

  https://github.com/MassOS-Linux/MassOS/wiki/UEFI-Secure-Boot
