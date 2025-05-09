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

# needed dirs
ROOT=${ROOT:-}
TMP="$ROOT/tmp"
REPODIR=${REPODIR:-$ROOT/pkg}
DIST=${DIST:-dirty} ; DISTVER=${DISTVER:-0.1}
TMPDIR=${TMPDIR:-$TMP/$DIST-$DISTVER}
WORKDIR="$TMPDIR/mnt"
# take only packages and not all repo for make disk size
REPO_PKG_DIR=${REPO_PKG_DIR:-$REPODIR/repository/$DIST-$DISTVER/packages}
REPO_TOOLS_DIR=${REPO_TOOLS_DIR:-$REPODIR/tools}
REPO_INSTALLED_DIRS=${REPO_INSTLLED_DIRS:-$REPODIR/installed}
#REPO_SIZE=$(du -sc $REPO_PKG_DIR | tail -1)
#TMP_DISK_SIZE=$(echo $REPO_SIZE | cut -d " " -f 1)
#DISK_SIZE=$(echo "($TMP_DISK_SIZE/1000/1000)+1" | bc ) # +1G
DISK_SIZE=15 #GB
IMGFILE="dirty-0.1.server.img"
# from where install packages

[ -d $TMPDIR] || mkdir -vp $TMPDIR

# make img if not here
if [ ! -e $TMPDIR/$IMGFILE ] ; then 
  echo "[*] Creating $TMPDIR/$IMGFILE with size ${DISK_SIZE}GB"
  fallocate -l ${DISK_SIZE}G $TMPDIR/$IMGFILE 
fi
if [ -e $TMPDIR/$IMGFILE ] ; then 
  echo "[-] file exist."
  if fdisk -l $TMPDIR/$IMGFILE | grep $TMPDIR/${IMGFILE}1 >/dev/null ; then
    echo "[-] Partition exist."
  else
    # make new partition full disk 
    echo "[*] Partitioning $IMGFILE"
    printf 'o\nn\np\n1\n\n\nw\n' | fdisk "$TMPDIR/$IMGFILE"
  fi
else
  echo "[!] File disk not found!"
fi

# Mount and format image with loops
# ######################
# WARNING: Before run this script make sure you have no loops mounted on the sistem.
########################
LOOP0=$(lsblk | grep loop0 >/dev/null && echo 0 || echo 1)
LOOP0P1=$(lsblk | grep loop0p1 >/dev/null && echo 0 || echo 1)
LOOP1=$(lsblk | grep loop1 >/dev/null && echo 0 || echo 1)
MOUNTLOOP=$(lsblk | grep "$TMPDIR/mnt" > /dev/null  && echo 0 || echo 1)
#FSCHECK=$(fsck.ext4 /dev/loop1 > /dev/null && echo 0 || echo 1)
#if fsck.ext4 /dev/loop1  ; then FSCHECK=0 ; else FSCHECK=1 ; fi

if [ "$LOOP0" == "0" ] ; then
  echo "[-] loop0 exist!"
else
  #https://superuser.com/questions/130955/how-to-install-grub-into-an-img-file
  #(Note that if you want grub-mkconfig/update-grub to operate on this volume, then the partition loopback must be connected to the disk loopback under /dev, and not directly to the image file).
  #losetup /dev/loop0 $TMPDIR/$IMGFILE
  #kpartx -v -a /dev/loop0 && LOOP0=$(lsblk | grep loop0 >/dev/null && echo 0 || echo 1) \
  #Dont work too need to use e when grub boot to change dm-1 with sda1
  kpartx -v -a "$TMPDIR/$IMGFILE" && LOOP0=$(lsblk | grep loop0 >/dev/null && echo 0 || echo 1) \
  && LOOP0P1=$(lsblk | grep loop0p1 >/dev/null && echo 0 || echo 1)
fi

if [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "1" ] ; then
  echo "[!] No partition found!"
  exit 1
fi

if [ "$LOOP0P1" == "0" ] && [ "$LOOP1" == "1" ] ; then
  losetup /dev/loop1 /dev/mapper/loop0p1 && LOOP1=$(lsblk | grep loop1 >/dev/null && echo 0 || echo 1)
fi

if fsck.ext4 /dev/loop1  ; then FSCHECK=0 ; else FSCHECK=1 ; fi

if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$FSCHECK" == "1" ] && [ "$MOUNTLOOP" == "1" ] ; then 
    mkfs.ext4 /dev/mapper/loop0p1 && if fsck.ext4 /dev/loop1  ; then FSCHECK=0 ; else FSCHECK=1 ; fi
fi

if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$FSCHECK" == "0" ] && [ "$MOUNTLOOP" == "1" ] ; then 
    echo "[*] loops ok, file system ok, mounting file."
    [ ! -d "$TMPDIR/mnt" ] && mkdir -v "$TMPDIR/mnt"
    mount /dev/loop1 "$TMPDIR/mnt"
fi

MOUNTLOOP="$(lsblk | grep "$TMPDIR/mnt" > /dev/null  && echo 0 || echo 1)"

#################################################################################
# Install pckages
#if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$FSCHECK" == "1" ] && [ "$MOUNTLOOP" == "0" ] ; then 
if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$MOUNTLOOP" == "0" ] ; then 
  echo "[-] Mountpoint exist."

    #INSTALLDIR=$WORKDIR bash /home/data/git-repos/vielLosero/make.buildpkg/LFS_chroot/packages/lfschroot-0.0.1-all-1_LFS_r12.2_879_multilib.sh install

  # install packages on the new fs from local repo 
  cat $REPO_TOOLS_DIR/lists_of_packages/dirty-0.1_core_list.txt | grep -v "#" | while read line ; do 
    
    name="$(echo ${line%-[*})" #linux-mainline-[0-9]*_LFS_*
    #full_file_path=$(ls $REPO_PKG_DIR/*/*$line || ls -1 /home/data/git-repos/vielLosero/make.buildpkg/*LFS/packages/*$line ) 
    # get only the last update package.
    full_file_path=$(ls $REPO_PKG_DIR/*/$name/*$line | sort -Vr | head -1) 
    file_name_no_path=${full_file_path##*/}
    pkg_name="${file_name_no_path%.*}" 
    name="${pkg_name%-*-*-*}" 
    pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
    pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
    rel=${pkg_name/$name-$ver-$arch-/}
    first_pkg_char=$(printf %.1s ${name,})


    if [ ! -d $WORKDIR/pkg/installed/${pkg_name} ] ; then
    INSTALLDIR=$WORKDIR bash $full_file_path install
    # Comment the line below to omit md5sum and accelerate the installation.
    #echo "Keeping MD5Sum of files." && INSTALLDIR=$WORKDIR bash $full_file_path md5sum > $WORKDIR/pkg/installed/${pkg_name}/md5sum
      #echo " ------------> need install: $pkg_name "
    else 
      if [ -d $WORKDIR/pkg/installed/${pkg_name} ] ; then
        echo "$pkg_name INSTALLED."
      else
        echo "--> FAILED: $pkg_name"
      fi
    fi
  done

    #INSTALLDIR=$WORKDIR bash /home/data/git-repos/vielLosero/make.buildpkg/LFS/packages/linux-6.14_rc2-x86_64-1_LFS_r12.2_880_multilib.sh install


  ## if [ ! -d $WORKDIR/pkg/installed/make_buildpkg_dirty_package_manager-0.0.1-all-1 ] ; then
  ## INSTALLDIR=$WORKDIR bash $REPO_PKG_DIR/packages/m/make_buildpkg_dirty_package_manager-0.0.1-all-1.sh install
  ## fi
  ## if [ ! -d $WORKDIR/pkg/filesystem_hierarchy-3.0-all-1_LFS_r12.2_879_multilib ] ; then
  ## INSTALLDIR=$WORKDIR bash /home/data/git-repos/vielLosero/make.buildpkg/LFS_chroot/packages/filesystem_hierarchy-3.0-all-1_LFS_r12.2_879_multilib.sh install
  ## fi
  ## if [ ! -d $WORKDIR/pkg/lfschroot-0.0.1-all-1_LFS_r12.2_879_multilib ] ; then
  ## INSTALLDIR=$WORKDIR bash /home/data/git-repos/vielLosero/make.buildpkg/LFS_chroot/packages/lfschroot-0.0.1-all-1_LFS_r12.2_879_multilib.sh install
  ## fi

  ## # install LFS multilib packages
  ## for pkg in $(ls -1 /home/data/git-repos/vielLosero/make.buildpkg/LFS/packages/*multilib*.sh ) ; do 
  ##   pkg_name=${pkg##*/} 
  ##   pkg_name=${pkg_name%.sh}
  ##   if [ ! -d $WORKDIR/pkg/${pkg_name} ] ; then
  ##   INSTALLDIR=$WORKDIR bash $pkg install
  ##   else 
  ##     echo "$pkg_name INSTALLED."
  ##   fi
  ## done
  ## # install BLFS sysV packages
  ## for pkg in $(ls -1 /home/data/git-repos/vielLosero/make.buildpkg/BLFS/packages/*sysV*.sh ) ; do 
  ##   pkg_name=${pkg##*/} 
  ##   pkg_name=${pkg_name%.sh}
  ##   if [ ! -d $WORKDIR/pkg/${pkg_name} ] ; then
  ##   INSTALLDIR=$WORKDIR bash $pkg install
  ##   else 
  ##     echo "$pkg_name INSTALLED."
  ##   fi
  ## done

  
  #https://superuser.com/questions/130955/how-to-install-grub-into-an-img-file
  mkdir -p $WORKDIR/boot/grub
cat > $WORKDIR/boot/grub/device.map <<EOF
(hd0)   /dev/loop0
(hd0,1) /dev/loop1
EOF

  LFS=$WORKDIR  bash $REPO_TOOLS_DIR/lfs-chroot mount
  LFS=$WORKDIR bash $REPO_TOOLS_DIR/lfs-chroot /bin/bash <<END
  echo "------------> ENTERING CHROOT!!"
  #echo "grub-mkdevicemap"
  grub-mkconfig -o /boot/grub/grub.cfg
  sed -i 's%root=/dev/dm-1%root=/dev/sda1%g' /boot/grub/grub.cfg
  ln -s /usr/bin/vim /usr/bin/vi
  # make user for ssh 
  install -v -g sys -m700 -d /var/lib/sshd &&
  groupadd -g 50 sshd        &&
  useradd  -c 'sshd PrivSep' \
           -d /var/lib/sshd  \
           -g sshd           \
           -s /bin/false     \
           -u 50 sshd
  # Generate a key for sshd server.
  ssh-keygen -A
  chmod +x /etc/rc.d/init.d/sshd
  echo "------------> EXITING CHROOT!!"
END


  grub-install --no-floppy --modules="part_msdos" --target=i386-pc --grub-mkdevicemap=$WORKDIR/boot/grub/device.map --boot-directory=$WORKDIR/boot/ /dev/loop0 -v

  #(Beware that the post-installer of the grub-pc package will run a probe that overwrites the device map(!), so you'll have to write it after installation and run grub-mkconfig/update-grub yourself).
  mkdir -p $WORKDIR/boot/grub
cat > $WORKDIR/boot/grub/device.map <<EOF
(hd0)   /dev/loop0
(hd0,1) /dev/loop1
EOF

  echo "CHROOT  to change dm-1 with sda1 on grub.cfg and set up dhcp"
  LFS=$WORKDIR bash $REPO_TOOLS_DIR/lfs-chroot /bin/bash
  #CHROOT  to change dm-1 with sda1 on grub.cfg
  #chroot $WORKDIR /bin/bash 
  # then can check 
  #grub-probe --device /dev/loop1 --device-map=$WORKDIR/boot/grub/device.map --target=drive
  
  # fstab
  #echo "/dev/sda1        /                ext4         defaults         1   1" > $WORKDIR/etc/fstab
  #echo "/dev/sda1               /               ext4            rw,relatime     0 1" > $WORKDIR/etc/fstab
  cat > $WORKDIR/etc/fstab << 'EOF'
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/sda1               /               ext4            rw,relatime     0 1
#/dev/<xxx>     /              <fff>    defaults            1     1
#/dev/<yyy>     swap           swap     pri=1               0     0
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF
  
  
  LFS=$WORKDIR bash $REPO_TOOLS_DIR/lfs-chroot umount
  LFS=$WORKDIR bash $REPO_TOOLS_DIR/lfs-chroot umount
  #umount $WORKDIR/dev
  #umount $WORKDIR/sys
  #umount $WORKDIR/proc
  #umount $WORKDIR
  INSTALL_PKG=0

fi
#################################################################################

if [ "$INSTALL_PKG" == "0" ] ; then
  echo "[*] Install pkg finished."
  if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$MOUNTLOOP" == "0" ] ; then 
    umount "$TMPDIR/mnt" && MOUNTLOOP=$(lsblk | grep "$TMPDIR/mnt" > /dev/null  && echo 0 || echo 1)
  else
    echo "[!] Cant umount disk!"
  fi
  if [ "$LOOP1" == "0" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$MOUNTLOOP" == "1" ] ; then
    losetup -d /dev/loop1 && LOOP1=$(lsblk | grep loop1 >/dev/null && echo 0 || echo 1)
  else
    echo "[!] Cant umount loop1!"
  fi
  if [ "$LOOP1" == "1" ] && [ "$LOOP0" == "0" ] && [ "$LOOP0P1" == "0" ] && [ "$MOUNTLOOP" == "1" ] ; then 
    kpartx -d "$TMPDIR/$IMGFILE" && LOOP0=$(lsblk | grep loop0 >/dev/null && echo 0 || echo 1) \
    && LOOP0P1=$(lsblk | grep loop0p1 >/dev/null && echo 0 || echo 1)
  else
    echo "[!] Cant umount loop0!"
  fi
  if [ "$LOOP1" == "1" ] && [ "$LOOP0" == "1" ] && [ "$LOOP0P1" == "1" ] && [ "$MOUNTLOOP" == "1" ] ; then 
  #if [ "$CLEAN" == "0" ] ; then
    echo "[*] Slack temp repo in $TMPDIR/$IMGFILE"
  else
    echo "[!] Not clean exit!"
  fi
fi

