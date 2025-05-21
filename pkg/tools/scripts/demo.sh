#!/bin/bash

# Script to run for make a demo video.

#ps='\s-\v\$'
#echo "${ps@P}"

run(){
comm="$1"
delay=0.15

ps='\s-\v\$'
echo -n "${ps@P} "
for ((i = 0; i < ${#comm}; i++)); do
    echo -n "${comm:$i:1}"
    sleep $delay
done
echo -en "\n" ; echo "$comm" | bash
#echo -e "\n $comm" | bash
}


run "uname -a"
sleep 1
# package usage
run 'bash /pkg/repository/dirty-0.0/packages/b/bc/bc-1.08.1-x86_64-1_MLFS_current_Viel.sh'
sleep 2
# package list
run 'bash /pkg/repository/dirty-0.0/packages/b/bc/bc-1.08.1-x86_64-1_MLFS_current_Viel.sh list'
sleep 2
# package verbose
run 'bash /pkg/repository/dirty-0.0/packages/b/bc/bc-1.08.1-x86_64-1_MLFS_current_Viel.sh verbose'

sleep 2

run 'SKIP=1 DECODE=0 bash /pkg/repository/dirty-0.0/builders/p/Python/buildpkg.Python-3.13.3-x86_64-1_MLFS_current_Viel.sh'
sleep 3
run 'bash /pkg/tools/scripts/repo-status.sh gettext'
#sleep 1
#run 'CHECK_RELEASE=1  bash /pkg/repository/dirty-0.0/makers/g/gettext/make.buildpkg.gettext-0.24-x86_64-1_MLFS_current_Viel.sh'
sleep 2
run 'cat /pkg/metadata/MLFSCHROOT/Python-3.13.3-x86_64-1_MLFSCHROOT_current_Viel/timings'
sleep 3
run 'grep Builder /pkg/metadata/MLFSCHROOT/*/timings'



