
# Makers scripts for dirty current (The Dirty system from scratch)
Reading here and there before start build LFS, hoping to be able to use it as my daily distribution and as a learning experience I started building a simple package manager to manage my first build of LFS.
This is the result and a work in progress that I will share. My dirty system from scratch.
Any feedback, testers, contributors, supporters ... help are welcome.

## Motivation



## What you can expect?



## The concept
The concept are easy, a script (the maker) that download the sources do the checksums and make a second script (the builder). The builder creates a thirt script (the package) to install the files on the system.
```
bash-5.2# ls -la /pkg/repository/dirty-0.0/
total 20
drwxr-xr-x  5 root root 4096 May  9 14:26 .
drwxr-xr-x  4 root root 4096 May 13 17:36 ..
drwxr-xr-x 38 root root 4096 Apr 24 10:35 builders
drwxr-xr-x 38 root root 4096 Apr 24 10:35 makers
drwxr-xr-x 38 root root 4096 Apr 24 10:35 packages
bash-5.2#
```
The maker 



## How to install the repository and build from sources.
Clone the repository and move it to the / root dir.
```
cd /tmp
git clone https://github.com/VielLosero/dirty.current.git
mv dirty.current/pkg /
```
Mount your disk, partition or disk image file under /mnt/lfs.

Start the build for MLFS chapters 5 and 6.
This will take some time. On my laptop with an Intel Core i7-6700HQ @ 4x 2.592GHz with mitigations on a virtual machine with host cpu and the 4 cores it takes 69 minutes.
```
bash /pkg/tools/scripts/run.MLFSCHROOT_Cross-Toolchain.sh
```
---
**NOTE**
After build if everything has gone well you can chroot inside using the lfs-chroot script, or manualy like a current LFS.
```
bash-5.2# bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login
```
---

Exit from lfs chroot if you are inside and run the next script to build MLFS chapter 7.
This will take in my system about 20 minutes. 
```
bash /pkg/tools/scripts/run.MLFSCHROOT_Chroot_additional_tools.sh
```

---
**NOTE**
If everything has gone well you can now chroot inside again.
```
bash-5.2# bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login
```
---

Now you are ready to download the sources to build dirty-0.0 repository inside the chroot and run it.
Again exit from chroot.

The chroot don't have network so we need to download sources outside the chroot.
You can run the makers one by one or use the above commands to run all in one.
```
cp /pkg/tools/run.repo.list.dirty-0.0.make /tmp/run.repo.list

bash /pkg/tools/scripts/run.repo.list.sh 
```
Then rsync all the /pkg dir into the LFS chroot. This will rsync the builders with the sources on the LFS chroot.
```
rsync -avP /pkg /mnt/lfs/
```
Chroot inside and run the builders. MLFS Chapters 8,9. GLFS and some custom. The entire list to build are [/pkg/tools/lists_of_packages/dirty-0.0_current_list.txt](pkg/tools/lists_of_packages/dirty-0.0_current_list.txt)
```
bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login

(lfs chroot) root:/# cp /pkg/tools/run.repo.list.dirty-0.0.build.install /tmp/run.repo.list

(lfs chroot) root:/# bash /pkg/tools/scripts/run.repo.list.sh
```
## What next?
Check your repo status. 
```
bash /pkg/tools/scripts/repo-status.sh
```
If you are able to make it work you can then check for updates. 
```
bash /pkg/tools/scripts/update-repository-makers.sh
bash /pkg/tools/scripts/upgrade-repository-makers.sh
bash /pkg/tools/scripts/update-repository-builders.sh
bash /pkg/tools/scripts/upgrade-repository-builders.sh
bash /pkg/tools/scripts/update-repository-packages.sh
bash /pkg/tools/scripts/upgrade-repository-packages.sh
```
Make and share your makers. Test and feedback. Contribute and leave the dirty grow.
You can check the packages build statistics in /pkg/metadata/MLFSCHROOT/{pkg_name}/timings. And check the buidlers and the packages created under /mnt/lfs/... and copied with rsync to /pkg/repository/MLFSCHROOT/buidlers/ /pkg/repository/MLFSCHROOT/packages/
You can check the statisctics inside chroot on /pkg/metadata/dirty-0.0/ too.
...

Some changes are comming ... stay up. 

## Thanks to:

LFS BLFS MLFS GLFS For their job.

The readers, if you have arrived here.

## Contributing and support

You can catch me on [LQ LFS Forum](https://www.linuxquestions.org/questions/linux-from-scratch-13/).

Please read [Contributor covenant](https://www.contributor-covenant.org/) for details, and  [code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct) before submitting pull requests or issues.

## The Author

* **Viel Losero** - *Initial work* - [Viel Losero](https://github.com/VielLosero)

References:

[LFS](https://www.linuxfromscratch.org/)

Licence: [CC-BY-SA](http://creativecommons.org/licenses/by-sa/4.0/)
