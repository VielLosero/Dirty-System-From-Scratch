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
#  and The GLFS Development Team 2024-2025 as part of project Linux From Scratch
#  and derivates like MLFS and are provided under the MIT license.
#
# --- END LICENSE ---

#:Maintainer: Viel Losero <viel.losero@gmail.com>
#:Contributor: -

#:Version:0.0.4

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
short_desc="The X.Org Libinput Driver is a thin wrapper around libinput and allows for libinput to be used for input devices in X. This driver can be used as drop-in replacement for evdev and synaptics."
url="https://gitlab.freedesktop.org/xorg/driver/xf86-input-libinput"
license=""
# prevent empty var.
if [ -z $pkg_name ] ; then exit 1 ; fi

# Master vars.
ROOT=${ROOT:-} ; TMP="$ROOT/tmp"
REPODIR=${REPODIR:-/pkg/repository}
METADATADIR="${METADATADIR:-/pkg/metadata/$first_pkg_char/${name}/${pkg_name}}"
DIST=${DIST:-dirty} ; DISTVER=${DISTVER:-0.0}
SOURCESDIR=${SOURCESDIR:-$TMP/$DIST-$DISTVER/sources-all}
SOURCESPPDIR=${SOURCESPPDIR:-$TMP/$DIST-$DISTVER/sources-per-package/$name-$ver}
BUILDDIR=${BUILDDIR:-$TMP/$DIST-$DISTVER/build/$pkg_name}
PKGDIR=${PKGDIR:-$TMP/$DIST-$DISTVER/pkgfiles/$pkg_name}
OUTBUILD=${OUTBUILD:-$REPODIR/$DIST-$DISTVER/builders/$first_pkg_char/${name}/${build_pkg_name}.sh}
OUTPKG=${OUTPKG:-$REPODIR/$DIST-$DISTVER/packages/$first_pkg_char/${name}/${pkg_name}.sh}

# Other need vars for example to change the default INSTALLDIR=$LFS.
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
# As with previous releases of the X Window System, it may be desirable to install Xorg into an alternate prefix. This is no longer common practice among Linux distributions. The common installation prefix for Xorg on Linux is /usr. There is no standard alternate prefix, nor is there any exception in the current revision of the Filesystem Hierarchy Standard for Release 7 of the X Window System. Alan Coopersmith of Sun Microsystems, once stated "At Sun, we were using /usr/X11 and plan to stick with it." Only the /opt/* prefix or the /usr prefix adhere to the current FHS guidelines.
# The BLFS editors recommend using the /usr prefix.
# Choose your installation prefix, and set the XORG_PREFIX variable with the following command:
# export XORG_PREFIX="<PREFIX>"
XORG_PREFIX="/usr"
docdir="--docdir=$XORG_PREFIX/share/doc/$name-$ver"
#Xorg_environment https://www.linuxfromscratch.org/blfs/view/stable/x/xorg7.html#xorg-env
XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
#export XORG_PREFIX XORG_CONFIG

# --- END CAT SEED ---
 
# Config get tool.
if wget --help >/dev/null 2>&1 ; then GETVER="wget --output-document - --quiet" GETFILE="wget -c " SPIDER="wget -q --method=HEAD"
elif curl --help >/dev/null 2>&1 ; then GETVER="curl --connect-timeout 20 --silent" GETFILE="curl -C - -O --silent" SPIDER="curl -L --head --fail --silent"
else echo "Needed wget or curl to download files or check for new versions." && exit 1 ; fi

# Package vars.
version_url=https://www.x.org/archive/individual/driver
sum="sha256sum"
file1_url=$version_url
file1=$name-$ver.tar.xz
file1_sum=2524c35f196554ea11aef3bba1cf324759454e1d49f98ac026ace2f6003580e6
file2_url=$file1_url
file2=${file1}.sig
file2_sum=7399ab82edeccfb8c5e67b2777d5614ab860353f0b2cc7d4c0aa6fb1c8937f47
xcb_util_gpgkey=67DC86F2623FC5FD4BB5225D14706DBE1E4B4540 

# Check for new releases.
CHECK_RELEASE=${CHECK_RELEASE:-0}
NEW=${NEW:-1}
if [ $CHECK_RELEASE = 1 ] ; then 
  last_version=$(echo "$($GETVER $version_url)" | tr ' ' '\n' | grep href.*${name}-[0-9].*[0-9].tar.*z\" | cut -d'"' -f2 | sort -V | tail -1 | sed 's/.tar.*//' | cut -d'-' -f4 )
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
            cp $0 $NEWMAKE && echo "Created: $NEWMAKE" || exit 1 ; exit 2
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
[ ! -e $file1 ] && $GETFILE ${file1_url}/${file1}
[ -e $file1 ] && if echo "$file1_sum $file1" | $sum -c ; then ln -v $SOURCESDIR/$file1 $SOURCESPPDIR/ ; else $sum $file1 ; exit 1 ; fi
[ ! -e $file2 ] && $GETFILE ${file2_url}/${file2}
[ -e $file2 ] && if echo "$file2_sum $file2" | $sum -c ; then ln -v $SOURCESDIR/$file2 $SOURCESPPDIR/ ; else $sum $file2 ; exit 1 ; fi

# Check signaure if needed
gpg --keyserver hkps://keyserver.ubuntu.com --receive-keys $xcb_util_gpgkey
gpg --verify $file2 $file1 || exit 1

# Prepare sources or patches.
echo "Preparing sources."
cd $SOURCESPPDIR || exit 1
# Do something if needed.

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

# Cat to builder the build sources part.
cat << 'EOF_OUTBUILD' >> $OUTBUILD
# Build part
if [ $CHECK -eq 1 ] ; then echo "Skipping CHECK tasks." ; else
  # Check tasks needed to build.
  start_checks_date=$(date +"%s")
  echo "Checking needs to build."
  # --- LFS_CMD_CHECKS ---
  # --- END_LFS_CMD_CHECKS ---
  end_checks_date=$(date +"%s")
  checks_time=$(($end_checks_date - $start_checks_date))
  echo "Checks time: $checks_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Checks time: $checks_time seconds" 
fi

if [ $EXTRACT -eq 1 ] ; then echo "Skipping EXTRACT sources." ; else
  # Extracting sources.
  start_extract_date=$(date +"%s")
  echo "Preparing sources."
  cd $BUILDDIR || exit 1
  # deleting source dirs if exist.
  if [ -d $name-$ver ] ; then rm -rf $name-$ver ; fi
  if [ -d $PKGDIR ] ; then rm -rf $PKGDIR && mkdir $PKGDIR ; fi
EOF_OUTBUILD
  echo '  tar xf $SOURCESDIR'/$file1 >> $OUTBUILD 
  cat << 'EOF_OUTBUILD' >> $OUTBUILD
  cd $name-$ver || exit 1
  # --- LFS_CMD_EXTRACT ---
  # --- END_LFS_CMD_EXTRACT ---
  end_extract_date=$(date +"%s")
  extract_time=$(($end_extract_date - $start_extract_date))
  echo "Extract time: $extract_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Extract time: $extract_time seconds" 
fi
  
if [ $PATCH -eq 1 ] ; then echo "Skipping PATCH sources." ; else 
  # Apply patches here.
  start_patch_date=$(date +"%s")
  echo "Applying patches."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_PATCH ---
  # --- END_LFS_CMD_PATCH ---
  end_patch_date=$(date +"%s")
  patch_time=$(($end_patch_date - $start_patch_date))
  echo "Patch time: $patch_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Patch time: $patch_time seconds" 
fi
  
if [ $CONFIG -eq 1 ] ; then echo "Skipping CONFIG sources." ; else 
  # ./configure here.
  start_config_date=$(date +"%s")
  echo "Configuring sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_CONFIG ---
  ./configure $XORG_CONFIG || exit 1
  # --- END_LFS_CMD_CONFIG ---
  end_config_date=$(date +"%s")
  config_time=$(($end_config_date - $start_config_date))
  echo "Sources config time: $config_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources config time: $config_time seconds"
fi

if [ $BUILD -eq 1 ] ; then echo "Skipping BUILD sources." ; else 
  start_build_date=$(date +"%s")
  echo "Compiling sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_BUILD ---
  NUMJOBS="-j $(nproc)"
  make $NUMJOBS || exit 1
  # --- END_LFS_CMD_BUILD ---
  end_build_date=$(date +"%s")
  build_time=$(($end_build_date - $start_build_date))
  echo "Sources build time: $build_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources build time: $build_time seconds"
fi

if [ $INSTALL -eq 1 ] ; then echo "Skipping INSTALL sources." ; else 
  start_install_date=$(date +"%s")
  #Installing sources.
  echo "Installing sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_INSTALL ---
  DESTDIR=$PKGDIR make install || exit 1
  # --- END_LFS_CMD_INSTALL ---
  end_install_date=$(date +"%s")
  install_time=$(($end_install_date - $start_install_date))
  echo "Sources install time: $install_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources install time: $install_time seconds"
fi  

if [ $POST -eq 1 ] ; then echo "Skipping POST compilation tasks." ; else 
  # Post compilation
  start_post_date=$(date +"%s")
  echo "Post compilation tasks."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_POST ---
  # --- END_LFS_CMD_POST ---
  end_post_date=$(date +"%s")
  post_time=$(($end_post_date - $start_post_date))
  echo "Post compilation tasks time: $post_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Post compilation tasks time: $post_time seconds"
fi
  
if [ $CONFIG32 -eq 1 ] ; then echo "Skipping CONFIG32 bits sources." ; else 
  # ./configure here.
  start_config32_date=$(date +"%s")
  echo "Configuring 32bits sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_CONFIG32 ---
  # --- END_LFS_CMD_CONFIG32 ---
  end_config32_date=$(date +"%s")
  config32_time=$(($end_config32_date - $start_config32_date))
  echo "Sources config32 time: $config32_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources config32 time: $config32_time seconds"
fi

if [ $BUILD32 -eq 1 ] ; then echo "Skipping BUILD32 bits sources." ; else 
  start_build32_date=$(date +"%s")
  echo "Compiling 32bits sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_BUILD32 ---
  # --- END_LFS_CMD_BUILD32 ---
  end_build32_date=$(date +"%s")
  build32_time=$(($end_build32_date - $start_build32_date))
  echo "Sources build32 time: $build32_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources build32 time: $build32_time seconds"
fi

if [ $INSTALL32 -eq 1 ] ; then echo "Skipping INSTALL32 bits sources." ; else 
  #Installing sources.
  start_install32_date=$(date +"%s")
  echo "Installing 32bits sources."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_INSTALL32 ---
  # --- END_LFS_CMD_INSTALL32 ---
  end_install32_date=$(date +"%s")
  install32_time=$(($end_install32_date - $start_install32_date))
  echo "Sources install32 time: $install32_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources install32 time: $install32_time seconds"
fi

if [ $POST32 -eq 1 ] ; then echo "Skipping POST32 bits compilation tasks." ; else 
  # Post compilation 32bits
  start_post32_date=$(date +"%s")
  echo "Post compilation 32bits tasks."
  cd $BUILDDIR || exit 1
  cd $name-$ver || exit 1
  # --- LFS_CMD_POST32 ---
  # --- END_LFS_CMD_POST32 ---
  end_post32_date=$(date +"%s")
  post32_time=$(($end_post32_date - $start_post32_date))
  echo "Post compilation 32bits tasks time: $post32_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Post compilation 32bits tasks time: $post32_time seconds"
fi

if [ $STRIP -eq 1 ] ; then echo "Skipping STRIP elf." ; else 
  # strip ELF
  start_strip_date=$(date +"%s")
  find $PKGDIR | xargs file | grep "ELF.*executable" | cut -f 1 -d : \
               | xargs strip --strip-unneeded 2> /dev/null
  end_strip_date=$(date +"%s")
  strip_time=$(($end_strip_date - $start_strip_date))
  echo "Sources strip time: $strip_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Sources strip time: $strip_time seconds"
fi
  
if [ $SHARED -eq 1 ] ; then echo "Skipping find SHARED libs." ; else 
  # extract /pkg shared-libs dir to temp file, to cat in base64 when contruct the pkg script.
  start_shared_date=$(date +"%s")
  echo "Find ELF files and extract needed shared libs"
  trap "rm -f $TMP_PKG_SHAREDLIBS_FILE" EXIT
  cd $PKGDIR
  find . -type f -executable -exec objdump -p "{}" 2>/dev/null \; |\
    grep NEEDED | sed 's/ *NEEDED *\(l.*\)/\1/' | LC_ALL=POSIX sort -u > $TMP_PKG_SHAREDLIBS_FILE
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
    LC_ALL=POSIX sort -u > $TMP_PKG_SHAREDLIBS_FILE
  end_shared_date=$(date +"%s")
  shared_time=$(($end_shared_date - $start_shared_date))
  echo "Find shared time: $shared_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Find shared time: $shared_time seconds"
fi

if [ $CHECKSUM -eq 1 ] ; then echo "Skipping CHECKSUM files." ; else 
  # Get CHECKSUM of all files in $PKGDIR.
  # WARNING: Dont put files with timestamps that can broke the checksum.
  start_checksum_date=$(date +"%s")
  cd $PKGDIR || exit 1
  #ls -la .
  if locale -a | grep POSIX >/dev/null ; then
    find . -type f -exec md5sum {} \; | LC_ALL=POSIX sort > $TMP_PKG_CHECKSUMS_FILE
    # Master md5
    echo "Master MD5:  $(md5sum $TMP_PKG_CHECKSUMS_FILE) "
  else
    echo "Locale POSIX not found" && exit 1
  fi
  end_checksum_date=$(date +"%s")
  checksum_time=$(($end_checksum_date - $start_checksum_date))
  echo "Checksum pkg files time: $checksum_time" >> $TMP_PKG_TIMINGS_FILE
  echo "Checksum pkg files time: $checksum_time seconds"
fi

EOF_OUTBUILD

# Cat to Builder the package pkg.sh. $OUTPKG part.
cat << 'EOF_OUTBUILD' >> $OUTBUILD
if [ $PACKAGE -eq 1 ] ; then echo "Skipping PACKAGE." ; else
  #Packaging.
  start_package_date=$(date +"%s")
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
  # and https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html
  # requires GNU Tar 1.28+
  echo "compresed_tar_xz_pkg_b64='$( LC_ALL=POSIX tar --sort=name \
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
  TAR_EXCLUDE_FROM=${TAR_EXCLUDE_FROM:-/pkg/config/tar-exclude-from-file.txt}
  
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
    echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jtf - | LC_ALL=POSIX sort > $PKG_INDEX_FILE
    echo "Installing files in $INSTALLDIR"
    echo "Decoding b64 package files."
      # --keep-directory-symlink Don't replace existing symlinks to directories when extracting.
      # tested tar (GNU tar) 1.35 || exit
      echo "$compresed_tar_xz_pkg_b64" | base64 -d | tar -Jxvf - --keep-directory-symlink --exclude-from=$TAR_EXCLUDE_FROM
    echo "$(date +"%a %b %d %T %Z %Y") Installed $pkg_name in $INSTALLDIR" >> $LOGFILE 
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
    LC_ALL=POSIX comm -23 $PKG_INDEX_FILE $TMP_ALL_NEEDED_FILES_SORT 2>/dev/null > $TMP_FILES_TO_REMOVE
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
    rm -rf $PKG_DIR 2>/dev/null && echo "$(date +"%a %b %d %T %Z %Y") Removed $pkg_name in $INSTALLDIR" >> $LOGFILE
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
