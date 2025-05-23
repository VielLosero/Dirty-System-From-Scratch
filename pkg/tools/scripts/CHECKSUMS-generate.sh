#!/bin/bash

find /pkg/repository/MLFSCHROOT/makers/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_MAKERS.txt
find /pkg/repository/MLFSCHROOT/builders/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_BUILDERS.txt
find /pkg/repository/MLFSCHROOT/packages/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_PACKAGES.txt


find /pkg/repository/dirty-0.0/makers/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_dirty-0.0_MAKERS.txt
find /pkg/repository/dirty-0.0/builders/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_dirty-0.0_BUILDERS.txt
find /pkg/repository/dirty-0.0/packages/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_dirty-0.0_PACKAGES.txt

# Sources checksum from builders.
grep "sha256sum -c" /pkg/repository/*/builders/*/*/* | cut -d '"' -f2 | sort -u > /pkg/tools/CHECKSUMS_SOURCES.txt

