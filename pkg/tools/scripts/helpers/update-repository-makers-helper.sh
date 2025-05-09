#!/bin/bash

cd $(dirname $0) && CWD=$(pwd) || exit 1

UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver

[ ! -d $UPDATEDIR_REPO_MAKERS_UP_TO_DATE ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_UP_TO_DATE
[ ! -d $UPDATEDIR_REPO_MAKERS_FAILED ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_FAILED
[ ! -d $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER

if [ $# -eq 1 ] ; then
	if [ -e $1 ] ; then
		file=${1##*/}
		if [ -h $UPDATEDIR_REPO_MAKERS_UP_TO_DATE/$file ] ; then
      echo "Up to date: $file"
		elif [ -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
      echo "Need upgrade: $file"
    else
		#CHECK_RELEASE=1 bash $1
    last=$(CHECK_RELEASE=1 bash $1)
		result=$?
		case "$result" in
			0)
				echo "Up to date: $file"
				ln -s $1 $UPDATEDIR_REPO_MAKERS_UP_TO_DATE/$file
				if [ -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file
				fi
				if [ -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_FAILED/$file
				fi

				;;
			1)
				echo "Failed: $file"
				if [ ! -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					if [ ! -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
						ln -s $1 $UPDATEDIR_REPO_MAKERS_FAILED/$file
					fi
				fi
				;;
			2)
				echo "Need upgrade: $file --> $(echo "$last" | grep "Version check" | cut -d' ' -f4)"
        #echo "CHECK_RELEASE=1 NEW=0 bash $1"
				if [ ! -h $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file ] ; then
					ln -s $1 $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER/$file
				fi
				if [ -h $UPDATEDIR_REPO_MAKERS_FAILED/$file ] ; then
					rm $UPDATEDIR_REPO_MAKERS_FAILED/$file
				fi
				;;
			*)	echo "Error"
				;;
	
		esac
		fi
	fi
fi

