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

cd $(dirname $0) && CWD=$(pwd) || exit 1

UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver
UPDATEDIR_REPO_MAKERS=/tmp/updates/repository/makers

[ ! -d $UPDATEDIR_REPO_MAKERS_UP_TO_DATE ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_UP_TO_DATE
[ ! -d $UPDATEDIR_REPO_MAKERS_FAILED ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_FAILED
[ ! -d $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER
[ ! -d $UPDATEDIR_REPO_MAKERS ] && mkdir -vp $UPDATEDIR_REPO_MAKERS


if [ -z "$(ls -1A $UPDATEDIR_REPO_MAKERS )"  ] ; then
	echo ""
	echo "No builders to upgrade. No makers's links found."
else
# Run new makers from UPDATEDIR_REPO_MAKERS=/tmp/updates/repository/makers
for file in $(ls -1 $UPDATEDIR_REPO_MAKERS/* ) ; do
	echo ""
  bash $file || exit 1
  if [ $? -eq 0 ] ; then 
    rm -v $file
  fi
done
fi
