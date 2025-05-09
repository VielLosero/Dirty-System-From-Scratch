#!/bin/bash

ROOT=${ROOT:-/pkg}
REPODIR=$ROOT/repository/dirty-0.1
INSTALLED_DIR="$ROOT/installed"
BLACKLISTED_DIR="$ROOT/blacklisted"

if [ $# -ne 1 ] ; then
	echo "USAGE:"
	exit 1
fi



list=$1
INSTALLPKG=1
MD5SUM=1

cat $list | grep -v "#" | while read line ; do 
#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | while read line ; do 
#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT| while read line ; do 
#cat $REPODIR/tools/lists_of_packages/last_update_ordered_list.txt | grep -v "#" | while read line ; do 

#for file in $(ls $REPODIR/makers/*/*/*$line*) ; do
# run only last 
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
builder_full_path="$REPODIR/builders/$first_pkg_char/$name/$builder"
package_full_path="$REPODIR/packages/$first_pkg_char/$name/$package"

if [ -e "$BLACKLISTED_DIR/$pkg_name" ] ; then
	echo "Blacklisted **skipping** : $pkg_name"
else
	if [ -e "$maker_full_path" ] ; then
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
			if [ ! -e $INSTALLED_DIR/$pkg_name ] ; then
				echo "Package **not** installed: $pkg_name"
				if [ "$INSTALLPKG" == "1" ] ; then 
					bash $package_full_path install
					if [ "$MD5SUM" == "1" ] ; then 
						bash $package_full_path md5sum > $INSTALLED_DIR/$pkg_name/md5sum
					fi
				fi
			else
				echo "Packages already installed: $pkg_name "
			fi
		fi
	fi
fi


done
done

