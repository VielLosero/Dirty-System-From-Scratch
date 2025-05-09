#!/bin/bash

REPODIR=/pkg/repository/dirty-0.1
INSTALLDIR=${INSTALLDIR:-/}
PKG_DB="$INSTALLDIR/pkg/installed"

UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver
UPDATEDIR_REPO_MAKERS=/tmp/updates/repository/makers
UPDATEDIR_REPO_BUILDERS=/tmp/updates/repository/builders

list=/pkg/tools/lists_of_packages/dirty-0.1_core_list.txt

#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | while read line ; do 
#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT| while read line ; do 
cat $list | grep -v "#" | while read line ; do 
#cat /pkg/tools/lists_of_packages/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT | while read line ; do 

for file in $(ls $UPDATEDIR_REPO_BUILDERS/*$line* 2>/dev/null) ; do

builder_full_path=$(realpath $file)
builder=${builder_full_path##*/}
maker=make.${builder}
package=${builder/buildpkg./}
pkg_name=${package/.sh/}
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
package_full_path="$REPODIR/packages/$first_pkg_char/$name/$package"
maker_full_path="$REPODIR/makers/$first_pkg_char/$name/$maker"

echo $file
bash $file || exit 1
if [ $? -eq 0 ] ; then 
  rm -v $file
fi

done
done 

