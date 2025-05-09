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
echo "USAGE: checkpkgmd5.sh { pkg_name }"
echo "              	    { name-ver-arch-rel }"
echo "              	    { pkg-example-0.0.1-x86_64-1_extra_info }"
exit 1
}

if [ $# -ne 1 ] ; then usage ; fi

pkg=$1
package_path=""
if [[ "$(ls -1 /pkg/repository/dirty-0.1/packages/*/$pkg/* 2>/dev/null | wc -l)" -eq 1 ]] ; then 
	package_path="$(ls -1 /pkg/repository/dirty-0.1/packages/*/$pkg/*)"
else
	if [[ "$(ls -1 /pkg/repository/dirty-0.1/packages/*/*/$pkg 2>/dev/null | wc -l)" -eq 1 ]] ; then 
		package_path="$(ls -1 /pkg/repository/dirty-0.1/packages/*/*/$pkg)"
	else
		echo "  Select one pkg as argument:"
		ls -1 /pkg/repository/dirty-0.1/packages/*/*/*$pkg* | sed 's%.*/%%g' | sort -Vr
	fi
fi

pkg_name="$1" 
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})


if [ -e "$package_path" ] ; then
  echo "  Package name: $name"
  echo "  Version: $ver"
  echo "  Arch: $arch"
  echo "  Release: $rel"
  echo "  List of failed checksums."
  cd /
  bash $package_path checksum | tail -n +6 | md5sum -c --quiet 
  cd - >/dev/null
else
  true
fi


