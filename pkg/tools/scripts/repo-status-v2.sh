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

#:Version:0.0.2

REPO=${REPO:-*} # * all repos
REPODIR=/pkg/repository/$REPO
PKG_DB=/pkg/installed
BLACKLIST=/pkg/blacklist
LOGFILE=/var/log/make.buildpkg.log
# Update var.
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver
UPDATEDIR_REPO_MAKERS_NEW=/tmp/updates/repository/makers-new
UPDATEDIR_REPO_BUILDERS=/tmp/updates/repository/builders

if [ "$REPO" == "*" ] ; then
  if [[ -z "$@" ]] ; then comls="$REPODIR/*/*/*/* $PKG_DB/*" ; fi
  while [[ ! -z "$@" ]] ; do
    comls=("${comls[@]}" "$REPODIR/*/*/*/*$1* $PKG_DB/*$1*") ; shift
  done
else
  # exclude installed and work only with REPO
  if [[ -z "$@" ]] ; then comls="$REPODIR/*/*/*/*" ; fi
  while [[ ! -z "$@" ]] ; do
	  comls=("${comls[@]}" "$REPODIR/*/*/*/*$1*") ; shift
  done
fi
#echo "${comls[@]}"

# get all existent pkg_name for all the repo or the arguments passed.
ls -1d ${comls[@]} 2>/dev/null | sed 's%.*/%%g' | sed 's/^make\.buildpkg\.//g' | sed 's/^buildpkg\.//g' | sed 's/\.sh$//g' | sort -u | while read pkg_name ; do 
# reset vars.
# m(maker) b(builder) p(package) i(installed) s(skipped/blacklisted) u(update/remove) v(version) l(in logs)
#m M maker exist
#b B builder exist
#p P package exist
#i I are installed
#s s maker or builder are skipped
#s S package are skipped
#u u maker need update
#u U package need upgrade
#u R package can be removed
#v V is the last version
#l - package not in logs # by default
#l   package in logs. is space " "
#l L package are last in logs
m=" " ; b=" " ; p=" " ; i=" " ; s=" " ; u=" " ; v=" " ; l="-"

#echo "$pkg_name"
pkg_name="$pkg_name"
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
rel_build=${rel%%_*} ; rel_helper1=${rel/${rel_build}_}
rel_tag1=${rel_helper1/_*} ; rel_helper2=${rel/${rel_build}_${rel_tag1}_}
rel_tag2=${rel_helper2/_*} ; rel_helper3=${rel/${rel_build}_${rel_tag1}_${rel_tag2}_}
rel_tag3=${rel_helper3/_*}
# check if makers,builders and packages files exist for the pkg_name.
if [ -e $REPODIR/*/*/*/make.buildpkg.$pkg_name.sh ] ; then m=M ; fi
if [ -e $REPODIR/*/*/*/buildpkg.$pkg_name.sh ] ; then b=B ; fi
if [ -e $REPODIR/*/*/*/$pkg_name.sh ] ; then p=P ; fi
# check if pkg_name are installed.
if [ -e $PKG_DB/$pkg_name ] ; then i=I ; fi
# check if pkg_name are blacklisted.
if [ -e $BLACKLIST/make.buildpkg.$pkg_name* ] ; then s=s ; fi
if [ -e $BLACKLIST/buildpkg.$pkg_name* ] ; then s=s ; fi
if [ -e $BLACKLIST/$pkg_name* ] ; then s=S ; fi
# check version from existent files.
if [ "$m" == "M" ] ; then 
	last_version="$(ls -1 $REPODIR/*/*/*/make.buildpkg.${name}-[0-9]*_${rel_tag1}_*.sh | sort -Vr | head -1)"
	last_version=${last_version##*/make.buildpkg.${name}-} 
elif [ "$b" == "B" ] ; then 
	last_version="$(ls -1 $REPODIR/*/*/*/buildpkg.${name}-[0-9]*_${rel_tag1}_*.sh | sort -Vr | head -1)"
	last_version=${last_version##*/buildpkg.${name}-} 
elif [ "$p" == "P" ] ; then 
	last_version="$(ls -1 $REPODIR/*/*/*/${name}-[0-9]*_${rel_tag1}_*.sh | sort -Vr | head -1)"
	last_version=${last_version##*/${name}-} 
fi
# check if pkg_name are the last version.
if [ "$ver-$arch-${rel}.sh" == "$last_version" ] ; then v="V" ; fi
# check if pkg_name is on logs.
if [ -z "$(grep "Installed ${pkg_name}" $LOGFILE)" ] ; then l="-" ; else l=" " ; fi
# check if package are the last installed in logs.
if [ "Installed $pkg_name" == "$(grep "Installed ${name}-[0-9].*_${rel_tag1}_.*" $LOGFILE | tr -s ' ' | tail -1 | cut -d' ' -f7-8)" ] ; then l="L" ; fi

# From here start the update/upgrade/remove/skip conditions.
# check if there is some package to upgrade. New or overwrited.
if [ "$v" == "V" -a "$p" == "P" -a "$l" != "L" ] ; then u=U ; fi
# check if there is some link on /tmp/updates/repository/... , then mark the maker/builder to update.
if ls -1 $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/make.buildpkg.${pkg_name}.sh >/dev/null 2>/dev/null ; then u="u" ; fi
if ls -1 $UPDATEDIR_REPO_MAKERS_NEW/make.buildpkg.${pkg_name}.sh >/dev/null 2>/dev/null ; then u="u" ; fi
if ls -1 $UPDATEDIR_REPO_BUILDERS/buildpkg.${pkg_name}.sh >/dev/null 2>/dev/null ; then u="u" ; fi
# check if package is older then dont mark as update.
if [ "$v" == " " -a "$u" == "u" ] ; then u=" " ; fi 
# check if package will be removed.
if [ "$i" == "I" -a "$v" == " " -a "$l" == " " ] ; then u=R ; fi
# check if package are skipped
if [ "$s" != " " ] ; then u=" " ; fi

# Show status.
# NOTES: s and u lowers reference to makers or builders. Upper reference to packages.
#echo " M B P I S/s U/u/R V L/l package_name "
#echo " $m $b $p $i $s $u $v $l $pkg_name "
echo "# $m $b $p $i $s $u $v $l $pkg_name"
done
