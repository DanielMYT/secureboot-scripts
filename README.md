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

# Get started
The following sections contain some recommended and/or interesting reading
about how secure boot works under the hood, and the purpose of these scripts'
existence. If you don't care about this and want to get straight on with the
process, scroll down to the **The process of taking control of secure boot**
section.

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

# Why take control of secure boot?
As shown in the **Overview** section above, you can clearly see that, in the
default state of secure boot, the only entities that have control over the
secure boot environment on the computer you are using are the device OEM and
Microsoft. This means only they can decide what is or isn't allowed to boot on
your system. As we have also established, this means you cannot "alter" the
certificate list that control what can or can't boot, because any updates to
**Authorized Signatures (db)** requires one of the **Key Exchange Keys (KEK)**
to sign (therefore "authorize") the update.

There is an exception on some systems, primarily ones which use **AMI Aptio V**
firmwares. Such firmwares are special, because they actually expose options for
direct key management within the firmware settings. This allows you to directly
update any of the variables, including **Authorized Signatures (db)**, without
those updates needing to be signed by the authority above the variable you are
updating. This means you don't need to take control of secure boot at all in
order to be able to modify the certificates that the system trusts (however you
may still want to, due to the obvious benefits of having control and freedom).
Although the interface is complicated and unintuitive to naviagate, there is an
[article](https://github.com/MassOS-Linux/MassOS/wiki/UEFI-Secure-Boot) in the
MassOS documentation which contains a section with detailed instructions of how
to import a custom certificate using this firmware interface. Although that
article is specifically centered around the MassOS secure boot certificate, you
could theoretically follow the same instructions to import any secure boot
certificate, or a group of certificates.

However, most other systems, particularly laptops, do not have such options in
the firmware settings. Therefore, the only way to import custom certificates is
to take control of the secure boot environment, such that your own certificates
are in **PK** and **KEK**, and therefore can sign any **db** updates you want.
This is where the scripts in this repository are invaluable, so we'd highly
recommend reading on.

As for why not just disable secure boot, well there are two main reasons. One
is a pragmatic reason - if you dual-boot your GNU/Linux system with Windows,
then some Windows-only features will be blocked without secure boot. These
include the **Windows Device Encryption** feature (which is an alternative to
BitLocker on Home editions of Windows which don't support BitLocker), as well
as several other security-related features. Furthermore, online multiplayer
video games often make use of aggressive anti-cheat engines, and these engines
frequently require secure boot to be enabled, and will prevent you from running
the game if secure boot is disabled. If you therefore dual-boot with a distro
of GNU/Linux which is not Microsoft-signed, and play such a video game under
Windows, you'd be stuck between having secure boot enabled or disabled. This is
until now - whereby you can use these scripts to take ownership of secure boot
yourself, instead of disabling it outright.

It should be noted that the system requirements of Windows 11 do **NOT**
require secure boot to _enabled_ - this is a common misconception. However they
do require secure boot to be **supported** by the system.

The second reason you may not want to disable it is simply for the security it
should offer. The whole point of the system is to block malware and other
undesirable code from loading during the early boot stage. The secure boot
system doesn't only apply to the `.efi` binaries that boot from the firmware -
it also initiates a chain of trust that ensures security during the entirety of
the system boot-up process. In the context of GNU/Linux, having secure boot
enabled should trigger the bootloader to verify that the Linux kernel image it
loads is signed, and then the Linux kernel should verify all its modules are
signed (and refuse to load unsigned modules, by making use of the kernel
lockdown feature).

Unfortunately, whether or not the factory state of secure boot is really
"secure", depends on whether or not you trust Microsoft. The presence of the
OEM's certificate is likely negligible, since it will only be used to sign the
OEM's own internal debugging/diagnostics, but the presense of Microsoft's
certificates, especially their KEK, could be considered a "backdoor", since it
allows them to update your system's db or dbx databases at any time. While the
scripts in this repo do give you the option of having Microsoft's KEK installed
alongside your own KEK, the choice is entirely yours, and you can choose to
exclude Microsoft's KEK certificate from your KEK database if desired, without
affecting your ability to boot Windows (assuming you keep Microsoft's db
certificates).

# Comparison table

| Mode | Factory state | Secure boot disabled | Using these scripts |
|-|-|-|-|
| Owner | OEM | N/A | You |
| Controlled by | OEM + Microsoft | N/A | You (+ OPTIONALLY Microsoft/OEM) |
| Security level | Debatable | Requires common sense | Secure |
| Some Windows features | Available | Blocked | Available |
| Video game anti-cheat | Permitted | Forbidden | Permitted |
| Think of it as | Restricted boot | YOLO | Secure boot |

# Why haven't I heard about this until now?
Either you have just kept secure boot disabled as you've seen it as useless, or
you have always used a distro which is **signed by Microsoft**, and hence is
authorized by Microsoft to boot on any system even with the factory secure boot
setup.

Since the **GRUB 2** bootloader, used by most modern GNU/Linux distributions,
is licensed under the **GPLv3**, Microsoft will refuse to sign it. This is
because the **GPLv3** license is intentionally designed to protect you from the
problem of **TiVoization** - whereby free software is effectively rendered
non-free, due to it existing in an environment (e.g., on a hardware device)
that itself does not permit running modified versions of the software. So in
other words, you could download and modify the free software program, but would
have no way to run it on the locked-down device that the original version runs
on. In the context of a factory secure boot system, this applies because only
Microsoft-signed binaries are allowed to run on the system by default, and your
modified version would not be Microsoft-signed.

To work around this problem, distributions instead use a companion bootloader
called **shim**. **shim** is licensed under a more permissive license, and can
therefore be signed by Microsoft - and then **shim** can use its own internal
database, known as the **MOKList (Machine Owner Keys)** to verify if the main
bootloader (e.g., **GRUB 2**) is allowed to start up. By this logic, Microsoft
only needs to sign **shim**, and then any other binaries can be signed by keys
that are either compiled in to **shim**'s vendor database, or in the MOKList.

Unfortunately, this still creates an non-level playing field, since **shim** is
essentially useless if it's not Microsoft-signed. This is because, although
**shim** uses its own internal database (MOKList) separate to the main UEFI
secure boot databases, **shim** has to be signed by a key trusted by the
firmware to be able to load in the first place. From an end user's perspective,
this is not a big deal, since the distribution maintainers will deal with it.
From a distribution maintainer's perspective, this is problematic. In order to
have your **shim** build signed by Microsoft, you first have to submit it to
the [shim review board](https://github.com/rhboot/shim-review), who, besides
having the audacity to directly state that they are the ones who decide what
["the world is able to boot"](https://go.dmassey.net/shimscam) (although the
scripts in this repository make every effort to change who REALLY should have
control of this, and the answer is **only the device owner**), also require
the entity submitting the **shim** binary to be officially recognised as a
corporation or organization under their jurisdiction. Clearly this is not
practical for small, community-driven projects, like MassOS. And this problem
was one of the reasons for these scripts' existence to begin with - to level
out the playing field and give people back control over their own computers.

While MassOS could instead just yoink the signed **shim** binary from another
distribution, such as **Ubuntu** or **Fedora**, this raises ethical issues,
including creating reliance on a distribution outside of MassOS's control, and
being essentially reliant on non-free software, since again, you _could_
modify **shim**, but then you loose the Microsoft signature! Rather than try to
buy into this problem, the MassOS developers took the decision to instead
compile and self-sign everything, and provide documentation on how users can
import the needed secure boot certificates into their own firmware. And this
may require using the scripts in this repository to take control over your own
computer's secure boot environment, but it is a worthwhile trade-off, to always
promote and foster freedom and control over your own computing.

Even if you aren't a user of MassOS, we hope you will agree with most of what
has been written, and will therefore make the decision to take ownership and
control over your own computer's secure boot environment, without the need to
instead compromise the security of your machine by turning off secure boot
entirely (which would also be the boring and easy way out if you really think
about it). The scripts in this repository have been designed (and documented)
to make the process as simple as possible. The author(s) can only hope you will
benefit from it!

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
Secure Boot: enabled (user)   #Secure boot is enabled - PK is locked.
Secure Boot: disabled         #Secure boot is disabled - PK is still locked.
Secure Boot: disabled (setup) #Setup mode - PK is cleared and replaceable.
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
