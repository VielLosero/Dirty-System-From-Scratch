#!/bin/bash

# ls -1 /pkg/repository/dirty-0.1/packages/*/* | sed 's%.*/%%g' | sed 's/-[^-]*-[^-]*-[^-]*$//g'

name="$1"

ls -1 -r /pkg/repository/dirty-0.1/packages/*/*$1* | sed 's%.*/%%g'
#ls -1 /pkg/repository/dirty-0.1/packages/*/*$1* | sed 's%.*/%%g'


#for i in $(ls -1 /pkg/repository/dirty-0.1/makers/*/*) ; do pathpkg=${i%-*-*-*.sh} ; file=${pathpkg##*/} ; echo ${file/make.buildpkg./} ;done | LC_COLLATE=  sort -u

#for i in $(ls -1 /pkg/repository/dirty-0.1/makers/*/*linux*) ; do pathpkg=${i%-*-*-*.sh} ; file=${pathpkg##*/} ; echo ${file/make.buildpkg./} ;done | LC_COLLATE=  sort -u
