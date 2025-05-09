#!/bin/bash

ROOT=${ROOT:-/mnt/lfs}
REPODIR=/pkg/repository/dirty-0.1 # local repo
LFSREPODIR=$ROOT/pkg/repository/dirty-0.1
INSTALLED_DIR="$ROOT/pkg/installed"
BLACKLISTED_DIR="$ROOT/pkg/blacklisted"

INSTALLPKG=1
list=/pkg/tools/lists_of_packages/LFSCHROOT_Cross-Toolchain_and_cross_tools.txt

if [ ! -e "$INSTALLED_DIR/make_buildpkg_dirty_package_manager*" ] ; then 
INSTALLDIR=$ROOT bash $REPODIR/packages/m/make_buildpkg_dirty_package_manager/make_buildpkg_dirty_package_manager-0.0.1-all-1_LFSCHROOT_Viel.sh install
fi
if [ ! -e "$INSTALLED_DIR/filesystem_hierarchy*" ] ; then 
INSTALLDIR=$ROOT bash $REPODIR/packages/f/filesystem_hierarchy/filesystem_hierarchy-3.0-all-1_LFSCHROOT_r12.2_multilib.sh install
fi

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
		if [ -e $LFSREPODIR/$builder_path ] ; then
			SKIP=1 DECODE=0 bash /pkg/tools/lfs-user $LFSREPODIR/$builder_path && rm $LFSREPODIR/$builder_path || exit 1
		elif [ -e $REPODIR/$builder_path ] ; then
			SKIP=1 DECODE=0 bash /pkg/tools/lfs-user $REPODIR/$builder_path || exit 1
		fi
		# if builder not exist make it.
		if [ ! -e $LFSREPODIR/$builder_path ] ; then
		bash /pkg/tools/lfs-user $REPODIR/$maker_path || exit 1
		fi
		if [ -e $LFSREPODIR/$builder_path ] ; then
			echo "Copy builder from lfsrepo to repo"
			cp -av $LFSREPODIR/$builder_path $REPODIR/$builder_path || exit 1
			if [ ! -e $LFSREPODIR/$package_path ] ; then
			bash /pkg/tools/lfs-user $LFSREPODIR/$builder_path || exit 1  
			fi
		fi
		if [ -e $LFSREPODIR/$package_path ] ; then
			#ls $package_full_path
			echo "Copy package from lfsrepo to repo"
			cp -av $LFSREPODIR/$package_path $REPODIR/$package_path || exit 1
			if [ ! -e $INSTALLED_DIR/$pkg_name ] ; then
				echo "Package **not** installed: $pkg_name"
				if [ "$INSTALLPKG" == "1" ] ; then 
					INSTALLDIR=/mnt/lfs bash $LFSREPODIR/$package_path install || exit 1
				fi
			else
				echo "Packages already installed: $pkg_name "
			fi
		fi
		# reove tmp sources to have space
		rm -rf /mnt/lfs/tmp/dirty-0.1/*
	fi
fi


done
done

