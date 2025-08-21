#!/bin/bash

# Script to run for make a demo video.

#ps='\s-\v\$'
#echo "${ps@P}"

delay=0.10

run(){
comm="$1"

ps='\s-\v\$'
echo -n "${ps@P} "
for ((i = 0; i < ${#comm}; i++)); do
    echo -n "${comm:$i:1}"
    sleep $delay
done
echo -en "\n" ; echo "$comm" | bash
#echo -e "\n $comm" | bash
}

write(){
comm="$1"

ps='\s-\v\$'
echo -n "${ps@P} "
for ((i = 0; i < ${#comm}; i++)); do
    echo -n "${comm:$i:1}"
    sleep $delay
done
echo ""
}


case $1 in
  1) CH1=1
    ;;
  2) CH2=1
    ;;
  3) CH3=1
    ;;
  4) CH4=1
    ;;
  5) CH5=1
    ;;
  6) CH6=1
    ;;
  *)  CH1=${CH1:-1} CH2=${CH2:-1} CH3=${CH3:-1} CH4=${CH4:-1} CH5=${CH5:-1} CH6=${CH6:-1}
    ;;
esac
CH1=${CH1:-0} CH2=${CH2:-0} CH3=${CH3:-0} CH4=${CH4:-0} CH5=${CH5:-0} CH6=${CH6:-0}

if [ $CH1 -eq 1 ] ; then
delay=0.05
write "Chapter 1."
write "Welcome to the Dirty System From Scratch demo."
write "It is a system based on MLFS and GLFS Linux from scratch books."
write "A new distribution concept based on files and sources coded inside scripts in base64."
write "With 3 base scripts that do the job."
write "The MAKER script."
write "The BUILDER script."
write "And the PACKAGE script."
write "The Maker can check for updates and download the sources to code insite the Builder."
write "The Builder compile the sources and code the files inside the Package."
write "The Package can install the files on the system."
write "Lets go."
delay=0.10
write "A maker checking for updates."
run 'CHECK_RELEASE=1 bash /pkg/repository/dirty-0.0/makers/a/acl/make.buildpkg.acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "A maker making the builder."
run 'bash /pkg/repository/dirty-0.0/makers/a/acl/make.buildpkg.acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "A builder compiling sources to build a package."
run 'bash /pkg/repository/dirty-0.0/builders/a/acl/buildpkg.acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "A package installing the compiled files on the system."
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh install'
fi


if [ $CH2 -eq 1 ] ; then
write "Chapter 2."
write "Go deeper the builder and the package."
write "The Builder script has well ordered parts to build the sources."
run 'SKIP=1 bash /pkg/repository/dirty-0.0/builders/a/acl/buildpkg.acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "We can run or redo only one or multiples desired parts like extract the sources."
run 'SKIP=1 DECODE=0 bash /pkg/repository/dirty-0.0/builders/a/acl/buildpkg.acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "Of course we can't PACKAGE=0 if we don't BUILD=0 and INSTALL=0 the sources before."
write "That requires you know what are you doing."
write "The next feature was that the Builder take timings of each part."
run 'cat /pkg/metadata/dirty-0.0/acl-2.3.2-x86_64-1_MLFS_current_Viel/timings'
write "So that was a nice benchmark between diferent machines."
write "And help you to take breaks when you rebuild the packages."
write "Late we will talk about the SHARED libs part."
write "Now the package."
write "Runing the package without arguments show the Usage:"
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh'
write "Listing files inside the package."
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh list'
write "List files verbose inside the package."
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh verbose'
write "Install files on the system."
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh install'
write "What if I don't want to install a single file?"
run 'cat /pkg/config/tar-exclude-from-file.txt'
write "Removing the package files from the system."
run 'bash /pkg/repository/dirty-0.0/packages/d/dmenu/dmenu-5.4-x86_64-1_DIRTY_current_Viel.sh remove'
write "Now we can inspect the package log file."
run 'tail -10 /var/log/make.buildpkg.log'
write "Check the md5 of package files in the system."
run 'cd / && bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh checksum | tail -n +6 | md5sum -c'
write "And see the shared libraries a package need."
run 'bash /pkg/repository/dirty-0.0/packages/a/acl/acl-2.3.2-x86_64-1_MLFS_current_Viel.sh shared'
write "Late you can inspect the rest of the options: compare, epoch and echo."
fi

if [ $CH3 -eq 1 ] ; then
write "Chapter 3."
write "Ok so how to manage 3 scripts by x packages ... lot of files."
run 'ls -1 /pkg/repository/dirty-0.0/*/*/*/* | wc -l'
write "How can we manage it?"
write "Take a look at the repo-status script."
run 'bash /pkg/tools/scripts/repo-status.sh | head -20'
write "M when the maker exist."
write "B when the builder exist."
write "Same for P package."
write "I when was installed."
write "V if the scripts are the last version."
write "And L if it are the last installed in the package install logs."
write "You can see the full description inside the repo-status.sh script."
write "Interested in how to automate updates?"
write "What libraries are missing?"
write "That's what run.repo.list.sh scripts do."
write "What are a repo list?"
write "A list of packages that we ordered like build order."
run 'cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | head -30'
write "The run.repo.list.sh is a work in progress script."
write "It read the /tmp/run.repo.list file and take action on makers, buildes and packages."
write "So create a list to check updates. It takes a while. So only for the first 30 makers."
run 'cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | head -30 | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | sed "{s/^#/# C/g} ; {s/ M /   /g} ; {s/ B /   /g} ; {s/ P /   /g} ; {s/ I /   /g}" > /tmp/run.repo.list '
write "Inspect it."
run 'head -30 /tmp/run.repo.list'
write "I deleted the M B P I because each LETTER run an action and I only want to check for updates for now."
write "The C will run the CHECK_RELEASE=1 for the respective maker line. Lets run the repo list."
run 'bash /pkg/tools/scripts/run.repo.list.v2.sh'
write "This make some links on /tmp/updates/repository/"
run 'ls -1 /tmp/updates/repository/'
write "To the makers up to date."
run 'ls -1 /tmp/updates/repository/makers-up-to-date/'
write "To he makers failed."
run 'ls -1 /tmp/updates/repository/makers-failed/'
write "And to the makers with new version."
run 'ls -1 /tmp/updates/repository/makers-with-new-ver/'
write "Anyway we can inspect again the /tmp/run.repo.list to see the status of the executed list."
run 'head -30 /tmp/run.repo.list'
write "N was for new sources versions available."
write "F for failed requests."
write "s for skip. Blacklisted makers or builders. S for blacklisted packages."
write "You can see the full description of actions inside run.repo.list.sh script."
write "We can inspect the blacklisted directory with the links to makers, builders or packages to skip."
run 'ls -1 /pkg/blacklist/'
write "Returning at run.repo.list.sh work in progress script."
write "The plan was to add arguments to the script that will automate the creation of lists and automate a little more."
write "So in next versions we will only need to run run.repo.list.sh update"
write "Now we can execute run.repo.list.sh again, the N will create the new maker with the new version of the sources."
write "And the failed request will check again for new sources versions."
run 'bash /pkg/tools/scripts/run.repo.list.v2.sh'
write "Now with the new makers created we can search for it on the repo status (repo-status.sh)."
run 'cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V "'
write "Create a new run list with this new makers only."
run 'cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | grep " M      " | sed "s/#/#  /g" > /tmp/run.repo.list'
write "Inspect it."
run 'head -30 /tmp/run.repo.list'
write "And run the list. M will execute the maker so it will try to download the new sources and create the builder."
run 'bash /pkg/tools/scripts/run.repo.list.v2.sh'
write "As you can see the new maker that was copied from the old version have incorrect hashes that need to be verified and updated."
write "It is recomended to inspect the Changelog of the new sources too, you know."
write "After update the new hashes and read about the changes, we can run the new maker to create the builder that will create the package."
fi

if [ $CH4 -eq 1 ] ; then
write "Chapter 4."
write "How to update the makers source hashes."
write "When we copy the old maker *tcl-8.6.16* to create the new maker script version *tcl-8.6.17* it have the old sources hashes for tcl8.6.16-src.tar.gz."
write "So we need update with the new source hashes for the files the new maker will download, like tcl8.6.17-src.tar.gz."
write "Let go. Inspect the /tmp/run.repo.list"
run 'head -30 /tmp/run.repo.list'
write "Then run the run.repo.list.sh script, the M will run the maker that will try download the sources under /tmp/sources-all/"
run 'bash /pkg/tools/scripts/run.repo.list.v2.sh'
run 'ls -la /tmp/sources-all/'
write "As said, Edit the maker and update the hash."
write 'vi /pkg/repository/dirty-0.0/makers/t/tcl/make.buildpkg.tcl-8.6.17-x86_64-1_MLFS_current_Viel.sh'
vi /pkg/repository/dirty-0.0/makers/t/tcl/make.buildpkg.tcl-8.6.17-x86_64-1_MLFS_current_Viel.sh
write "Then rerun the run.repo.list.sh script, the M will stay because the first run wasn't successfull."
run 'head -30 /tmp/run.repo.list'
run 'bash /pkg/tools/scripts/run.repo.list.v2.sh'
write "Doing it for lot of files it becomes a repetitive and tiring task."
write "MLFS and GLFS have it hashes and lists to download files."
write "I prefer to do mannual verification, for now."
write "I recoment to update all makers in a row and do not build B and package P at same time."
write "To help and check we share all our hashes too."
write "Because time, as example we will do only the t subdir."
run 'grep "sha256sum -c" /pkg/repository/*/builders/t/*/* | cut -d \" -f2 | sort -u -k2 | head -30'
write "Take a look at /pkg/tools/scripts/CHECKSUMS-generate.sh"
write "Maybe I will add an option to print the URL on the makers to make a full download list and automate the hash check. Will see."
fi




