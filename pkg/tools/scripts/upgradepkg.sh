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

# update-repository-makers --> will create links of makers that have new versions.
# upgrade-repository-makers --> will run CHECK_RELEASE=1 NEW=0 makers's links to create NEW versions of makers.

# update-repository-builders --> will create links of makers that don't have builders.
# upgrade-repository-builders --> will run makers's links to create new builders.

# update-repository-pacakges --> will create links of builders that don't have packages.
# upgrade-repository-packages --> will run builders's links to create new packages.

# updatepkg --> 
# upgradepkg --> install last and remove old.
# installpkg --> 
# removepkg -->

REPODIR=/pkg/repository/dirty-0.1
PKG_DB=/pkg/installed
LOGFILE=/var/log/make.buildpkg.log
#UPDATELINKS=/tmp/updates/need_update
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver
UPDATEDIR_REPO_MAKERS_NEW=/tmp/updates/repository/makers-new
UPDATEDIR_REPO_BUILDERS=/tmp/updates/repository/builders


# Find last version.
# Check not installed.
for pkg_name in $( bash /pkg/tools/scripts/repo-status.sh | grep "     U V - " | grep -v "LFSCHROOT" | cut -c 18- ); do 
#echo $pkg_name
package=${pkg_name}.sh
builder=buildpkg.${package}
maker=make.${builder}
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
maker_full_path="$REPODIR/makers/$first_pkg_char/$name/$maker"
builder_full_path="$REPODIR/builders/$first_pkg_char/$name/$builder"
package_full_path="$REPODIR/packages/$first_pkg_char/$name/$package"
rel_build=${rel%%_*} ; rel_helper1=${rel/${rel_build}_}
rel_tag1=${rel_helper1/_*} ; rel_helper2=${rel/${rel_build}_${rel_tag1}_}
rel_tag2=${rel_helper2/_*} ; rel_helper3=${rel/${rel_build}_${rel_tag1}_${rel_tag2}_}
rel_tag3=${rel_helper3/_*}

# Install.
echo "upgrade $pkg_name"
bash $package_full_path install

# Remove old versions.
# be care if there are more than one to remove.
# need check if only one.
if remove_pkg=$(bash /pkg/tools/scripts/repo-status.sh $name | grep " I   R     " | cut -c 18- ) ; then
  echo "remove $remove_pkg"
  bash /pkg/tools/scripts/removepkg.sh $remove_pkg remove && rm -rf $PKG_DB/$removepkg
fi

done




