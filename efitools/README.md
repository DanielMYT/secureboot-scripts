Provides support for a prebuilt efitools binary package, which can be used as a
drop in replacement for any distribution which does not provide efitools in
their package repositories.

The binary package is stored under the `distrib/` subdirectory, encoded in
ASCII (base64) and split into 1000-line parts. This is so it is more friendly
to git, compared to storing the raw binary package in the git repository.

The `efitools-prebuilt.sh` script will automatically re-combine and decode the
stored package parts from this repository. It will then extract the tarball to
the `extracted/` directory. The efitools binary programs will then be available
under the `extracted/bin/` directory.

The binary package was compiled on Ubuntu 16.04, with OpenSSL libraries being
statically-linked. It is therefore compatible with almost any GNU/Linux distro
released post-2016, and only depends on Glibc present on the host system (which
is present out of the box on all GNU/Linux distributions). Unfortunately, it
currently only supports the `x86_64` architecture. If you are on a different
architecture, you will need to install a distribution-provided efitools package
instead (or compile it yourself).

The original, unsplit, unencoded tarball can alternatively be downloaded from
[here](https://dmassey.net/files/misc/efitools-1.9.2-standalone-x86_64.tar.xz).
The SHA256 checksum for the original binary package tarball is
`369f0b30d4f3ae00ae8d3b63c88f49b66caa38cbf0a5a9f908104f963feac8fb`.
