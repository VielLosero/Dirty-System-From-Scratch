#!/bin/bash

# ls -1 /pkg/repository/dirty-0.1/packages/*/* | sed 's%.*/%%g' | sed 's/-[^-]*-[^-]*-[^-]*$//g'

#echo -e "d w 0 2 1  po Py pl " | tr ' ' '\n' | LC_COLLATE="" sort | xargs

# some strange file will cry 
for i in $(ls -1 /pkg/repository/dirty-0.1/makers/*/*/*) ; do pathpkg=${i%-*-*-*.sh} ; file=${pathpkg##*/} ; echo ${file/make.buildpkg./} ;done | LC_COLLATE=  sort -u

#find /pkg/repository/dirty-0.1/makers/*/* -maxdepth 0 -type d | sort -u
#find /pkg/repository/dirty-0.1/builders/*/* -maxdepth 0 -type d | sort -u
#find /pkg/repository/dirty-0.1/packages/*/* -maxdepth 0 -type d | sort -u

# grep pkg from all files, if they are in a bad dir too,
# like old /pkg/repository/dirty-0.1/packages/l/linux-mainline/linux_mainline-6.14_rc3-x86_64-1_LFS_r12.2_multilib.sh 
#                                               -------------      ----
#ls -1 /pkg/repository/dirty-0.1/*/*/*/* | sed 's%.*/%%g' | sed 's/^make\.buildpkg\.//g' | sed 's/^buildpkg\.//g' | sed 's/\.sh$//g' |  sed 's/-[^-]*-[^-]*-[^-]*$//g' | sort -u


