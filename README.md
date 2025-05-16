
## The Dirty system from scratch
English is not my main language, so be patient. I will write little.
As a learning experience I started building a simple package manager to manage my first build of LFS. Late I changed to MLFS and GLFS. This is a work in progress. Sure each LFS users have their own scripts to manage their packages, updates and the system. Happy to share my dirty if this can help someone.
For now I build full MLFS and 70% GLFS and some custom packages to get a little functional system that can boot on my laptop and continue the development not in a virtual machine. I need feedback, testers, contributors, supporters ... any help are welcome.
Why that name "Dirty"?
Because it is a work in progress and sure my code can polish more, but it works.
The concept are easy, a script (the maker) that download the sources do the checksums and make a second script (the builder). The builder creates a thirt script (the package) to install the files. You can read more about it on my old file [HOW.DID.DIRTY.START.md](HOW.DID.DIRTY.START.md)

### How to install the repository and build from sources.
Clone the repository and move it to have your / like /pkg/repository/MLFSCHROOT. Root perms are needed.
```
cd /tmp
git clone https://github.com/VielLosero/dirty.current.git
mv dirty.current/pkg /
```
Then you can mount your disk or partition under /mnt/lfs or mount a disk image on /mnt/lfs for virtual machines or simply run it to build LFS on your /mnt/lfs directory. It is highly recommended to built in a virtual machine if you don't know what you are doing. Late you can scp or rsync the packages to install it where you want.

To start the build you need to run the script that download sources, make the buildes, build the packages and install MLFS chapters 5 and 6 on /mnt/lfs. This will create the chroot environment. Be care about start on a clean /mnt/lfs.
Alternatively you can run the makers one by one if you create the user and LFS environment before.
```
bash /pkg/tools/scripts/run.MLFSCHROOT_Cross-Toolchain.sh
```
This will take some time. On my laptop with an Intel Core i7-6700HQ @ 4x 2.592GHz with mitigations on a virtual machine with host cpu and the 4 cores it takes 69 minutes.

After build if everything has gone well you can chroot inside using the lfs-chroot script, or manualy like a current LFS.
```
bash-5.2# bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login
7.2. Changing Ownership.
7.3. Preparing Virtual Kernel File Systems.
mkdir: created directory '/mnt/lfs/dev'
mkdir: created directory '/mnt/lfs/proc'
mkdir: created directory '/mnt/lfs/sys'
mkdir: created directory '/mnt/lfs/run'
mount: /dev bound on /mnt/lfs/dev.
mount: devpts mounted on /mnt/lfs/dev/pts.
mount: proc mounted on /mnt/lfs/proc.
mount: sysfs mounted on /mnt/lfs/sys.
mount: tmpfs mounted on /mnt/lfs/run.
mount: tmpfs mounted on /mnt/lfs/dev/shm.
devtmpfs on /mnt/lfs/dev type devtmpfs (rw,relatime,size=14881328k,nr_inodes=3720332,mode=755,inode64)
devpts on /mnt/lfs/dev/pts type devpts (rw,relatime,gid=5,mode=620,ptmxmode=000)
tmpfs on /mnt/lfs/dev/shm type tmpfs (rw,nosuid,nodev,relatime,inode64)
devpts on /mnt/lfs/dev/pts type devpts (rw,relatime,gid=5,mode=620,ptmxmode=000)
proc on /mnt/lfs/proc type proc (rw,relatime)
sysfs on /mnt/lfs/sys type sysfs (rw,relatime)
tmpfs on /mnt/lfs/run type tmpfs (rw,relatime,inode64)
tmpfs on /mnt/lfs/dev/shm type tmpfs (rw,nosuid,nodev,relatime,inode64)
(lfs chroot) I have no name!:/#
```
Exit from lfs chroot if you are inside and run the next script that download sources, make the buildes, build the packages and install MLFS chapter 7.
```
bash /pkg/tools/scripts/run.MLFSCHROOT_Chroot_additional_tools.sh
```
This will take in my system about 20 minutes. If everything has gone well you can now chroot inside /mnt/lfs dir using the lfs-chroot script or manualy mounting dev,proc,sys ... like a current LFS.
```
bash-5.2# bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login
7.2. Changing Ownership.
7.3. Preparing Virtual Kernel File Systems.
mount: /dev bound on /mnt/lfs/dev.
mount: devpts mounted on /mnt/lfs/dev/pts.
mount: proc mounted on /mnt/lfs/proc.
mount: sysfs mounted on /mnt/lfs/sys.
mount: tmpfs mounted on /mnt/lfs/run.
mount: tmpfs mounted on /mnt/lfs/dev/shm.
devtmpfs on /mnt/lfs/dev type devtmpfs (rw,relatime,size=14881332k,nr_inodes=3720333,mode=755,inode64)
devpts on /mnt/lfs/dev/pts type devpts (rw,relatime,gid=5,mode=620,ptmxmode=000)
tmpfs on /mnt/lfs/dev/shm type tmpfs (rw,nosuid,nodev,relatime,inode64)
devpts on /mnt/lfs/dev/pts type devpts (rw,relatime,gid=5,mode=620,ptmxmode=000)
proc on /mnt/lfs/proc type proc (rw,relatime)
sysfs on /mnt/lfs/sys type sysfs (rw,relatime)
tmpfs on /mnt/lfs/run type tmpfs (rw,relatime,inode64)
tmpfs on /mnt/lfs/dev/shm type tmpfs (rw,nosuid,nodev,relatime,inode64)
(lfs chroot) root:/#
``` 
Now you are ready to download the sources to build dirty-0.0 repository inside the chroot and run it.
Again exit from chroot.

---
**NOTE**

You can check the packages build statistics in /pkg/metadata/MLFSCHROOT/{pkg_name}/timings. And check the buidlers and the packages created under /mnt/lfs/... and copied with rsync to /pkg/repository/MLFSCHROOT/buidlers/ /pkg/repository/MLFSCHROOT/packages/

---

The chroot don't have network so we need to download sources and make the buidlers to copy it into the chroot LFS and build it.
You can run the makers one by one or use the above commands to run the script to do it.
```
cp /pkg/tools/run.repo.list.dirty-0.0.make /tmp/run.repo.list

bash /pkg/tools/scripts/run.repo.list.sh 
```
Then rsync all the /pkg dir into the LFS chroot. Chroot inside and run the builders. Chapters 8,9 ... From MLFS, some GLFS and some custom packages. The entire list of packages on [/pkg/tools/lists_of_packages/dirty-0.0_current_list.txt](pkg/tools/lists_of_packages/dirty-0.0_current_list.txt)
```
rsync -avP /pkg /mnt/lfs/
```
To chroot into LFS dir.
```
bash /pkg/tools/lfs-chroot mount && bash /pkg/tools/lfs-chroot login
```
Inside the chroot. Again you can run the builders one by one and install the packages created or run the above commands to automate the task.
```
(lfs chroot) root:/# cp /pkg/tools/run.repo.list.dirty-0.0.build.install /tmp/run.repo.list

(lfs chroot) root:/# bash /pkg/tools/scripts/run.repo.list.sh
```
## What next?
If you are able to make it work you can then check for updates. Make and share your makers. Test and feedback. Contribute and leave the dirty grow.

## Thanks to:

LFS BLFS MLFS GLFS For their job.

The readers, if you have arrived here.

## Contributing and support

You can catch me on [LQ LFS Forum](https://www.linuxquestions.org/questions/linux-from-scratch-13/).

Please read [Contributor covenant](https://www.contributor-covenant.org/) for details, and  [code of conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct) before submitting pull requests or issues.

If you want to support this project with a donation, here is mi Bitcoin address:

bc1q6d245chm8t5sdkqjugwg3ce2c92m276ee4ksv4

## The Author

* **Viel Losero** - *Initial work* - [Viel Losero](https://github.com/VielLosero)

References:

[LFS](https://www.linuxfromscratch.org/)

Licence: [CC-BY-SA](http://creativecommons.org/licenses/by-sa/4.0/)
