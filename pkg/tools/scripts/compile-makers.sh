#!/bin/bash

REPODIR=/pkg/repository/dirty-0.1
INSTALLDIR=${INSTALLDIR:-/}
PKG_DB="$INSTALLDIR/pkg/installed"

list=$1

#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | while read line ; do 
#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT| while read line ; do 
cat $list | grep -v "#" | grep -v LFSCHROOT | while read line ; do 
#cat /pkg/tools/lists_of_packages/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT | while read line ; do 

for file in $(ls $REPODIR/makers/*/*/*$line*) ; do

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
builder_full_path="$REPODIR/builders/$first_pkg_char/$name/$builder"
package_full_path="$REPODIR/packages/$first_pkg_char/$name/$package"



	## exclude packages here
	if [[ "$file" =~ "blfs-bootscripts-20250225" ]] ; then echo "Package skipped          : $pkg_name " ; break ; fi

if [ -e $maker_full_path ] ; then
	if [ ! -e $builder_full_path ] ; then
	bash $maker_full_path || exit 1
	fi
	if [ -e $builder_full_path ] ; then
		if [ ! -e $package_full_path ] ; then
		bash $builder_full_path || exit 1
		fi
	fi
	if [ -e $package_full_path ] ; then
		#ls $package_full_path
		if [ ! -e $PKG_DB/$pkg_name ] ; then
			echo "Package **not** installed: $pkg_name"
			#bash $package_full_path install
			#bash $package_full_path md5sum > $PKG_DB/$pkg_name/md5sum
		else
			echo "Package already installed: $pkg_name "
		fi
	fi
fi

done
done

