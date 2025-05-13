
## The Dirty system from scratch
This is the history about a the Make.Buildpkg concept and the Dirty system from scratch, and how I update and automate my LFS.
As a learning experience I started building a simple package manager for LFS. As I built it, I was thinking about how to make it more useful, easy and simple. Will it end up being a distribution? To know how it ends you need to continue reading.

## The concept beneath the chain make --> build --> package.
I am glad to present you: The maker, the builder and the package.
The concept was easy, make a builder that build a package that can be installed.

  maker --> builder --> package --> install it.

From sources to packages, it is for LFS users like me.
All in one place but not. In shell scripts but structured and managed.

Why not make a simple script to do all the job? Divide and conquest.
Because edit a file whit 5000 lines of source code inside are hard. So we need the maker.
Becasue not all people want to have the sources. Some people only need the packages to install it. So we need 3 scripts.
Wait, wait, sources inside? Yes.

### The maker script (make.buildpkg.pkg-ver-arch-rel.sh).
A maker script start with maker.buildpkg.
The maker is the script that download the sources and check for updates.
The maker make an other scripts, like new makers from new versions and builder scripts.
This maker script have all in one place: download the sources, check it, and make the builder script that build the package.
If you delete the builder and the package you can recreate it with the maker.
The headers of the maker take the script name as reference to set the variables to work, so updating only the name of the script will update the variables inside and download the according version of the new sources files. We only need to verify/update the checksum and signature of the sources downloaded.
```
# Get init data from filename.
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
```

### The builder script (buildpkg.pkg-ver-arch-rel.sh).
The builder is the script with the sources in base64, it extract and compile the sources and build the (pkg-ver-arch-rel.sh) script.
The builder have all the sources (tar.xz, tzr.xz.sig, patches) in one tar file coded in base64. If you want to rebuild a package with more or less build options that is your package. So you can copy the builder with your release name and edit the compile options to make your oun package easy (buildpkg.pkg-ver-arch-MY_RELEASE.sh).
If you want, the builder can only extract the sources. Each time the builder extract the sources do a checksum off the extracted or existent files.
You can grep the builder to get a sha256sum list of all the sources. Not all people that provide sources provide a sha256sum, some provide md5sum some other sha512. Lot of souces are signed. With te builder you can share easy with other people a sha256sum list of sources in same format.
Try:
```
bash-5.2# grep "sha256sum -c" /pkg/repository/dirty-0.1/builders/*/*/* | cut -d' ' -f2-4 | sort -k2
```

#### Why did you put the sources in a shell script?

Structuring thinks like that:
 - you don't need to seach where the sources are.
 - you have the checksum within the same file.
 - The builder with the sources are easy reproducible.
 - you sign it and it is build always same.
 - and more that you can love or hate. Will see ...

#### How did you put the sources in a shell script?
Coded in base64. If you know a best way point me please.
The size of the files increase a litlte bit but inside we have the signature and in some cases the patches.
Only code a file in base64 it increase around 30% like uuencoded files transfered on internet.

```
233K Feb 27 16:33 wayland-1.23.1.tar.xz
329K Mar  9 17:47 buildpkg.wayland-1.23.1-x86_64-1_BLFS_Graphical.sh

1.9M Mar  8 23:58 libX11-1.8.12.tar.xz
2.5M Mar 10 08:01 /pkg/repository/dirty-0.1/builders/l/libX11/buildpkg.libX11-1.8.12-x86_64-1_BLFS_Graphical_XORGLibs.sh

19M Mar 10 13:30 /tmp/dirty-0.1/sources/glibc-2.41/glibc-2.41.tar.xz
30M Mar  3 09:24 /pkg/repository/dirty-0.1/builders/g/glibc/buildpkg.glibc-2.41-x86_64-1_LFS_r12.2_multilib.sh

236M Mar 10 13:24 /tmp/dirty-0.1/sources-all/linux-6.14-rc5.tar.gz
319M Mar  3 12:52 /pkg/repository/dirty-0.1/builders/l/linux-mainline/buildpkg.linux-mainline-6.14_rc5-x86_64-1_LFS_r12.2_multilib.sh
```
Today the space in disk is not a problem and the benefit is more than the harm. 

### The package script (pkg-ver-arch-rel.sh).
The package script have a tar file inside coded in base64 too.
With the tar file coded inside and a few lines of code we can repeat easy a custom installation. Like with a tar file we can list the files. Extract only one file and compare the files extracted/installed on the system. What about tar errors? Sort the files in the correctoorder and you get no errors.
With few lines more of code we can made some md5sum checksum using the tar as list.
Let me explain this in detail.
At some point on the process of making this, I think about add by defaul the creation of an md5sum file on the system. Tar can extract: one file, a list of files or all the files. Extract all files and pipe it to the checksum program don't work, because the chechsum program need the files one by one. Extract the list of files from the tar and then extract one by one to the checksum program are so slow. Extract one file from tar pipe to the checksum program is usefull if we only want to check a little number of files.
So the md5sum option on the package script use the tar list of files but check the files installed on the system. Then to easy made a checksum control of that files we have 2 options:
    - Store a checksum of the files installed just after install.
    - Check one by one the files and overload the system.
In additional I create my tools to help me to manage that "repository" of files. An additional (/pkg/tools/scripts/installpkg.sh) script can install the package an then store the md5sum. 
But we always have the tar inside to check file by file if needed.

#### Why an other package manager?
Realy it's not, tar does the hard job and is a great tool. Don't need to reinvent the well.
With few lines of code, you can make a script that automate tar jobs. And if you put the sources inside you just have a little powerfull "package script" that you can manage.
Easy rigth? Common.

## The visual concept.
```
+--------------------------------+
| make.buildpkg.pkg.sh           |
|                                |
|  Automate source download      |
|  Check src and new version     |
|  Easy to edit read plain text  |
|  All in one place              |
|  Cat sources in b64 to builder |
|  make the buildpkg             |
| +---------------------------+  |
| | buildpkg.pkg.sh           |  |
| |                           |  |
| |  Have source in b64       |  |
| |  decode and checksum      |  |
| |  can made checks          |  |
| |  Extract and compile src  |  |
| |  get pkg needed libs      |  |
| |  cat files in b64 to pkg  |  |
| |  build the pkg.sh         |  |
| | +--------------------+    |  |                 
| | | pkg.sh             |    |  |   
| | |                    |    |  |
| | |  pkg:tar in b64    |    |  |             
| | |                    |    |  |             
| | |  pkg.sh list       |    |  |
| | |  pkg.sh verbose    |    |  |
| | |  pkg.sh compare    |    |  |
| | |  pkg.sh install    |    |  |
| | |  pkg.sh remove     |    |  |
| | |  pkg.sh shared     |    |  |
| | |  pkg.sh md5sum     |    |  |
| | |  pkg.sh echo       |    |  |
| | |                    |    |  |
| | +--------------------+    |  |                 
| +---------------------------+  |
+--------------------------------+
```

## Extensibility, portability, scalability and more ...
Ok talk a little about.

In reference at extensibility, extra funcionalities can be added by only code it in shell script, no is needed to learn Python, C, rust, go, zig ... compile code or fight vs a database. With a few lines of code it is easy to make a repository manager that checks the packages installed, or the last version package in the logs, or the sources that need updates, or the packages that need upgrade. On tools you can find my script, but everyone can make their ones. It is easy to remove, or exclude when rsync, the makers and the builders and have a repository only with packages. There are advantages and disavantages on store a repository on local. If you dont have the package script to remove the package you can check in tools the removepkg script.

In reference at the portability, the system package uses bash (shell scripts) that make a great portability IMO. Only depend of tar bash coreutils findutils and sed to work. And sure this can be reduced if needed.

How about other arch, maybe we can change on the maker the arch and make a specific builder, but lot of space, duplicated sources coded in b64. Maybe we can add the arch on the build part of the builder. Will see on the next versions.

The scalability, for now I only fight with a fer packages 175, most repeated like gcc pass1 pass2 ... and the cross-toolchain packages. I am planing to add TAGS on the release part of the name but who knows. Suggestions are welcome.

You can immagine the maker.buildpkg organisation like jobs. Each script are a job that can exit 0 or 1. Then you can make an upper script to check/manage/run what jobs are done.

I know that there is not a full reporducible build system but ... wait ... the builders ... will ... ou ...
The builder was reproducible. mmm Maybe late I can do something more. I am working now to add SOURCE_DATE_EPOCH.

We can talk about security and how to harden my dirty.

I don't forgot the dependéncies. An other funcionality I don't talk about, the needed_libs file that each package have.
As example to find the packages that have been build with pam you can do:
```
bash-5.2# grep "libpam" /pkg/installed/*/needed-libs | cut -d':' -f1 | sort -u
/pkg/installed/linux-pam-1.7.0-x86_64-1_BLFS_sysV_r12.2/needed-libs
/pkg/installed/openssh-9.9p2-x86_64-1_BLFS_sysV_r12.2/needed-libs
/pkg/installed/shadow-4.17.3-x86_64-1_BLFS_sysV_r12.2/needed-libs
/pkg/installed/shadow-4.17.3-x86_64-1_LFS_r12.2_multilib/needed-libs
```
And this can be coded in a search script to add functionalities.

And then, how to manage all that files? Below an example of how my repository looks.
The advantage of that simple organization  are that you have all the data sctuctured and accessible, not in a Data Base that you need to know and make the queryes. You can made your custom scripts to show or manage as you want. Powerfull?
Try to guess what each letter is. See "The repository status." section for more info.
```
bash-5.2# bash /pkg/tools/scripts/repo-status.sh
 M B P     U V - Python-3.13.2-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I     V L Python-3.13.2-x86_64-1_LFS_r12.2_multilib
 M B P I     V L acl-2.3.2-x86_64-1_LFS_r12.2_multilib
   B         V - acl-2.3.2-x86_64-1_LFS_r12.2_multilib.sh
 M B P     U V - alsa-lib-1.2.13-x86_64-1_LFS_r12.2_multilib
 M B P     U V - alsa-utils-1.2.13-x86_64-1_LFS_r12.2_multilib
 M B P I     V L attr-2.5.2-x86_64-1_LFS_r12.2_multilib
 M B P I     V L autoconf-2.72-x86_64-1_LFS_r12.2_multilib
 M B P I     V L automake-1.17-x86_64-1_LFS_r12.2_multilib
 M B P     U V - bash-5.2.37-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I     V L bash-5.2.37-x86_64-1_LFS_r12.2_multilib
 M B P I     V L bc-1.08.1-x86_64-1_LFS_r12.2_multilib
 M B P I     V L binutils-2.44-x86_64-1_LFS_r12.2_multilib
 M B P     U V - binutils-pass1-2.44-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P     U V - binutils-pass2-2.44-x86_64-1_LFSCHROOT_r12.2_multilib
 M B     s   V - binutils-with-gold-2.44-x86_64-1_LFS_r12.2_multilib
 M B P     U V - bison-3.8.2-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I     V L bison-3.8.2-x86_64-1_LFS_r12.2_multilib
 M B P         - blfs-bootscripts-20241209-x86_64-1_BLFS_sysV_r12.2
 M B P I     V L blfs-bootscripts-20250225-x86_64-1_BLFS_sysV_r12.2
 M B P I     V L bzip2-1.0.8-x86_64-1_LFS_r12.2_multilib
 M B P     U V - coreutils-9.6-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I     V L coreutils-9.6-x86_64-1_LFS_r12.2_multilib
 M B P I     V L curl-8.12.1-x86_64-1_BLFS_sysV_r12.2
 M B P         - dhcpcd-10.2.0-x86_64-1_BLFS_sysV_r12.2
 M B P I     V L dhcpcd-10.2.2-x86_64-1_BLFS_sysV_r12.2
 M B P     U V - diffutils-3.11-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I     V L diffutils-3.11-x86_64-1_LFS_r12.2_multilib
```

## The /pkg directory
In the early of the make.buildpkg I used a home dir to store makers builders and packages directories with the respective files on LFS_chroot LFS and BLFS directories on an ineficient way. Late I decided to unify all in a repository and the best place to put all togheder IMO are a new place in the root directory. Hello new standard FSH location for packatges.
Shit, I want remove all that dirty. It's all under /pkg.

### Visual /pkg structure.
```
.
└── pkg
    ├── blacklist
    ├── installed
    ├── repository
    │   └── dirty-0.1
    │       ├── builders
    │       ├── makers
    │       └── packages
    └── tools
        ├── checksums
        ├── lists_of_packages
        ├── patches
        └── scripts
```

### The /pkg/blacklist dir
This directory serve to make soft links (aka:simlinks) to the files that we want to freeze.
If a maker is blacklisted the automated scripts like (/pkg/tools/scripts/check-updates.sh), that uses lists_of_packages to run, skip to run the blacklisted maker.
Same whith builders and packages.
I will expose late the automation and the lists_of_packages.
Nothing stop you to run a maker a builer or install a package manually.
For now you can blacklist a maker like:
```
ln -s /pkg/repository/dirty-0.1/makers/b/binutils-with-gold/make.buildpkg.binutils-with-gold-2.44-x86_64-1_LFS_r12.2_multilib.sh /pkg/blacklist/
```
Same for builders and packages but changing the link to respective script.

### The /pkg/installed dir
This directory have a list of installed packages ordered in directories (showed above).
```
bash-5.2# ls -l1 /pkg/installed/ | head -8
total 432
drwxr-xr-x 2 root root 4096 Mar 10 18:51 Python-3.13.2-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:50 acl-2.3.2-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:50 attr-2.5.2-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:51 autoconf-2.72-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:51 automake-1.17-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:51 bash-5.2.37-x86_64-1_LFS_r12.2_multilib
drwxr-xr-x 2 root root 4096 Mar 10 18:50 bc-1.08.1-x86_64-1_LFS_r12.2_multilib
``` 

Inside these packages directories we have a structured system of package metadata (showed above too).
```
bash-5.2# ls -la /pkg/installed/binutils-2.44-x86_64-1_LFS_r12.2_multilib/
total 64
drwxr-xr-x   2 root root  4096 Mar 11 09:35 .
drwxr-xr-x 110 root root 12288 Mar 10 18:52 ..
-rw-r--r--   1 root root    43 Mar 10 18:50 build-time
-rw-r--r--   1 root root 13316 Mar 10 18:50 index
-rw-r--r--   1 root root 23728 Mar 11 09:35 md5sum
-rw-r--r--   1 root root  2952 Mar 10 18:50 needed-libs
bash-5.2#
``` 

I think each file name is self-explanatory.

As exposed on "The package script" section, to get the md5sum file, after install a package we can run:
```
bash-5.2# bash /pkg/repository/dirty-0.1/packages/b/binutils/binutils-2.44-x86_64-1_LFS_r12.2_multilib.sh md5sum > /pkg/installed/binutils-2.44-x86_64-1_LFS_r12.2_multilib/md5sum
```
or use the (/pkg/tools/scripts/installpkg.sh) script.

### The /pkg/repository/dirty-0.1 dir (The Dirty system is alive!!).
Like Victor Franquestein my monster based on LFS need a release name.
For now is a work in progres and maybe die before see the ligth but I will try hard. No?
Inside the dirty-0.1 directory we have the three makers builders and packages directories, then the first leter of the package name, then the name of the package and then the corresponding maker builder or package scripts. The CORE of the system.

Why that long path?
It is not the same that all the scripts are in directories inside the three makers builders packages directories or add a letter in between.
```
/home/data/git-repos/vielLosero/make.buildpkg/LFS_chroot/27 maker_scripts.   <-- my first atempt.
/home/data/git-repos/vielLosero/make.buildpkg/LFS/75 maker_scripts. 
...
/pkg/repository/dirty-0.1/makers/175 maker_script files.
/pkg/repository/dirty-0.1/makers/175 package_name dirs/10 maker_script files.
/pkg/repository/dirty-0.1/packages/a/24 package_name dirs start with a/10 makers_script files.
```                                  
The last was more scalable rigth?

### The /pkg/tools dir
This directory have four directories inside. Explained above.
There is too some files like my basic kernel config to test on qemu. Some others work trash files, and 2 that I want to enumerate:
The lfs-user and the lfs-chroot.
These files are two scripts that help set up the environment when I build the list of packages.
Alarm to know when the builds have finished. Notes.txt. The script to sign the packages. The pub key. And a file for triks. Thats my dirty working caos.

#### The /pkg/tools/checksums directory 
Tis directory have some checksums of the entire filesystem to compare between builds for now, the plan was to automate the creation of  master checksums of all the md5sum files from installed packages. Or something similar. I will see late. You can check it.
```
bash-5.2# md5sum /pkg/tools/checksums/CHECKSUMS.mnt.lfs.chroot.md5
c22be0227ac91facb4693e0a52e4fb74  /pkg/tools/checksums/CHECKSUMS.mnt.lfs.chroot.md5   <-- MASTER KEY??

bash-5.2# cat /pkg/tools/checksums/CHECKSUMS.mnt.lfs.chroot.md5 | grep pkg/installed/ | grep md5sum | head -5
6f40c614ce7c1aeb2535a85d21e2753a  ./pkg/installed/make-4.4.1-x86_64-1_LFSCHROOT_r12.2_multilib/md5sum
98ad8bd5ded64cd3a9bdcf83e27e3532  ./pkg/installed/findutils-4.10.0-x86_64-1_LFSCHROOT_r12.2_multilib/md5sum
3d81473bdde94fd5cdf19bf13c73cc73  ./pkg/installed/util-linux-2.40.4-x86_64-1_LFSCHROOT_r12.2_multilib/md5sum
121ba7c370eee6210b4baa44bda45708  ./pkg/installed/Python-3.13.2-x86_64-1_LFSCHROOT_r12.2_multilib/md5sum
c48282068020e80d7752fecf74387179  ./pkg/installed/grep-3.11-x86_64-1_LFSCHROOT_r12.2_multilib/md5sum
bash-5.2#

```
#### The /pkg/tools/lists_of_packages directory
This directory have the list of packages ordered.
We need ordered list to install for example the BLFS shadow after the LFS shadow package.
Or to install gcc-pass2 after gcc-pass1.
Maybe I can made custom lists to install custom systems? Like list_dns_server ...
The lists_of_packages contain only the relevant TAGS of the scripts like:
```
bash-5.2# cat /pkg/tools/lists_of_packages/LFSCHROOT_Cross-Toolchain_and_cross_tools.txt                             15:45:16 [10/35483]
#order list for update and build packages.
# cat ordered.txt | grep -v "#" | while read line ; do ls /pkg/repository/*/*/*/*$line ; done
# _LFSCHROOT_
#
# 5. Compiling a Cross-Toolchain
.make_buildpkg_dirty_package_manager-[0-9]*_LFSCHROOT_*
.filesystem_hierarchy-[0-9]*_LFSCHROOT_*
.binutils-pass1-[0-9]*_LFSCHROOT_*
.gcc-pass1-[0-9]*_LFSCHROOT_*
.linux-headers-[0-9]*_LFSCHROOT_*
.glibc-[0-9]*_LFSCHROOT_*
.gcc-libstdc++-[0-9]*_LFSCHROOT_*
#
# 6. Cross Compiling Temporary Tools
.m4-[0-9]*_LFSCHROOT_*
.ncurses-[0-9]*_LFSCHROOT_*
.bash-[0-9]*_LFSCHROOT_*
.coreutils-[0-9]*_LFSCHROOT_*
.diffutils-[0-9]*_LFSCHROOT_*
.file-[0-9]*_LFSCHROOT_*
.findutils-[0-9]*_LFSCHROOT_*
.gawk-[0-9]*_LFSCHROOT_*
.grep-[0-9]*_LFSCHROOT_*
.gzip-[0-9]*_LFSCHROOT_*
.make-[0-9]*_LFSCHROOT_*
.patch-[0-9]*_LFSCHROOT_*
.sed-[0-9]*_LFSCHROOT_*
.tar-[0-9]*_LFSCHROOT_*
.xz-[0-9]*_LFSCHROOT_*
.binutils-pass2-[0-9]*_LFSCHROOT_*
.gcc-pass2-[0-9]*_LFSCHROOT_*
``` 

With that I can run my custom script to find the makers, the builders or the packages and automate thinks like check updates or install.
Not to hard I can live with that if I can automate the work. Did you imagine figth with list of hard coded full paths?

What if I make a list for the packages that need update? Wait it is on (last_update_ordered_list.txt). On Check for updates section I will explain how that works.

#### The /pkg/tools/patches directory
This is the trash dir where I put my patches to retouch all the makers for big changes, like patch the license (/pkg/tools/patches/patch_license) to acomplish with the portion of lines I have used from LFS. (Thanks LFS comunity.)

Don't look inside, you will see my errors code. XD

#### The /pkg/tools/scripts directory
This direcotry have my scripts to manage the repository for now, the plan B are to add some soft links to find the needed tools on /usr/local/sbin/ and or /usr/local/bin faster.

The plan C are that you, if you are already reading this, make your custom scripts and share it with me (the joke community of "Dirty") :) or not. I hope you can appreciate the power of having full system packages data ordered, accesible and simple.

If you plan to try "Dirty" system you can use a custom script placed inside that directory to make a raw disk for qemu.

### The repository status.
Now you know a little more about my "Dirty" system try but that's not all folks!
Surfing the web people tank about stay or not with LFS because it is hard to update and mantain.
As learning experience LFS are awesome. I recomend you to build it at last one. When I do it a new world was opened for me. But whats next? How to manage all that?
Data are the reponse. If we know the status of each package we can mainage it. Nothing new rigth? So where is the data? And what we need to know?
```
# reset vars.
# m(maker) b(builder) p(package) i(installed) s(skipped/blacklisted) u(update/remove) v(version) l(in logs)
#m M maker exist
#b B builder exist
#p P package exist
#i I are installed
#s s maker or builder are skipped
#s S package are skipped
#u u maker need update
#u U package need upgrade
#u R package can be removed
#v V is the last version
#l - package not in logs # by default
#l   package in logs. is space " "
#l L package are last in logs
```
At this point you would have to know where the makers the builders and the packages scripts are, and where are the installed packages and que blacklist directories.

In the next point "Check for updates" I will explain the update process. For now we can found (after run /pkg/tools/scripts/check-updates.sh) a temp dir with the makers that need updates. So that files are marked on the repository status as need update with a "u".
```
bash-5.2# ls -1 /tmp/updates/need_update/
make.buildpkg.iana-etc-20250225-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.linux-6.13.5-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.linux-headers-6.13.5-x86_64-1_LFSCHROOT_r12.2_multilib.sh
make.buildpkg.linux-headers-6.13.5-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.linux-mainline-6.14_rc5-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.llvm-19.1.7-x86_64-1_BLFS_sysV_r12.2.sh
make.buildpkg.pkgconf-2.4.1-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.setuptools-75.8.2-x86_64-1_LFS_r12.2_multilib.sh
make.buildpkg.vim-9.1.1179-x86_64-1_LFS_r12.2_multilib.sh
bash-5.2#
```

There is a log file (/var/log/make.buildpkg.log) to know if a old version of a package has been installed, maybe by error. In that case the last version of the package it will be marked as need upgrade with a "U" when runing the repo status script. At this point it is not safe to remove the old package becasue we can lose funcionalities. After restoring/update to the last version of the package we have two installed packages and the older it will be marked as safe to remove with a "R" when we run the repo status.
Then you can remove/uninstall the package from the system not from the repository. XD

## Check for updates.
Thas's ugly I know but two months of work are not enough for more.
First the self explained organization of files. There are 3 directories that have soft links to the makers if they are checked, failed or need update. The others files are working lists.  

bash-5.2# ls -la /tmp/updates/
total 44
drwxr-xr-x 5 root root  4096 Mar 12 04:36 .
drwxr-xr-t 4 root root  4096 Mar 12 04:36 ..
drwxr-xr-x 2 root root 16384 Mar 12 04:36 checked
drwxr-xr-x 2 root root  4096 Mar 12 04:36 failed
-rw-r--r-- 1 root root   612 Mar 12 04:36 last_update_ordered_list.txt
-rw-r--r-- 1 root root  1224 Mar 12 04:36 last_version_makers_ordered_list.txt
drwxr-xr-x 2 root root  4096 Mar 12 04:36 need_update
-rw-r--r-- 1 root root  1224 Mar 12 04:36 ordered_update_links.txt
bash-5.2# ls -la /tmp/updates/

The metodology of work was to run /pkg/tools/scripts/check-updates.sh just whitout failed checks. So all makers will be on checked or need_update.

Then we only need copy the old maker with the new version name and run one by one all makers to download the sources, edit the checksums, read the sources Changelogs and audit it. Not kidding. You can automate this too. I don't, to risky for me. I don't audit the sources but depending the package and the time I do more or less controls you know.

To automate a few the process I have the lists of packages, so I made 2 scripts on tools.
One to run the makers (compile-makers.sh) sure I will change that name. To run the last_update_ordered_list.txt whitout need to write each maker path. Maybe are best to download all the sources at same time and then chekc it and edit the chekcsums but, I am happy runing one by one.
And one to install the new packages when they be ready (/pkg/tools/scripts/installpkg.sh).

That is a work in progress ... and sure my automation scripts will change.
```
bash-5.2# bash /pkg/tools/scripts/repo-status.sh | grep " u "
 M B P I   u V L iana-etc-20250225-x86_64-1_LFS_r12.2_multilib
 M B P     u V - linux-6.13.5-x86_64-1_LFS_r12.2_multilib
 M B P     u V - linux-headers-6.13.5-x86_64-1_LFSCHROOT_r12.2_multilib
 M B P I   u V L linux-headers-6.13.5-x86_64-1_LFS_r12.2_multilib
 M B P I   u V L linux-mainline-6.14_rc5-x86_64-1_LFS_r12.2_multilib
 M B P I   u V L pkgconf-2.4.1-x86_64-1_LFS_r12.2_multilib
 M B P I   u V L setuptools-75.8.2-x86_64-1_LFS_r12.2_multilib
 M B P I   u V L vim-9.1.1179-x86_64-1_LFS_r12.2_multilib
bash-5.2#
```

## Downloading sources.
Back to updating the makers ... or when make new ones ...
In the first trys I use a separate temp directory per package to store download sources and construct the builder inside. Thats ends with some duplicate sources and lose of disk space. Like LFS do, I put all the sources in a /tmp/dirty-0.1/sources-all directory and make hard links for each package to construct the builder.
As you know the hard link use the same inode and no require additional space. So whith that structure we have an ordered per package sources and a full dir with all the sources, easy to manage as needed.

I am happy to share my "dirty" with all you but ... , automated download of souces per user is not the same as download packages from a distribution server that are ready to. So guys don't collapse the servers souces downloading asap. Especting 2 or 3 folks who dare to try I am not scared about rigth?. Due to github repository limits I can't push all my repository.
The old organization of files moved from tree dirs LFS LFS_chroot and BLFS with makers builders and packages to the ordered repository structure showed below make the git log so big. So I will made a new clean repository to share the makers and maybe some little builders and the pacckages, dunno.
```
--- /home/data/git-repos/vielLosero/make.buildpkg --------------------------------------------------------------------------------------
   13.8 GiB [###################] /.git
    4.3 GiB [#####              ] /pkg
   16.0 KiB [                   ]  make.buildpkg.busybox.1.37.0-x86_64-1.sh
   12.0 KiB [                   ]  README.md
   12.0 KiB [                   ]  make.buildpkg.ncdu-1.21-x86_64-1.sh
    4.0 KiB [                   ]  lfs-chroot
    4.0 KiB [                   ]  viel.losero.pubring.gpg
```

If anyone would be kind enough to provide some space/server I would appreciate it. For now I am no plan to rent any hosting just for my dirty. But I want to share it with you :)

## Usage of the packages.
All this hard job I done was to have a Dirty structured system of packages to reuse them in others machines and manage them.
If you plan to try it you can install one by one or use the orderd lists to install the packages. Like:
```
bash /pkg/tools/scripts/install-list.sh /pkg/tools/lists_of_packages/LFSCHROOT_Cross-Toolchain_and_cross_tools.txt
```
This will install on /mnt/lfs the Cross toolchain from your /pkg/repository/dirty-0.1/packages if you have build it or you can rsync it from internet.

I know. There is a lot of work to do with the packages to automate the distribution of packages and make alive my "Dirty" system based on LFS. Who knows.

## The run scripts
Build LFS toolchain and aditional tools for cross compiling, or for isolate from the host is not trivial you know. Once we have the maker is hard too to run it one by one, the run scripts make our life easy.
The runers scripts automate some task. Like run the maker if you dont have the builder, run the builder if you dont have the package, or install the package if it are not installed. All this on /mnt/lfs of course.
Be care about disc space I build it on ram in a 32 Ram system and I have sometimes run out of available RAM. Is for that maybe you need to adjust the scripts or make yours.
There are two, the toolchain and the chroot:
```
/pkg/tools/scripts/run.LFSCHROOT_Cross-Toolchain.sh
```
```
/pkg/tools/scripts/run.LFSCHROOT_Chroot_additional_tools.sh
```

## A new world is comming.
There are lot of possibilities when make the thinks small and simple.
As a learning experience I would do it again.
As my main system I am working on.
Hope you can apreciate that 2 months of job and the work behind F.O.S.S community an the distributions. I done, I do and I will do.
Sure I forgot something but ... If you've read this far, I think that's enough for try my Dirty or hate it.

Can you imagine a maker script with all (or almost a lot) of the system config files inside, that you can edit and install on a clean LFS system?
Can you imagine the package and the config_files in separated scripts?
Or lot of builders scripts with diferent compilation option managed easy?
Or lot of package scripts to select your custom system as needed?
Or lot of custom lists to install from that lot of packages and construct your system?
If you can, leave the "dirty" grow.

## Triks
Custom views of repo status with grep.
```
bash /pkg/tools/scripts/repo-status.sh | grep -v "_LFSCHROOT_" | grep -v "_LFS_"
```
```
bash /pkg/tools/scripts/repo-status.sh | grep " u " | grep "_LFS_"
```
```
bash /pkg/tools/scripts/repo-status.sh | grep " R "
```

Use the package echo option to extract a file to md5sum or hexdump ...
```
bash /pkg/repository/dirty-0.1/packages/r/rsync-3.4.1-x86_64-1_BLFS_r12.2_multilib.sh echo | tail -n +5 | base64 -d | tar -Jxf - usr/bin/rsync -O | md5sum
```

Get package needed libs list.
```
cat /pkg/installed/*/needed-libs | cut -d':' -f2 | sed 's/,/\n/g' | sort -u
```
```
cat /pkg/installed/gcc-14.2.0-x86_64-1_LFS_r12.2_multilib/needed-libs | cut -d':' -f2 | tr ',' '\n' | sort -u
```

Find packages that not depending of ...
```
find /pkg/installed/ -name "needed-libs" -exec grep -L "libc.so" {} \; | cut -d'/' -f4
```

Check md5sum of packages.
```
cat /pkg/installed/binutils-2.44-x86_64-1_LFS_r12.2_multilib/md5sum | tail -n +6 | md5sum -c
```
```
find /pkg/installed/ -name md5sum -exec sh -c 'echo {} ; cat {} | tail -n +6 | md5sum -c --quiet'  \;
```

## Thanks to:

LFS BLFS MLFS GLFS For their job.

The F.O.S.S comunity. Try hard.

The readers, if you have arrived here.

## Contributing and support

Please read [Contributor covenant](https://www.contributor-covenant.org/) for details, and  [code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct) before submitting pull requests or issues.

If you want to support this project with a donation, here is mi Bitcoin address:

bc1q6d245chm8t5sdkqjugwg3ce2c92m276ee4ksv4

## The Author

* **Viel Losero** - *Initial work* - [Viel Losero](https://github.com/VielLosero)

References:

[LFS](https://www.linuxfromscratch.org/)

Licence: [CC-BY-SA](http://creativecommons.org/licenses/by-sa/4.0/)
