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
#
#  Copyright for portions of this script are held by Gerard Beekmans 1999-2025 
#  as part of project Linux From Scratch and are provided under the MIT license.
#
# --- END LICENSE ---

#:Maintainer: Viel Losero <viel.losero@gmail.com>
#:Contributor: -

#:Version:0.0.3

# Get Application init data from filename.
cd $(dirname $0) ; SWD=$(pwd) # script work directory
full_file_name="$0" ; file_name_no_path=${0##*/} 
make_pkg_name="${file_name_no_path%.*}" ; build_pkg_name="${make_pkg_name/make./}" 
pkg_name=${build_pkg_name/buildpkg./} ; name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
echo "  Package name: $name"
echo "  Version: $ver"
echo "  Arch: $arch"
echo "  Release: $rel"
# Additional info.
short_desc="LFS chroot environment"
url=""
license=""
# prevent empty var.
if [ -z $pkg_name ] ; then exit 1 ; fi

# Master vars.
ROOT=${ROOT:-} ; TMP="$ROOT/tmp"
REPODIR=${REPODIR:-/pkg/repository}
METADATADIR="${METADATADIR:-/pkg/metadata/$first_pkg_char/${name}/${pkg_name}}"
DIST=${DIST:-dirty} ; DISTVER=${DISTVER:-0.1}
SOURCESDIR=${SOURCESDIR:-$TMP/$DIST-$DISTVER/sources-all}
SOURCESPPDIR=${SOURCESPPDIR:-$TMP/$DIST-$DISTVER/sources-per-package/$name-$ver}
BUILDDIR=${BUILDDIR:-$TMP/$DIST-$DISTVER/build/$pkg_name}
PKGDIR=${PKGDIR:-$TMP/$DIST-$DISTVER/pkgfiles/$pkg_name}
OUTBUILD=${OUTBUILD:-$REPODIR/$DIST-$DISTVER/builders/$first_pkg_char/${name}/${build_pkg_name}.sh}
OUTPKG=${OUTPKG:-$REPODIR/$DIST-$DISTVER/packages/$first_pkg_char/${name}/${pkg_name}.sh}

# Other need vars for example to change the default INSTALLDIR=$LFS.
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu

# --- END CAT SEED ---
 
# Config get tool.
if wget --help >/dev/null 2>&1 ; then GETVER="wget --output-document - --quiet" GETFILE="wget -c " SPIDER="wget -q --method=HEAD"
elif curl --help >/dev/null 2>&1 ; then GETVER="curl --connect-timeout 20 --silent" GETFILE="curl -C - -O --silent" SPIDER="curl -L --head --fail --silent"
else echo "Needed wget or curl to download files or check for new versions." && exit 1 ; fi

# Package vars.
version_url=
sum="md5sum"

# Check for new releases.
CHECK_RELEASE=${CHECK_RELEASE:-0}
NEW=${NEW:-1}
if [ $CHECK_RELEASE = 1 ] ; then 
  last_version=0.0.1
  if [ -z "$last_version" ] ; then
    echo "Version check: Failed." ; exit 1
  else
    if [ "$last_version" == "$ver" ] ; then 
      echo "Version check: No new versions found." ; exit 0
    else
      if [ $NEW = 0 ] ; then
        NEWMAKE=${NEWMAKE:-$REPODIR/$DIST-$DISTVER/makers/$first_pkg_char/${name}/make.buildpkg.${name}-${last_version}-${arch}-${rel}.sh}
        if $SPIDER ${file1_url}/${file1/$ver/$last_version} >/dev/null 2>&1 ; then 
          if [ -e "$NEWMAKE" ] ; then
            echo "Exist: $NEWMAKE" ; exit 0
          else
            cp $0 $NEWMAKE 
            echo "Created: $NEWMAKE" ; exit 2
          fi
        else
          echo "Failed: new version file not found." ; exit 1 
        fi
      else
        echo "Version check: $name $last_version  $version_url" ; exit 2
      fi
      echo "Version check: $name $last_version  $version_url" ; exit 2
    fi
  fi
  exit 1
fi

# Make needed dirs.
[ -d $TMP ] || mkdir -p $TMP
[ -d $SOURCESDIR ] || mkdir -p $SOURCESDIR
[ -d $SOURCESPPDIR ] && rm -rfv $SOURCESPPDIR # To prevent fail hard link to sources because files not checked can exist.
[ -d $SOURCESPPDIR ] || mkdir -p $SOURCESPPDIR
[ -d ${OUTBUILD%/*} ] || mkdir -p ${OUTBUILD%/*}
[ -d "$METADATADIR" ] || mkdir -p $METADATADIR

# Get sources and check.
cd $SOURCESDIR || exit 1
# We don't need download sources, we made it, so only set var for compres the files.
file1=$name-$ver.tar.xz 

# Check signaure if needed

# Prepare sources or patches.
echo "Preparing sources."

if [ -e $file1 ] ; then rm $file1 ; fi
TMP_BUILD_LFSCHROOT_DIR=$(mktemp -d /tmp/make.buildpkg-lfschroot-XXXXXX)
trap "rm -rf $TMP_BUILD_LFSCHROOT_DIR" EXIT
cd $TMP_BUILD_LFSCHROOT_DIR || exit 1
  #mkdir {bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,root,run,sbin,srv,tmp,usr,var}
  # 7.3. Preparing Virtual Kernel File Systems
  mkdir -pv {dev,proc,sys,run}
  # 7.5. Creating Directories
  mkdir -pv {boot,home,mnt,opt,srv}
  mkdir -pv etc/{opt,sysconfig}
  mkdir -pv lib/firmware
  mkdir -pv media/{floppy,cdrom}
  mkdir -pv usr/{,local/}{include,src}
  mkdir -pv usr/lib/locale
  mkdir -pv usr/local/{bin,lib,sbin}
  mkdir -pv usr/{,local/}share/{color,dict,doc,info,locale,man}
  mkdir -pv usr/{,local/}share/{misc,terminfo,zoneinfo}
  mkdir -pv usr/{,local/}share/man/man{1..8}
  mkdir -pv var/{cache,local,log,mail,opt,spool}
  mkdir -pv var/lib/{color,misc,locate}
  
  ln -sfv run var/run
  ln -sfv run/lock var/lock
  
  install -dv -m 0750 root
  install -dv -m 1777 tmp var/tmp
  # 7.6. Creating Essential Files and Symlinks
  ln -sv proc/self/mounts etc/mtab
cat > etc/hosts << EOF
  127.0.0.1  localhost $(hostname)
  ::1        localhost
EOF

cat > etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

echo "tester:x:101:101::/home/tester:/bin/bash" >> etc/passwd
echo "tester:x:101:" >> etc/group
install -o tester -d home/tester

touch var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp var/log/lastlog
chmod -v 664  var/log/lastlog
chmod -v 600  var/log/btmp

  echo "Creating LFS auto script."
cat << 'EOF' > tmp/LFS_autoconfig_chroot.sh 
echo "7.2. Changing Ownership "
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac
chown -R root:root $LFS/lib32
echo "7.3.1. Mounting and Populating /dev"
mount -v --bind /dev $LFS/dev
echo "7.3.2. Mounting Virtual Kernel File Systems"
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
echo "7.6. Creating Essential Files and Symlinks"
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    localedef -i C -f UTF-8 C.UTF-8
echo "7.4. Entering the Chroot Environment"
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

EOF

  tar -Jcf $SOURCESDIR/$file1 *
  #rmdir home

  # link the source file created to source per package
  ln -v $SOURCESDIR/$file1 $SOURCESPPDIR/ || exit 1 

# Making Buildpkg.sh $OUTBUILD (The builder)
echo "Making buildpkg."
# echo first line to builder.
echo "#!/bin/bash" > $OUTBUILD
# copy header to builder
sed -n '/^# --- LICENSE ---$/,/^# --- END CAT SEED ---$/p' $SWD/$file_name_no_path >> $OUTBUILD
# Cat EPOCH and dirs to builder.
cat << 'EOF_OUTBUILD' >> $OUTBUILD

# Get start builder date
start_builder_date=$(date +"%s")

# Set source date epoch for reporducible builds
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"

# Create dirs for builder.
[ -d $TMP ] || mkdir -p $TMP
[ -d $SOURCESDIR ] || mkdir -p $SOURCESDIR
[ -d $BUILDDIR ] || mkdir -p $BUILDDIR
[ -d $PKGDIR ] || mkdir -p $PKGDIR
[ -d ${OUTPKG%/*} ] || mkdir -p ${OUTPKG%/*}
[ -d "$METADATADIR" ] || mkdir -p $METADATADIR

# Create temp dir for package metadata.
TMP_METADATA_DIR=$(mktemp -d $ROOT/tmp/make.buildpkg-tmp-build-XXXXXX)
TMP_PKG_TIMINGS_FILE=$TMP_METADATA_DIR/tmp.timings.$pkg_name
TMP_PKG_SHAREDLIBS_FILE=$TMP_METADATA_DIR/tmp.sharedlibs.$pkg_name
TMP_PKG_CHECKSUMS_FILE=$TMP_METADATA_DIR/tmp.checksum.$pkg_name
trap "rm -rf $TMP_METADATA_DIR" EXIT

# Skip run part.
SKIP=${SKIP:-0}
if [ $SKIP  -eq 1 ] ; then
  DECODE=${DECODE:-1} CHECK=${CHECK:-1} EXTRACT=${EXTRACT:-1} PATCH=${PATCH:-1}
  CONFIG=${CONFIG:-1} BUILD=${BUILD:-1} INSTALL=${INSTALL:-1} POST=${POST:-1}
  CONFIG32=${CONFIG32:-1} BUILD32=${BUILD32:-1} INSTALL32=${INSTALL32:-1} POST32=${POST32:-1}
  STRIP=${STRIP:-1} SHARED=${SHARED:-1} CHECKSUM=${CHECKSUM:-1} PACKAGE=${PACKAGE:-1} METADATA=${METADATA:-1}
fi
DECODE=${DECODE:-0} CHECK=${CHECK:-0} EXTRACT=${EXTRACT:-0} PATCH=${PATCH:-0}
CONFIG=${CONFIG:-0} BUILD=${BUILD:-0} INSTALL=${INSTALL:-0} POST=${POST:-0}
CONFIG32=${CONFIG32:-0} BUILD32=${BUILD32:-0} INSTALL32=${INSTALL32:-0} POST32=${POST32:-0}
STRIP=${STRIP:-0} SHARED=${SHARED:-0} CHECKSUM=${CHECKSUM:-0} PACKAGE=${PACKAGE:-0} METADATA=${METADATA:-0}

EOF_OUTBUILD
# The coding base64 part.
  end_build_date=$(date +"%s")
  build_time=$(($end_build_date - $start_build_date))
  echo "Sources build time: $build_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources build time: $build_time seconds"
fi

if [ $INSTALL -eq 1 ] ; then echo "Skipping INSTALL sources." ; else 
  start_install_date=$(date +"%s")
# echo dirs to builder.
echo "Coding dirs to builder."
cat << 'EOF_OUTBUILD' >> $OUTBUILD
echo ""
if [ $DECODE -eq 1 ] ; then echo "Skipping DECODE sources." ; else
  start_decoding_date=$(date +"%s")
  cd $SOURCESDIR || exit 1
  # Make needed dirs to decode source.
  echo "Creating needed dirs to decode sources."
EOF_OUTBUILD
for dir in $(find . -type d | grep -v "^.$" | sort ) ; do
  echo "Found dir: $dir"
  echo "mkdir -vp $dir" >> $OUTBUILD
done
# echo files to builder.
echo "Coding files in b64 to builder."
echo "" >> $OUTBUILD
echo "# Decode base64 source files." >> $OUTBUILD
echo 'echo "Decoding b64 source files."' >> $OUTBUILD
for file in $(find . -type f | sort ) ; do
  if [ -z $(echo "$file" | grep -v "buildpkg.$name-$ver" ) ] ; then
    echo "  Excluding $file"
  else
    echo "  Added: $file"
    # echo check if file exist
    echo "if [ ! -e $file ] ; then" >> $OUTBUILD
    echo 'echo "Extracting: '$file'"' >> $OUTBUILD
    # cat file in base64
    echo "cat <<EOF | base64 -d > $file" >> $OUTBUILD
    cat $file | base64 >> $OUTBUILD
    echo "EOF" >> $OUTBUILD
    echo "fi" >> $OUTBUILD
    #echo md5sum 
    echo "# Check Sha256sum file or exit" >> $OUTBUILD
    echo "echo \"$(sha256sum $file)\" | sha256sum -c || exit 1" >> $OUTBUILD
    echo "# --- END CODE FILE ---" >> $OUTBUILD
  fi
done
# cat to buidler end decoding date and exit option.
cat << 'EOF_OUTBUILD' >> $OUTBUILD
  end_decoding_date=$(date +"%s")
  decoding_time=$(($end_decoding_date - $start_decoding_date))
  echo "Decoding sources time: $decoding_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Decoding sources time: $decoding_time seconds" 
fi
EOF_OUTBUILD

# Build sources part.
cat << 'EOF_OUTBUILD' >> $OUTBUILD
# Build part


# get start build date epoch 
start_build_date=$(date +"%s")
# make temp trap dir for all tmp files on build.
TMP_BUILD_DIR=$(mktemp -d $ROOT/tmp/make.buildpkg-tmp-build-XXXXXX)
trap "rm -rf $TMP_BUILD_DIR" EXIT

# make temp trap dir for all tmp files on build.
TMP_BUILD_DIR=$(mktemp -d /tmp/make.buildpkg-tmp-build-XXXXXX)

SKIP_CHECK_COMPILATION_TOOLS=1
if [ $SKIP_CHECK_COMPILATION_TOOLS -eq 1 ] ; then echo "Skipping check compilation tools." ; else 

  # Check for needed tools to build the pkg
  echo "Checking for needed tools."
  # ex: mkdir cp find grep tar ...
fi
SKIP_EXTRACTING_SOURCES=0
if [ $SKIP_EXTRACTING_SOURCES -eq 1 ] ; then echo "Skipping extracting sources." ; else 
  echo "Extracting/Preparing sources."
  cd $BUILDDIR || exit 1
  # Clean build dir.
  if [ -d $BUILDDIR ] ; then rm -rf $BUILDDIR/* ; fi || exit 1
EOF_OUTBUILD
echo '  tar xvf $SOURCESDIR'/$file1' || exit 1' >> $OUTBUILD 
cat << 'EOF_OUTBUILD' >> $OUTBUILD
fi
SKIP_CONFIG=1
if [ $SKIP_CONFIG -eq 1 ] ; then echo "Skipping configure sources." ; else 
  # Apply patches here.
  echo "Applying patches."

  #echo "Configuring sources."

fi  
SKIP_BUILD=1
if [ $SKIP_BUILD -eq 1 ] ; then echo "Skipping build sources." ; else 
  echo "Compiling sources."

fi
SKIP_INSTALL_SOURCES=0
if [ $SKIP_INSTALL_SOURCES -eq 1 ] ; then echo "Skipping installing sources." ; else 
  echo "Installing sources on pkg dir."
  echo "  Cleaning $PKGDIR"
  if [ -d $PKGDIR ] ; then rm -rf $PKGDIR/* ; fi || exit 1
  cd $BUILDDIR
  cp -rv * $PKGDIR
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  cd $PKGDIR

  # Post compilation
  #echo "Post compilation tasks."

  # strip ELF
  #find $PKGDIR | xargs file | grep "ELF.*executable" | cut -f 1 -d : \
  #             | xargs strip --strip-unneeded 2> /dev/null
  
  # extract /pkg shared-libs dir to temp file, and cat in base64 when contruct the pkg script.
  echo "Find ELF files and extract needed shared libs"
  TMP_PKG_SHAREDLIBS_FILE=$TMP_BUILD_DIR/tmp.sharedlibs.$pkg_name
  trap "rm -f $TMP_PKG_SHAREDLIBS_FILE" EXIT
  cd $PKGDIR
  find . -type f -executable -exec objdump -p "{}" 2>/dev/null \; | grep -E "^./|NEEDED" |\
    # change ': file format elf64-x86-64' to :
    sed -e 's/:.*$/:/' |\
    # remove new lines
    tr -d '\n' |\
    # remove more than one space
    tr -s ' ' |\
    # change first ': NEEDED ' with :
    sed 's/: NEEDED /:/g'|\
    # change ' NEEDED ' for ,
    sed 's/ NEEDED /,/g' |\
    # add new line and ./ when find ./
    sed 's/\.\//\n.\//g' |\
    # remove first black line and add \n at end
    awk 'NF' |\
    sort -u > $TMP_PKG_SHAREDLIBS_FILE

  # inspect where the pkg installed
  #cd $PKGDIR
  #ls -la .
fi
# get end build date epoch
end_build_date=$(date +"%s")
echo "START:$start_build_date END:$end_build_date"
build_time=$(($end_build_date - $start_build_date))
echo "Sources build time: $build_time seconds" 
TMP_PKG_BUILDTIME_FILE=$TMP_BUILD_DIR/tmp.buildtime.$pkg_name
echo "Sources build time: $build_time" > $TMP_PKG_BUILDTIME_FILE
EOF_OUTBUILD

# Building pkg.sh. $OUTPKG
cat << 'EOF_OUTBUILD' >> $OUTBUILD
echo ""
SKIP_PACKAGING=0
if [ $SKIP_PACKAGING -eq 1 ] ; then echo "Skipping the packaging." ; else
  #Packaging.
  echo "Packaging"
  # Start build pkg_name.sh
  echo "#!/bin/bash" > $OUTPKG
  # Copy script header to pkg.
  sed -n '/^# --- LICENSE ---$/,/^# --- END CAT SEED ---$/p' $SWD/$file_name_no_path >> $OUTPKG
  
  cat << 'EOF_OUTPKG' >> $OUTPKG
  if [ $# -eq 0 ]; then USAGE=1 ; fi
  while [ $# -gt 0 ] ; do
    case $1 in
      install) INSTALL=1 ; shift $# 
        ;;
      compare) COMPARE=1 ; shift $#
        ;;
      list) LIST=1 ; shift $#
        ;;
      remove) REMOVE=1 ; shift $#
        ;;
      verbose) VERBOSE=1 ; shift $#
        ;;
      checksum) CHECKSUM=1 ; shift $#
        ;;
      echo) ECHO=1 ; shift $#
        ;;
      shared) LISTSHARED=1 ; shift $#
        ;;
      epoch) EPOCH=1 ; shift $#
        ;;
      *) USAGE=1 ; shift $#
        ;;
    esac 
  done
  if [[ $USAGE -eq 1 ]] ; then
    echo "USAGE: pkg.sh list"
    echo "       pkg.sh verbose"
    echo "       pkg.sh compare"
    echo "       pkg.sh install"
    echo "       pkg.sh remove"
    echo "       pkg.sh shared"
    echo "       pkg.sh checksum"
    echo "       pkg.sh epoch"
    echo "       pkg.sh echo"
    echo "       INSTALLDIR=/foo pkg.sh install"
    exit 1
  fi
  
EOF_OUTPKG
  
  cd $PKGDIR
  # Tar and compress files in current dir and copy it in b64 to package script.
  # Thanks to https://reproducible-builds.org/docs/archives/ 
  # requires GNU Tar 1.28+
  echo "compresed_tar_xz_pkg_b64='$(tar --sort=name \
      --mtime="@${SOURCE_DATE_EPOCH}" \
      --owner=0 --group=0 --numeric-owner \
      --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
      -Jcf - * | base64)'" >> $OUTPKG
  echo "# --- END TAR FILE ---" >> $OUTPKG
  # Cat temp sharedlibs file in b64 to package script.
  echo "shared_libs_b64='$(cat $TMP_PKG_SHAREDLIBS_FILE | base64)'" >> $OUTPKG
  #rm $TMP_PKG_SHAREDLIBS_FILE
  # Cat checksums file in b64 to package script.
  echo "checksums_b64='$(cat $TMP_PKG_CHECKSUMS_FILE | base64)'" >> $OUTPKG
  #rm $TMP_PKG_CHECKSUMS_FILE

  # Source date epoch from buildpkg to have reference to reproduce.
  echo "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH" >> $OUTPKG
  
cat << 'EOF_OUTPKG' >> $OUTPKG
  INSTALLDIR=${INSTALLDIR:-/}
  cd $INSTALLDIR || exit 1
  LOGDIR="$INSTALLDIR/var/log"
  LOGFILE="$LOGDIR/make.buildpkg.log"
  PKG_DB="$INSTALLDIR/pkg/installed"
  PKG_DIR="$PKG_DB/$pkg_name"
  TMP_PKG_DIR=$(mktemp -d $ROOT/tmp/make.buildpkg-tmp-pkg-XXXXXX)
  trap "rm -rf $TMP_PKG_DIR" EXIT
  # pkg installed files
  PKG_INDEX_FILE="$PKG_DIR/index"
  # pkg shared libs
  PKG_SHAREDLIBS_FILE="$PKG_DIR/needed-libs"
  # pkg checksums
  PKG_CHECKSUMS_FILE="$PKG_DIR/checksums"
  # Tar exclude-from file.
  TAR_EXCLUDE_FROM=${TAR_EXCLUDE_FROM:-/pkg/config}
  
  if [[ $INSTALL -eq 1 ]] ; then 
    [ -d $PKG_DIR ] || mkdir -p $PKG_DIR 
    [ -d $LOGDIR ] || mkdir -p $LOGDIR 
    # check write on log file 
    if [ -w $LOGFILE ] ; then true ; else touch $LOGFILE || exit 1 ; fi
    # check write on PKG_INDEX_FILE
    echo "Updating pkg.db files for this package."
    # echo sharedlibs  to package db.
    echo "$shared_libs_b64" | base64 -d > $PKG_SHAREDLIBS_FILE
    # update pkg index
    echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jtf - | sort > $PKG_INDEX_FILE
    echo "Installing files in $INSTALLDIR"
    echo "Decoding b64 package files."
      # --keep-directory-symlink Don't replace existing symlinks to directories when extracting.
      # tested tar (GNU tar) 1.35 || exit
      echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jxvf - --keep-directory-symlink --exclude-from=$TAR_EXCLUDE_FROM
    echo "$(date) Installed $pkg_name in $INSTALLDIR" >> $LOGFILE 
  elif [[ $COMPARE -eq 1 ]] ; then
    echo "Comparing pkg with files in $INSTALLDIR"
    # Compare tar with filesystem (only files, dirs and links not work)
    echo "Decoding b64 package files."
    echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jdf - | sed 's/^/  /' 
  elif [[ $LIST -eq 1 ]] ; then
    echo "Decoding b64 package files."
    echo "Listing pkg files."
    echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jtf - | sed 's/^/  /' 
  elif [[ $VERBOSE -eq 1 ]] ; then
    echo "Listing pkg files."
    echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jtvf - | sed 's/^/  /' 
  elif [[ $CHECKSUM -eq 1 ]] ; then
    echo "Checksum md5sum filesystem files."
    echo "$checksums_b64" | base64 -d 
  elif [[ $ECHO -eq 1 ]] ; then
    # exclude print pkg name version arch release
    echo "$compresed_tar_xz_pkg_b64" 
  elif [[ $LISTSHARED -eq 1 ]] ; then
    echo "Listing needed shared libs for this pkg."
    echo "$shared_libs_b64" | base64 -d 
  elif [[ $EPOCH -eq 1 ]] ; then
    echo "Source data epoch for this pkg."
    echo "$SOURCE_DATE_EPOCH"
  elif [[ $REMOVE -eq 1 ]] ; then
    # All needed files are all installed files + noremove - pkg_installed
    # to find files that are in other packages and can't remove.
    TMP_ALL_NEEDED_FILES=$TMP_PKG_DIR/make.buildpkg-all-needed-files.remove
    TMP_ALL_NEEDED_FILES_SORT=$TMP_PKG_DIR/make.buildpkg-all-needed-files-sort.remove
    TMP_FILES_TO_REMOVE=$TMP_PKG_DIR/make.buildpkg-files-to.remove
    # find all files installed
    find $PKG_DB -name "index" -not -path "*/$pkg_name/*" -exec cat {} \; | LC_ALL=POSIX sort > $TMP_ALL_NEEDED_FILES
    cat $TMP_ALL_NEEDED_FILES | LC_ALL=POSIX sort > $TMP_ALL_NEEDED_FILES_SORT
    # compare all files to pkg installed and get uniques no needed by third parties
    comm -23 $PKG_INDEX_FILE $TMP_ALL_NEEDED_FILES_SORT 2>/dev/null > $TMP_FILES_TO_REMOVE
    # need to do a dry run.
    # remove no needed files
    cat $TMP_FILES_TO_REMOVE | LC_ALL=POSIX sort -ru | while read line ; do
      if [ -f $line ] ; then 
        rm -v $line
      elif [ -d $line ] ; then 
        rmdir -v $line
      elif [ -h $line ] ; then
        rm -v $line
      fi
    done
    # remove pkg 
    rm -rf $PKG_DIR 2>/dev/null && echo "$(date) Removed $pkg_name in $INSTALLDIR" >> $LOGFILE
  fi
  rm -rf "$TMP_PKG_DIR"
  
  #echo ""
EOF_OUTPKG
  end_package_date=$(date +"%s")
  package_time=$(($end_package_date - $start_package_date))
  echo "Package time: $package_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Package time: $package_time seconds"

# Get builder end time and send to TIMINGS tmp file.
end_builder_date=$(date +"%s")
builder_time=$(($end_builder_date - $start_builder_date))
echo "Builder time: $builder_time" >> $TMP_PKG_TIMINGS_FILE 
echo "Builder time: $builder_time seconds"
#cat $TMP_PKG_TIMINGS_FILE

if [ $METADATA -eq 1 ] ; then echo "Skipping store METADATA files." ; else 
  # pkg master key
  PKG_MASTERKEY_FILE="$METADATADIR/pkg_masterkey"
  echo "Package Checsum Masterkey: $(md5sum $TMP_PKG_CHECKSUMS_FILE | cut -d' ' -f1) " > $PKG_MASTERKEY_FILE
  # pkg build timings
  PKG_TIMINGS_FILE="$METADATADIR/timings"
  cat $TMP_PKG_TIMINGS_FILE > $PKG_TIMINGS_FILE
fi

# Remove tmp dir 
rm -rf "$TMP_METADATA_DIR"
  
  echo "Created: $OUTPKG"
fi
EOF_OUTBUILD

# Store md5sum of the OUTBUILD builder script to repository metadata.
BUILDER_CHECKSUM_FILE="$METADATADIR/builder_checksum"
md5sum  $OUTBUILD > $BUILDER_CHECKSUM_FILE
echo "Created: $OUTBUILD"
