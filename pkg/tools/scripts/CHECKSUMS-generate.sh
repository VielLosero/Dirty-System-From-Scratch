#!/bin/bash

find /pkg/repository/MLFSCHROOT/makers/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_MAKERS.txt
find /pkg/repository/MLFSCHROOT/builders/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_BUILDERS.txt
find /pkg/repository/MLFSCHROOT/packages/ -type f  -exec md5sum {} \; > /pkg/tools/CHECKSUMS_MLFSCHROOT_PACKAGES.txt

