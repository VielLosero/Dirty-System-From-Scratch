#!/bin/bash

# This script will remake builders from all existent makers, or make new builders from updated makers.
# NEW=1 will remake all the builders. NEW=0 will make only new builders from updated makers. 
NEW=${NEW:-1}

# Extract sources from existent buidlers to minimize downloads, then 

ROOT=${ROOT:-/mnt/lfs}
REPODIR=/pkg/repository/dirty-0.1 # local repo
LFSREPODIR=$ROOT/pkg/repository/dirty-0.1
INSTALLED_DIR="$ROOT/pkg/installed"
BLACKLISTED_DIR="$ROOT/pkg/blacklisted"

# Find last maker to get vars.
# this is same as cat all_makers_ordered_list.txt list but with this we get all makers that are or not in list.
for file in $(ls -1 /pkg/repository/dirty-0.1/makers/*/*/*.sh | while read line ; do line1=${line##*/} ; line2=${line1/make.buildpkg./} ; name=${line2%-*-*-*} ; line3=${line2/$name/} ; line4=${line3#-*-*-*_} ; line5=${line4%%_*} ;echo ".${name}-[0-9]*_${line5}_*"  ; done | sort -u | while read list ; do ls /pkg/repository/dirty-0.1/makers/*/*/*$list | sort -Vr | head -1 ; done) ; do

maker_full_path=$file
maker=${maker_full_path##*/}
builder=${maker/make./}
package=${builder/buildpkg./}
pkg_name=${package/.sh/}
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
maker_path="makers/$first_pkg_char/$name/$maker"
builder_path="builders/$first_pkg_char/$name/$builder"
package_path="packages/$first_pkg_char/$name/$package"

if [ -e "$BLACKLISTED_DIR/$maker" ] ; then
	echo "Blacklisted **skipping** : $maker"
else
  # Extract sources if we have it
  if [ -e $REPODIR/$builder_path ] ; then
    SKIP=1 DECODE=0 bash $REPODIR/$builder_path || exit 1
  fi
  bash $REPODIR/$maker_path || exit 1
fi

done
