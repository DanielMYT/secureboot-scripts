# secureboot-scripts
Some scripts to simplify the process of taking control of UEFI secure boot.

# IMPORTANT NOTICE
Most of the scripts in this repository were originally written for the author's
own convenience, and were only designed to be used internally. They have now
been published in this repository, under the permissive MIT license, to allow
others to be able to use the scripts and benefit from them. Documentation on
how they work and how to use them (part of which you are currently reading) has
been written. Stability and functionality are not guaranteed. Use them at your
own risk, and make sure you understand what the scripts are actually doing
under the hood. The author assumes no resonsibility for any negative
consequences which may occur as a result of you (mis)using these scripts.

# Terminology
You should be aware that the term **"Key"** traditionally refers to the private
signing key which is used to sign binaries and signature lists, while the term
**"Certificate"** refers to the public certificate which is used to validate
that the signature(s), produced by the process of signing with the private key,
are correct and authentic.

# Overview
The UEFI secure boot environment has four main databases:

- **Platform Key (PK)** - The "master" certificate which controls the entire
  secure boot environment. By default, it will be the OEM's certificate. With
  the scripts in this repository, it will be your own personal certificate. The
  PK is signed by its own key. The PK of the system can only be replaced and/or
  installed when the machine is booted in "Setup Mode". On GNU/Linux systems,
  you can run the command `bootctl status` to verify whether the machine is in
  Setup Mode or User Mode (default/normal mode).
- **Key Exchange Keys (KEK)** - The database of certificates which control what
  can be added to, removed from, or modified in, the Authorized Signatures (db)
  and Forbidden Signatures (dbx) databases. Unlike the PK, the KEK can contain
  multiple certificates, any of which can be used to sign (and hence authorize)
  updates/modifications to the db and dbx. By default, the KEK will contain
  both the OEM's certificate and Microsoft's certificate. With the scripts in
  this repository, it will contain your own KEK certificate, and you will make
  the decision of whether or not Microsoft's certificate (plus any other custom
  certificates you may wish to add) shall also be included in the KEK. All KEK
  entries are signed by the PK's key.
- **Authorized Signatures (db)** - The database of certificates which control
  whether or not a signed EFI executable (e.g., bootloader or operating system)
  is allowed to start up on the machine. The certificates in this database can
  also be referred to as "UEFI Signing Certificates", amongst other names. This
  is because their corresponding keys are used for the purpose of signing real
  EFI binaries that may be booted on the system. By default, the db will hold
  all of Microsoft's various signing certificates, as well as the OEM's own
  certificate. With the scripts in this repository, it will contain your own
  signing certificate, and (if desired) Microsoft's certificates, as well as
  any other signing certificates you wish to trust by default. All db entries
  are signed by one of the KEK keys, and any updates/modifications to the db
  must also be signed by such. Which means that, if Microsoft's key is in the
  KEK, then Microsoft can also supply db updates themselves (not just you),
  which may or may not be desirable, depending upon your own personal
  preferences. Ultimately, however, it is your decision to make.
- **Forbidden Signatures (dbx)** - The database of certificates and/or binary
  hashes which are known to be untrusted, vulnerable, or even outright malware.
  Anything in the dbx overrides db, so even if a certificate is in the db, EFI
  binaries signed by its key will be unable to load if that certificate is also
  in the dbx, or if the hash of the EFI binary itself is in the dbx. By
  default, the list of signatures/hashes that Microsoft considers "bad" are
  frequently updated, through Windows Update, or through LVFS (fwupd) on Linux.
  For this reason, whether or not you can really utilise dbx depends on whether
  or not Microsoft's certificate is in your KEK (in which case, as previously
  mentioned, they can supply dbx updates). If this is not the case, then only
  you can manage/update the dbx, which again may or may not be desirable,
  depending upon your personal preferences. On the one hand, Microsoft can do
  the work of keeping your system safe of malware themselves, but on the other
  hand, it may be considered by some individuals to be a "backdoor", as
  Microsoft can at their own discretion update the databases of what is/isn't
  trusted to load on your machine.

# The process of taking control of secure boot

## Generate your own keys
The first step is to generate your own keys for PK, KEK and db. This forms the
foundation of your control over the secure boot environment. If you don't
already have keys for each, you can use the following command:
```sh
./generate-keys.sh
```
You will receive three prompts, to enter your desired CN for each key. You can
name them whatever you want, but we'd recommend using a sensible name that is
both easy to identify, and consistent between your three different keys. For
example, here are the following which could be used (but again, you may use
whichever name you want):

- **PK**: "John Smith Platform Key"
- **KEK**: "John Smith Key Exchange Key"
- **db**: "John Smith UEFI Signing Key"

Once the generation is complete, the keys and their corresponding certificates
will be placed under the `mykeys/` directory. The private keys will be under
`mykeys/private/`, and the public certificates will be under `mykeys/public/`.
You can freely share the public certificates to anyone, but **DO NOT** share
the private keys! They are private for a reason.

## Add extra third-party certificates
Before generating the new secure boot databases, you will most likely want to
add additional certificates into the db and, optionally, the KEK. These can
include the Microsoft certificates (for booting Windows and Microsoft-signed
GNU/Linux distributions), the device OEM's certificate(s), and others. All
additional certificates are placed under the `extracerts/` directory. More
specifically, `extracerts/kek/` for additional KEK certificates, and
`extracerts/db/` for additional db certificates. By default, there are none
under this directory, but there is a default directory in the top-level of this
repository, named `extracerts.DEFAULT`, which contains some common certificates
you may wish to use directly. You can copy these over to the `extracerts/`
directory by running the following command:
```sh
cp -r extracerts.DEFAULT/{db,kek} extracerts/
```
Full descriptions about each of these default certificates, as well as detailed
information on how to customize them and add your own, such as device OEM
certificates, can be found in [extracerts/README.md](extracerts/README.md). We
recommend reading through this before continuing on further, since it also
displays an annotated example image showing a finalized `extracerts` directory
that is ready for moving on to the next step.

## Generate the new secure boot databases
With your own keys generated, and any desired third-party certificates added,
you can generate the complete secure boot databases by running the following
command:
```sh
./create-databases.sh
```
A message will be displayed on the command-line for every certificate that has
been added after being found under the `extracerts/` directory. You should
check this output to verify that it matches the certificates you have placed
under this directory. Once the script finishes, the final database files will
be placed inside the `final/` directory, each with the `.auth` extension. These
will all be signed as appropriate:

- The PK will be signed by itself.
- The KEK will be signed by the PK.
- The db will be signed by the KEK.

## Import the new secure boot databases
The final step is to import the new secure boot databases into your firmware.
This will replace the factory secure boot databases, and will conclude the
process of taking control of the secure boot environment. You can do this with
the following command:
```sh
sudo ./import-to-firmware.sh
```
HOWEVER, it is very likely this command will fail at the PK import stage. This
is because, in order to install a new Platform Key, the existing Platform Key
must be erased. The process of doing this involves entering "Setup Mode", which
clears the PK (and ideally all other secure boot variables too), thus allowing
you to replace the PK with your own, and replace the KEK and db too, as the
`import-to-firmware.sh` script tries to do. In order to enter setup mode, you
need to restart into your UEFI firmware settings. This can be done by pressing
a specific hotkey during system startup, or can alternatively be done with the
following command:
```sh
systemctl reboot --firmware-setup
```
Once you are in the firmware setup, you need to find where the secure boot
option is located - it is often under the "Security" tab. "Secure Boot" may or
may not also be a submenu of the firmware settings you can descend into. But in
or around it, there should be an option to "Reset to Setup Mode", which does
exactly what it suggests. Once you select this option and restart back into the
main system, you can use the command `bootctl status` to verify whether or not
you are in setup mode:
```sh
bootctl status
```
It will give one of the following outputs on the "Secure Boot:"" line:
```sh
Secure Boot: enabled (user) # Secure boot is enabled - PK is locked.
Secure Boot: disabled # Secure boot is disabled - PK is still locked.
Secure Boot: disabled (setup) # Setup mode - PK is cleared and replaceable.
```
Clearly, you want the line which reads `disabled (setup)`. If this is the case,
you are good to proceed! Try to run the previously mentioned command again:
```sh
sudo ./import-to-firmware.sh
```
And now, it should work. The secure boot variables in your firmware should now
contain your newly created databases consisting of only your certificates and
the specific certificates you want your system to include. However, secure boot
may not become enabled by default after this process. So you should restart
into your firmware settings again, and enable secure boot if it is not already
enabled. After doing so, you should be good to go. You can run the following
commands to inspect the contents of each variable, and check it contains the
entries you expect:
```sh
# Platform Key (PK).
efi-readvar -v PK
# Key Exchange Keys (KEK).
efi-readvar -v KEK
# Authorized Signatures (db).
efi-readvar -v db
```

# Licensing
The scripts are Copyright (C) Daniel Massey and MIT licensed. See the LICENSE
file for the license text.
