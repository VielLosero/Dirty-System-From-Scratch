#!/bin/bash

ROOT=${ROOT:-/mnt/lfs}
REPODIR=/pkg/repository/dirty-0.1 # local repo
CHROOTDIR=/pkg/repository/dirty-0.1 # local repo inside chroot
LFSREPODIR=$ROOT/pkg/repository/dirty-0.1
INSTALLED_DIR="$ROOT/pkg/installed"
BLACKLISTED_DIR="$ROOT/pkg/blacklisted"
LFS=$ROOT

#REMOVE_BUILDER=1
INSTALLPKG=1
MD5SUM=1
list=/pkg/tools/lists_of_packages/LFSCHROOT_Chroot_additional_tools.txt

# change owner
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools,pkg}
case $(uname -m) in
	  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac

# install chroot pkg to have proc sys dev ...
if [ ! -e $INSTALLED_DIR/lfschroot-0.0.1-all-1_LFSCHROOT_r12.2_multilib ] ; then
INSTALLDIR=$ROOT bash $REPODIR/packages/l/lfschroot/lfschroot-0.0.1-all-1_LFSCHROOT_r12.2_multilib.sh install || exit 1
fi

# mount dev proc sys ...
bash /pkg/tools/lfs-chroot mount || exit 1

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
maker_path="makers/$first_pkg_char/$name/$maker"
builder_path="builders/$first_pkg_char/$name/$builder"
package_path="packages/$first_pkg_char/$name/$package"

if [ -e "$BLACKLISTED_DIR/$pkg_name" ] ; then
	echo "Blacklisted **skipping** : $pkg_name"
else
	if [ -e "$REPODIR/$maker_path" ] ; then
		# if we have sources on a builder extract it and recreate.
		if [ -e $REPODIR/$builder_path ] ; then
			echo "--> Extracting sources"
			SKIP=1 DECODE=0 bash $REPODIR/$builder_path || exit 1
			echo "--> Remake builder"
			bash $REPODIR/$maker_path || exit 1
		fi
		# if builder not exist make it.
		if [ ! -e $LFSREPODIR/$builder_path ] ; then
			echo "--> Cp builder to LFS"
			mkdir -vp $LFSREPODIR/builders/$first_pkg_char/$name
			cp -av $REPODIR/$builder_path $LFSREPODIR/$builder_path
		fi
		if [ -e $LFSREPODIR/$builder_path ] ; then
			if [ ! -e $LFSREPODIR/$package_path ] ; then
				echo "--> Run builder on chroot."
			bash /pkg/tools/lfs-chroot bash $CHROOTDIR/$builder_path || exit 1  
			fi
		fi
		if [ -e $LFSREPODIR/$package_path ] ; then
			#ls $package_full_path
			echo "--> Copy package from lfsrepo to local repo"
			cp -av $LFSREPODIR/$package_path $REPODIR/$package_path || exit 1
			if [ ! -e $INSTALLED_DIR/$pkg_name ] ; then
				echo "Package **not** installed: $pkg_name"
				if [ "$INSTALLPKG" == "1" ] ; then 
					echo "--> Installing package"
					INSTALLDIR=/mnt/lfs bash $LFSREPODIR/$package_path install || exit 1
					if [ "$MD5SUM" == "1" ] ; then 
						INSTALLDIR=/mnt/lfs bash $LFSREPODIR/$package_path md5sum > $INSTALLED_DIR/$pkg_name/md5sum
					fi
				fi
			else
				echo "Packages already installed: $pkg_name "
			fi
		else
			echo "$LFSREPODIR/$package_path not exist.!!" | exit 1
		fi
	fi
fi


done
done

##  # Clean the chroot env
##  # First, remove the currently installed documentation files to prevent them from ending up in the final system, and to save about 35 MB:
##  
##  rm -rf $ROOT/usr/share/{info,man,doc}/*
##  
##  # Second, on a modern Linux system, the libtool .la files are only useful for libltdl. No libraries in LFS are loaded by libltdl, and it's known that some .la files can cause BLFS package failures. Remove those files now:
##  
##  find $ROOT/usr/{lib,libexec} -name \*.la -delete
##  find $ROOT/usr/lib32 -name \*.la -delete
##  
##  # The current system size is now about 3 GB, however the /tools directory is no longer needed. It uses about 1 GB of disk space. Delete it now:
##  
##  rm -rf $ROOT/tools
##  
##  # remove the repository and the tmp dir
##  
##  rm -rf $ROOT/pkg
##  rm -rf $ROOT/tmp



