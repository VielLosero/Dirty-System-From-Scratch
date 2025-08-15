#!/bin/bash

[ -d /pkg/tools/checksums ] || mkdir -vp /pkg/tools/checksums

find /pkg/repository/MLFSCHROOT/makers/ -type f -exec md5sum {} \; | sort -u  -k2 > /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_MAKERS.txt
find /pkg/repository/MLFSCHROOT/builders/ -type f -exec md5sum {} \; | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_BUILDERS.txt
find /pkg/repository/MLFSCHROOT/packages/ -type f -exec md5sum {} \; | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_PACKAGES.txt


find /pkg/repository/dirty-0.0/makers/ -type f -exec md5sum {} \; | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_dirty-0.0_MAKERS.txt
find /pkg/repository/dirty-0.0/builders/ -type f -exec md5sum {} \; | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_dirty-0.0_BUILDERS.txt
find /pkg/repository/dirty-0.0/packages/ -type f -exec md5sum {} \; | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_dirty-0.0_PACKAGES.txt

# Sources checksum from builders.
grep "sha256sum -c" /pkg/repository/*/builders/*/*/* | cut -d '"' -f2 | sort -u -k2 > /pkg/tools/checksums/CHECKSUMS_SOURCES.txt

