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

REPODIR=/pkg/repository/dirty-0.1
PKG_DB=/pkg/installed
LOGFILE=/var/log/make.buildpkg.log

if [[ -z "$@" ]] ; then 
	echo "USAGE: installpkg {name} ex: linux-mainline this will install the last version." 
	echo "                  {pkg_name} ex: linux-mainline-6.14_rc3-x86_64-1_LFS_r12.2_multilib" 
	echo "                  {package_script_file.sh} ex: linux-mainline-6.14_rc3-x86_64-1_LFS_r12.2_multilib.sh" 
	echo "       if there is more than one pkg you need to parse one from the showed list." 
	exit 1
fi
  
  
#while [[ ! -z "$@" ]] ; do
#  if packages=$(ls -1 $REPODIR/packages/*/*/${1}-[0-9]*.sh 2>/dev/null) ; then 
#  LAST_VERSION=$(ls -1 $packages | sort -Vr | head -1)
#  echo "LAST: $LAST_VERSION"
#  elif packages=$(ls -1 $REPODIR/packages/*/*/${1}.sh 2>/dev/null) ; then 
#    echo $packages
#  elif packages=$(ls -1 $REPODIR/packages/*/*/${1/.sh/}.sh 2>/dev/null) ; then 
#    echo $packages
#  #
#  else
#
#    echo "Package $1 not found."
#  
#  fi
#  shift
#done
#
#exit 0

pkg=$1
install_pkg=""
if [[ "$(ls -1 /pkg/repository/dirty-0.1/packages/*/$pkg/* 2>/dev/null | wc -l)" -eq 1 ]] ; then 
	install_pkg="$(ls -1 /pkg/repository/dirty-0.1/packages/*/$pkg/*)"
else
	if [[ "$(ls -1 /pkg/repository/dirty-0.1/packages/*/*/$pkg 2>/dev/null | wc -l)" -eq 1 ]] ; then 
		install_pkg="$(ls -1 /pkg/repository/dirty-0.1/packages/*/*/$pkg)"
	else
		echo "  Select one pkg to install as argument:"
		ls -1 /pkg/repository/dirty-0.1/packages/*/*/*$pkg* | sed 's%.*/%%g' | sort -Vr
	fi
fi


if [ -z $install_pkg ] ; then
	true
else
	echo "$install_pkg" | sed 's%.*/%%g' | sed 's/^make\.buildpkg\.//g' | sed 's/^buildpkg\.//g' | sed 's/\.sh$//g' | sort -u | while read pkg_name ; do 
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
rel_build=${rel%%_*} # release build 1,2,3...
rel_lfs=${rel#*_*_} 
lfs_tag_1=${rel/_${rel_lfs}/}
lfs_tag=${lfs_tag_1/${rel_build}_/}
  # Check if needed libs are present on the system.
  # get needed libs on a tmp file.
	bash $install_pkg shared | tail -n +6 | cut -d':' -f2 | tr ',' '\n' | sort -u > /tmp/needed
  # make index_n with libs's names no path, from package index, we have that libs when install the pkg.
  # easy add all index files whitout path, libs included.
	bash $install_pkg list | sed 's%.*/%%' | sort -u > /tmp/index_n
  # show external libs needed
  #comm -23 /tmp/needed /tmp/index
  #echo ----
  # make all installed files list + index - old pkg version.
  # need to remove old pkg.
  #cat /tmp/index_n /pkg/installed/*/index | sed 's%.*/%%' | sort -u > /tmp/index_all
  find $PKG_DB -name "index" -not -path "*/$name-[0-9]*/*" -exec cat {} \; | sed 's%.*/%%' | LC_ALL=POSIX sort -u > /tmp/index_all_1
  cat /tmp/index_n /tmp/index_all_1 | sort -u > /tmp/index_all
  if [ -z $(comm -23 /tmp/needed /tmp/index_all) ] ; then 
	  echo "Needed libs found on the system."
    INSTALL=1
  else
    echo "Not installing. Needed lisb not found."
  fi

  # Check for files that will be overwrited when install the package.
  # make a proper index formated file.
  # remove package header tail -n +7
  # remove directories grep -v "/$"
  # remove spaces tr -d ' '
  # need order it don't come ordered.
  bash $install_pkg list | tail -n +7 | grep -v "/$" | tr -d ' ' | sort > /tmp/index
  # compare with all other index files to find overwited.
  for installed_pkg_index in $(ls -1 /pkg/installed/*/index) ; do
    overwrited_files=$(comm -12 /tmp/index $installed_pkg_index | wc -l)
    if [ $overwrited_files -gt 0 ] ; then 
    echo "Will overwrite $overwrited_files files in $installed_pkg_index"
    fi
  done

  # Install
  if [ "$INSTALL" == "1" ] ; then
	  echo "bash $install_pkg install"
  fi

	done

fi

