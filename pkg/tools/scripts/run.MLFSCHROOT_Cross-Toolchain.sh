#!/bin/bash
# --- LICENSE ---
# Copyright 2024, 2025 Viel Losero.
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# --- END LICENSE ---

#:Maintainer: Viel Losero <viel.losero@gmail.com>
#:Contributor: -

#:Version:0.0.5

#ROOT=${ROOT:-} ; TMP="$ROOT/tmp"
ROOT=${ROOT:-/mnt/lfs} ; TMP="$ROOT/tmp"
#REPO=${REPO:-$rel_tag1}
REPO=MLFSCHROOT
REPODIR=${REPODIR:-/pkg/repository/$REPO}
LFSREPODIR=${LFSREPODIR:-$ROOT/pkg/repository/$REPO}
METADATADIR="${METADATADIR:-$ROOT/pkg/metadata/$REPO}"
INSTALLED_DIR="$ROOT/pkg/installed"
BLACKLISTED_DIR="$ROOT/pkg/blacklisted"

INSTALLPKG=1
list=/pkg/tools/lists_of_packages/MLFSCHROOT_Cross-Toolchain_and_cross_tools.txt

# Check for ROOT.
[[ -d $ROOT ]] || mkdir -vp $ROOT

# Check for rsync.
if ! type -p rsync &>/dev/null ; then
  echo "ERROR: Cannot find rsync, please install it."; exit 1 
fi

# run lfs-user first to make needed user and files.
bash /pkg/tools/lfs-user create

# Read list.
cat $list | grep -v "#" | while read line ; do 

# Find last maker to get vars.
for file in $(ls $REPODIR/makers/*/*/*$line* | sort -Vr | head -1 ) ; do

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

if [ -e "$BLACKLISTED_DIR/$pkg_name" ] ; then
	echo "Blacklisted **skipping** : $pkg_name"
else
	if [ -e "$REPODIR/$maker_path" ] ; then
		# if we have sources on a builder extract.
		if [ -e $REPODIR/$builder_path ] ; then
			SKIP=1 DECODE=0 bash /pkg/tools/lfs-user $REPODIR/$builder_path || exit 1
		fi
		# if builder not exist make it.
		if [ ! -e $LFSREPODIR/$builder_path ] ; then
      echo "Making builder."
		  bash /pkg/tools/lfs-user $REPODIR/$maker_path || exit 1
		fi
    if [ ! -e $LFSREPODIR/$package_path ] ; then
      echo "Building package."
      SOURCE_DATE_EPOCH="1746190997" bash /pkg/tools/lfs-user $LFSREPODIR/$builder_path || exit 1
    fi
		if [ -e $LFSREPODIR/$package_path ] ; then
			#ls $package_full_path
			if [ ! -e $INSTALLED_DIR/$pkg_name ] ; then
				echo "Installing package."
				if [ "$INSTALLPKG" == "1" ] ; then 
					INSTALLDIR=/mnt/lfs bash /pkg/tools/lfs-user "$LFSREPODIR/$package_path install" || exit 1
				fi
			else
				echo "Packages already installed: $pkg_name "
			fi
		fi
		# reove tmp sources to have space
		#rm -rf /mnt/lfs/tmp/$REPO/*
		#rm -rf /mnt/lfs/tmp/sources-all
	fi
fi


done
#done && rsync -avPn $LFSREPODIR/ $REPODIR && rsync -avPn $METADATADIR /pkg/metadata 
done && rsync -avP $LFSREPODIR/ $REPODIR && rsync -avP $METADATADIR /pkg/metadata 
