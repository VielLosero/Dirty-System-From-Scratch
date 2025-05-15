#!/bin/bash
#
# https://wiki.archlinux.org/title/QEMU#Using_any_real_partition_as_the_single_primary_partition_of_a_hard_disk_image
#
#Using the device-mapper
#
#A method that is similar to the use of a VMDK descriptor file uses the device-mapper to prepend a loop device attached to the MBR file to the target partition. In case we do not need our virtual disk to have the same size as the original, we first create a file to hold the MBR:
#
#$ dd if=/dev/zero of=/path/to/mbr count=2048
#
#Here, a 1 MiB (2048 * 512 bytes) file is created in accordance with partition alignment policies used by modern disk partitioning tools. For compatibility with older partitioning software, 63 sectors instead of 2048 might be required. The MBR only needs a single 512 bytes block, the additional free space can be used for a BIOS boot partition and, in the case of a hybrid partitioning scheme, for a GUID Partition Table. Then, we attach a loop device to the MBR file:
#
## losetup --show -f /path/to/mbr
#
#/dev/loop0
#
#In this example, the resulting device is /dev/loop0. The device mapper is now used to join the MBR and the partition:
#
## echo "0 2048 linear /dev/loop0 0
#2048 `blockdev --getsz /dev/hdaN` linear /dev/hdaN 0" | dmsetup create qemu
#
#The resulting /dev/mapper/qemu is what we will use as a QEMU raw disk image. Additional steps are required to create a partition table (see the section that describes the use of a linear RAID for an example) and boot loader code on the virtual disk (which will be stored in /path/to/mbr).
#
#The following setup is an example where the position of /dev/hdaN on the virtual disk is to be the same as on the physical disk and the rest of the disk is hidden, except for the MBR, which is provided as a copy:
#
## dd if=/dev/hda count=1 of=/path/to/mbr
## loop=`losetup --show -f /path/to/mbr`
## start=`blockdev --report /dev/hdaN | tail -1 | awk '{print $5}'`
## size=`blockdev --getsz /dev/hdaN`
## disksize=`blockdev --getsz /dev/hda`
## echo "0 1 linear $loop 0
#1 $((start-1)) zero
#$start $size linear /dev/hdaN 0
#$((start+size)) $((disksize-start-size)) zero" | dmsetup create qemu
#
#The table provided as standard input to dmsetup has a similar format as the table in a VMDK descriptor file produced by VBoxManage and can alternatively be loaded from a file with dmsetup create qemu --table table_file. To the virtual machine, only /dev/hdaN is accessible, while the rest of the hard disk reads as zeros and discards written data, except for the first sector. We can print the table for /dev/mapper/qemu with dmsetup table qemu (use udevadm info -rq name /sys/dev/block/major:minor to translate major:minor to the corresponding /dev/blockdevice name). Use dmsetup remove qemu and losetup -d $loop to delete the created devices.
#
#A situation where this example would be useful is an existing Windows XP installation in a multi-boot configuration and maybe a hybrid partitioning scheme (on the physical hardware, Windows XP could be the only operating system that uses the MBR partition table, while more modern operating systems installed on the same computer could use the GUID Partition Table). Windows XP supports hardware profiles, so that that the same installation can be used with different hardware configurations alternatingly (in this case bare metal vs. virtual) with Windows needing to install drivers for newly detected hardware only once for every profile. Note that in this example the boot loader code in the copied MBR needs to be updated to directly load Windows XP from /dev/hdaN instead of trying to start the multi-boot capable boot loader (like GRUB) present in the original system. Alternatively, a copy of the boot partition containing the boot loader installation can be included in the virtual disk the same way as the MBR. 



## How to make my mbr to mount a partition on qemu.

#  VIRTUAL_MBR=/tmp/virtual/mbr
#  mkdir -vp /tmp/virtual
#  #dd if=/dev/zero of=/path/to/mbr count=2048
#  dd if=/dev/zero of=$VIRTUAL_MBR count=2048
#  
#  #Here, a 1 MiB (2048 * 512 bytes) file is created in accordance with partition alignment policies used by modern disk partitioning tools. For compatibility with older partitioning software, 63 sectors instead of 2048 might be required. The MBR only needs a single 512 bytes block, the additional free space can be used for a BIOS boot partition and, in the case of a hybrid partitioning scheme, for a GUID Partition Table. Then, we attach a loop device to the MBR file:
#  
#  LOOP=$(losetup --show -f $VIRTUAL_MBR || exit 1)
#  echo $LOOP
#  /dev/loop0
#
#  [root@arcadia virtual]# losetup
#  NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE        DIO LOG-SEC
#  /dev/loop0         0      0         0  0 /tmp/virtual/mbr   0     512
#  [root@arcadia virtual]#
#  
#  #In this example, the resulting device is /dev/loop0. The device mapper is now used to join the MBR and the partition:
#  
#  # WARNING need to send as 2 lines to work.
#  #echo "0 2048 linear /dev/loop0 0
#  #2048 `blockdev --getsz /dev/hdaN` linear /dev/hdaN 0" | dmsetup create qemu
#  
#  # WARNING need to send as 2 lines to work.
#  echo "0 2048 linear /dev/loop0 0
#  2048 $(blockdev --getsz /dev/sda4) linear /dev/sda4 0" | dmsetup create qemu


#After cp the mbr to a file 
# get first free loop device
LOOP=$(losetup -f)
echo $LOOP

# mount mbr file as loop
losetup -f /home/data/git-repos/vielLosero/make.buildpkg.dirty.current/mbr.for.hdd.sda4.loop.qemu.device.mapper
# WARNING need to send as 2 lines to work.
echo "0 2048 linear $LOOP 0
2048 $(blockdev --getsz /dev/sda4) linear /dev/sda4 0" | dmsetup create qemu

#[root@arcadia test]# dmsetup ls
#lukssdb3        (252:0)
#qemu    (252:1)
#[root@arcadia test]#

#[root@arcadia test]# dmsetup info qemu
#Name:              qemu
#State:             ACTIVE
#Read Ahead:        256
#Tables present:    LIVE
#Open count:        0
#Event number:      0
#Major, minor:      252, 1
#Number of targets: 2
#
#[root@arcadia test]#

#[root@arcadia test]# dmsetup status qemu
#0 2048 linear
#2048 713031680 linear
#[root@arcadia test]#

#[root@arcadia test]# dmsetup deps qemu
#2 dependencies  : (8, 4) (7, 0)
#[root@arcadia test]# dmsetup table qemu
#0 2048 linear 7:0 0
#2048 713031680 linear 8:4 0
#[root@arcadia test]# lsblk
#NAME         MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
#loop0          7:0    0     1M  0 loop
#└─qemu       252:1    0   340G  0 dm
#sda            8:0    0 931.5G  0 disk
#├─sda1         8:1    0   260M  0 part
#├─sda2         8:2    0   100G  0 part
#├─sda3         8:3    0 346.9G  0 part
#└─sda4         8:4    0   340G  0 part
#  └─qemu     252:1    0   340G  0 dm
#  sdb            8:16   0 447.1G  0 disk
#
#[root@arcadia test]# dmsetup remove qemu
#
