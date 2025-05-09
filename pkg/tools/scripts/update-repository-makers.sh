#!/bin/bash

# update-repository-makers --> will create links of makers that have new versions.
# upgrade-repository-makers --> will run CHECK_RELEASE=1 NEW=0 makers's links to create NEW versions of makers.

# update-repository-builders --> will create links of makers that don't have builders.
# upgrade-repository-builders --> will run makers's links to create new builders.

# update-repository-pacakges --> will create links of builders that don't have packages.
# upgrade-repository-packages --> will run builders's links to create new packages.

# update-packages --> link of packages that need upgrade.
# upgrade-packages --> install last and remove old.
# install-packages -->
# remove-packages -->


REPODIR=/pkg/repository/dirty-0.0
UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver

[ ! -d $UPDATEDIR_REPO_MAKERS_UP_TO_DATE ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_UP_TO_DATE
[ ! -d $UPDATEDIR_REPO_MAKERS_FAILED ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_FAILED
[ ! -d $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER

cd $(dirname $0) && CWD=$(pwd) || exit 1

# check if all files in makers need to be updated
# the file check-update-makers.sh use CHECK_RELEASE=1 to create symbolic links on /tmp/updates/needed_update to the makers that need update. 
# also check-update-makers.sh make symbolic links on /tmp/updates/checked to the makers that have been checked.
# and make symbolic links on /tmp/updates/failed to the makers that have failed to check new versions.
if [ -e $CWD/helpers/update-repository-makers-helper.sh ] ; then
	# this is same as cat all_makers_ordered_list.txt list but with this we get all makers that are or not in list.
	for file in $(ls -1 $REPODIR/makers/*/*/* | while read line ; do line1=${line##*/} ; line2=${line1/make.buildpkg./} ; name=${line2%-*-*-*} ; line3=${line2/$name/} ; line4=${line3#-*-*-*_} ; line5=${line4%%_*} ;echo ".${name}-[0-9]*_${line5}_*"  ; done | sort -u | while read list ; do ls $REPODIR/makers/*/*/*$list | sort -Vr | head -1 ; done) ; do
		# exclude blacklisted makers
		maker=$(echo $file | sed 's%.*/%%g')
		if [ -h /pkg/blacklist/$maker ] ; then
      echo "Blacklisted: $maker"
		else
			# pass the most current versions makers to check updates.
			$CWD/helpers/update-repository-makers-helper.sh $file &
		fi
	done 

else
	echo "Need update-repository-makers-helper.sh file."
	exit 1
fi

wait  # Don't execute the next command until subshells finish.
true

# Show if there are some failed links.
if [ -z "$(ls -1A $UPDATEDIR_REPO_MAKERS_FAILED )"  ] ; then
	# No updates failed
	true
else
	echo ""
	echo "List of makers that failed to check for new versions. Re run $0 again to fix."
       ls -1 $UPDATEDIR_REPO_MAKERS_FAILED
       exit 1
fi

# Show list of blacklisted makers.
if [ -z "$(ls -1A /pkg/blacklist )"  ] ; then
	echo ""
	echo "No blacklisted packages found."
else
	echo ""
	echo "List of blacklisted makers."
	ls -1 /pkg/blacklist/make.* | sed 's%.*/%%g'
fi

# Show list of makers to upgrade.
if [ -z "$(ls -1A $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER )"  ] ; then
	echo ""
	echo "No updates found."
else
	echo ""
	echo "List of makers that need upgrade."
	ls -1 $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER
fi

