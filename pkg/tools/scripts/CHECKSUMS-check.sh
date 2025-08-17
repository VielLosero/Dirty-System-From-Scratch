#!/bin/bash

cat /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_MAKERS.txt | md5sum -c --quiet
cat /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_BUILDERS.txt | md5sum -c --quiet
cat /pkg/tools/checksums/CHECKSUMS_MLFSCHROOT_PACKAGES.txt | md5sum -c --quiet

cat /pkg/tools/checksums/CHECKSUMS_dirty-0.0_MAKERS.txt | md5sum -c --quiet
cat /pkg/tools/checksums/CHECKSUMS_dirty-0.0_BUILDERS.txt | md5sum -c --quiet
cat /pkg/tools/checksums/CHECKSUMS_dirty-0.0_PACKAGES.txt | md5sum -c --quiet

