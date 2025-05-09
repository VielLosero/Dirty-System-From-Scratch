#!/bin/bash

REPODIR=/pkg/repository/dirty-0.1
INSTALLDIR=${INSTALLDIR:-/}
PKG_DB="$INSTALLDIR/pkg/installed"
PKG_DIR="$PKG_DB/$pkg_name"


#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | while read line ; do 
#cat $REPODIR/tools/all_makers_ordered_list.txt | grep -v "#" | grep -v LFSCHROOT| while read line ; do 
cat $REPODIR/tools/lists_of_packages/dirty-0.1_core_list.txt | grep -v "#" | while read line ; do 

maker_full_path=$(ls $REPODIR/makers/*/*$line)
maker=${maker_full_path##*/}
builder=${maker/make./}
package=${builder/buildpkg./}
pkg_name=${package/.sh/}
first_pkg_char=$(printf %.1s ${package,})
builder_full_path="$REPODIR/builders/$first_pkg_char/$builder"
package_full_path="$REPODIR/packages/$first_pkg_char/$package"

if [ -e $package_full_path ] ; then
	#ls $package_full_path
	if [ ! -e $PKG_DIR/$pkg_name ] ; then
		bash $package_full_path install
		if [ ! -e $PKG_DIR/$pkg_name/md5sum ] ; then
			bash $package_full_path md5sum > $PKG_DIR/$pkg_name/md5sum
		fi
	else
		echo "Packages already installed: $pkg_name "
	fi
else
	echo "Need to build $line"
fi


done

