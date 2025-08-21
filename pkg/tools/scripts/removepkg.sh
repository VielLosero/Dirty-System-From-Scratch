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
# --- END LICENSE ---

#:Maintainer: Viel Losero <viel.losero@gmail.com>
#:Contributor: -

#:Version:0.0.1

usage(){
echo "USAGE: removepkg.sh { pkg_name }"
echo "              	  { name-ver-arch-rel }"
echo "              	  { pkg-example-0.0.1-x86_64-1_extra_info }"
exit 1
}

DRY_RUN=${DRY_RUN:+1}
if [ $# -ne 1 ] ; then usage ; fi

pkg_name="$1" 
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})

echo "  Package name: $name"
echo "  Version: $ver"
echo "  Arch: $arch"
echo "  Release: $rel"
echo "  Removing files ..."


INSTALLDIR=${INSTALLDIR:-/}
cd $INSTALLDIR || exit 1
LOGDIR="$INSTALLDIR/var/log" 
LOGFILE="$LOGDIR/make.buildpkg.log"
PKG_DB="$INSTALLDIR/pkg/installed"
PKG_DIR="$PKG_DB/$pkg_name" 
TMP_PKG_DIR=$(mktemp -d /tmp/make.buildpkg-tmp-pkg-XXXXXX)
# pkg installed files
PKG_INDEX_FILE="$PKG_DIR/index"
# temp file for order pkg installed files if not in LC_ALL=POSIX for old pkg
TMP_PKG_INDEX_FILE="$TMP_PKG_DIR/index.posix"
# pkg shared libs
PKG_SHAREDLIBS_FILE="$PKG_DIR/needed-libs"
# pkg build time
PKG_BUILDTIME_FILE="$PKG_DIR/build-time"

# All needed files are all installed files + noremove - pkg_installed
# to find files that are in other packages and can't remove.
TMP_ALL_NEEDED_FILES=$TMP_PKG_DIR/make.buildpkg-all-needed-files.remove
TMP_ALL_NEEDED_FILES_SORT=$TMP_PKG_DIR/make.buildpkg-all-needed-files-sort.remove
TMP_FILES_TO_REMOVE=$TMP_PKG_DIR/make.buildpkg-files-to.remove
# find all files installed
find $PKG_DB -name "index" -not -path "*/$pkg_name/*" -exec cat {} \; | LC_ALL=POSIX sort -u > $TMP_ALL_NEEDED_FILES
cat $TMP_ALL_NEEDED_FILES | LC_ALL=POSIX sort -u > $TMP_ALL_NEEDED_FILES_SORT
# order pkg index if not in posix
cat $PKG_INDEX_FILE | LC_ALL=POSIX sort -u > $TMP_PKG_INDEX_FILE
# compare all files to pkg installed and get uniques no needed by third parties
LC_ALL=POSIX comm -23 $TMP_PKG_INDEX_FILE $TMP_ALL_NEEDED_FILES_SORT 2>/dev/null > $TMP_FILES_TO_REMOVE
# need to do a dry run.
if [ -z $DRY_RUN ]  ; then
  # remove no needed files
  cat $TMP_FILES_TO_REMOVE | LC_ALL=POSIX sort -ru | while read line ; do
    if [ -f $line ] ; then 
      rm -v $line
    elif [ -d $line ] ; then 
      rmdir -v $line
    elif [ -h $line ] ; then
      rm -v $line
    fi
  done
  # remove pkg 
  rm -rf $PKG_DIR 2>/dev/null && echo "$(date +"%a %b %d %T %Z %Y") Removed $pkg_name in $INSTALLDIR" >> $LOGFILE
else
  # dry run no needed files
  echo "  Dry run mode ..."
  cat $TMP_FILES_TO_REMOVE | LC_ALL=POSIX sort -ru | while read line ; do
    if [ -f $line ] ; then 
      echo "rm -v $line"
    elif [ -d $line ] ; then 
      echo "rmdir -v $line"
    elif [ -h $line ] ; then
      echo "rm -v $line"
    fi
  done
fi

