#!/bin/bash

cd $(dirname $0) && CWD=$(pwd) || exit 1

RUN_REPO_LIST=$ROOT/tmp/run.repo.list
BLACKLIST=/pkg/blacklist

UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver

[ ! -d $UPDATEDIR_REPO_MAKERS_UP_TO_DATE ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_UP_TO_DATE
[ ! -d $UPDATEDIR_REPO_MAKERS_FAILED ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_FAILED
[ ! -d $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER

if [ $# -eq 2 ] ; then
  line_num=$1
  if [ -z ${line_num} ] ; then echo "No line number, exiting." && exit 1 ; fi
	if [ -e $2 ] ; then
		file=${2##*/}
		if [ -h $UPDATEDIR_REPO_MAKERS_UP_TO_DATE/$file ] ; then
      echo "Up to date: $file"
      sed -i "${line_num}s/ C /   /" $RUN_REPO_LIST || exit 1
		elif [ -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
      echo "Need upgrade: $file"
      sed -i "${line_num}s/ C / N /" $RUN_REPO_LIST || exit 1
		elif [ -h $BLACKLIST/$file ] ; then
      echo "Blacklisted: $file"
      sed -i "${line_num}s/ C / S /" $RUN_REPO_LIST || exit 1
    else
		#CHECK_RELEASE=1 bash $1
    last=$(CHECK_RELEASE=1 bash $2 )
		result=$?
		case "$result" in
			0)
				echo "Up to date: $file"
				ln -s $2 $UPDATEDIR_REPO_MAKERS_UP_TO_DATE/$file
				if [ -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file
				fi
				if [ -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_FAILED/$file
				fi
        sed -i "${line_num}s/ C /   /" $RUN_REPO_LIST || exit 1
				;;
			1)
				echo "Failed: $file"
				if [ ! -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					if [ ! -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
						ln -s $2 $UPDATEDIR_REPO_MAKERS_FAILED/$file
					fi
				fi
        sed -i "${line_num}s/ C / F /" $RUN_REPO_LIST || exit 1
				;;
			2)
				echo "Need upgrade: $file --> $(echo "$last" | grep "Version check" | cut -d' ' -f4)"
        #echo "CHECK_RELEASE=1 NEW=0 bash $1"
				if [ ! -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					ln -s $2 $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file
				fi
				if [ -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_FAILED/$file
				fi
        sed -i "${line_num}s/ C / N /" $RUN_REPO_LIST || exit 1
				;;
			*)	echo "Error"
				;;
	
		esac
		fi
	fi
fi


