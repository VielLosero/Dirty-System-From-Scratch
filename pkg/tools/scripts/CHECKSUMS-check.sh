#!/bin/bash

cat /pkg/tools/CHECKSUMS_MLFSCHROOT_MAKERS.txt | md5sum -c --quiet
cat /pkg/tools/CHECKSUMS_MLFSCHROOT_BUILDERS.txt | md5sum -c --quiet
cat /pkg/tools/CHECKSUMS_MLFSCHROOT_PACKAGES.txt | md5sum -c --quiet

cat /pkg/tools/CHECKSUMS_dirty-0.0_MAKERS.txt | md5sum -c --quiet
cat /pkg/tools/CHECKSUMS_dirty-0.0_BUILDERS.txt | md5sum -c --quiet
cat /pkg/tools/CHECKSUMS_dirty-0.0_PACKAGES.txt | md5sum -c --quiet

