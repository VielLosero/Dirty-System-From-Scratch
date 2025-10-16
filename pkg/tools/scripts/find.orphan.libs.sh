#!/bin/bash



cat /pkg/installed/*/index | grep "\.so$" | rev | cut -d / -f1 | rev | sort -u >/tmp/installed1
cat /pkg/installed/*/index | grep "\.so\." | rev | cut -d / -f1 | rev | sort -u >/tmp/installed2
cat /pkg/installed/*/needed-libs | cut -d':' -f2 | sed 's/,/\n/g' | sort -u > /tmp/needed
cat /tmp/installed1 /tmp/installed2 | sort -u >/tmp/installed
comm -13 /tmp/installed /tmp/needed #> /tmp/needed.libs.not.found.${pkg_name}.before
