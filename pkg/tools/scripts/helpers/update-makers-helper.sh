#!/bin/bash

cd $(dirname $0) && CWD=$(pwd) || exit 1

UPDATE_CHECKED_DIR=/tmp/updates/checked
UPDATE_FAILED_DIR=/tmp/updates/failed
UPDATE_NEED_UPDATE_DIR=/tmp/updates/need_update

[ ! -d $UPDATE_CHECKED_DIR ] && mkdir -vp $UPDATE_CHECKED_DIR
[ ! -d $UPDATE_FAILED_DIR ] && mkdir -vp $UPDATE_FAILED_DIR
[ ! -d $UPDATE_NEED_UPDATE_DIR ] && mkdir -vp $UPDATE_NEED_UPDATE_DIR

if [ $# -eq 1 ] ; then
	if [ -e $1 ] ; then
		file=${1##*/}
		if [ -h $UPDATE_CHECKED_DIR/$file ] ; then
      echo "Up to date: $file"
		elif [ -h $UPDATE_NEED_UPDATE_DIR/$file ] ; then
      echo "Need update: $file"
    else
		#CHECK_RELEASE=1 bash $1
    last=$(CHECK_RELEASE=1 bash $1)
		result=$?
		case "$result" in
			0)
				echo "Up to date: $file"
				ln -s $1 $UPDATE_CHECKED_DIR/$file
				if [ -h $UPDATE_NEED_UPDATE_DIR/$file ] ; then
					rm $UPDATE_NEED_UPDATE_DIR/$file
				fi
				if [ -h $UPDATE_FAILED_DIR/$file ] ; then
					rm $UPDATE_FAILED_DIR/$file
				fi

				;;
			1)
				echo "Failed: $file"
				if [ ! -h $UPDATE_NEED_UPDATE_DIR/$file ] ; then
					if [ ! -h $UPDATE_FAILED_DIR/$file ] ; then
						ln -s $1 $UPDATE_FAILED_DIR/$file
					fi
				fi
				;;
			2)
				echo "Need update: $file --> $(echo "$last" | grep "Version check" | cut -d' ' -f4)"
        #echo "CHECK_RELEASE=1 NEW=0 bash $1"
				if [ ! -h $UPDATE_NEED_UPDATE_DIR/$file ] ; then
					ln -s $1 $UPDATE_NEED_UPDATE_DIR/$file
				fi
				if [ -h $UPDATE_FAILED_DIR/$file ] ; then
					rm $UPDATE_FAILED_DIR/$file
				fi
				;;
			*)	echo "Error"
				;;
	
		esac
		fi
	fi
fi

