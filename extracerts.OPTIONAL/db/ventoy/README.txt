NOTE: This README file is ignored by create-databases.sh as it does not contain
the .crt or .crt.guid file extension.

The Ventoy certificate can optionally be added to your Authorized Signature
database, which allows you to bypass the normal process of importing into
MokList using the Ventoy instructions when you want to run Ventoy under secure
boot. But this is optional and not required for Ventoy functionality. It is
just a convenience method.

Remember to enable secure boot support via the toggle in the Ventoy program,
when you are installing Ventoy to a USB flash drive.

The GUID was determined based on the serial number of the key. The upstream
Ventoy certificate is distributed in the DER format with no defined GUID, so do
NOT treat the GUID found in this repository as in any way official to the
Ventoy project. As mentioned in 'extracerts/README.md', the UEFI firmware does
not care about what GUID any particular certificate uses. Use of them is purely
a convention. The original DER certificate (which has been converted into the
PEM format as required by the scripts in this repository) comes from the
following location:

  https://github.com/ventoy/Ventoy/blob/v1.1.10/INSTALL/tool/ENROLL_THIS_KEY_IN_MOKMANAGER.cer
