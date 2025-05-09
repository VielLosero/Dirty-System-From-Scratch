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
UPDATEDIR_REPO_MAKERS=/tmp/updates/repository/makers
[ ! -d $UPDATEDIR_REPO_MAKERS ] && mkdir -vp $UPDATEDIR_REPO_MAKERS

if [ -e /pkg/tools/scripts/repo-status.sh ] ; then 

  # can be replaced with repo-status lines. Exist maker, exist builder, no package, no installed, no blacklisted, last version, not in logs.
  for file in  $(bash /pkg/tools/scripts/repo-status.sh | grep " M           V - " | grep -v LFSCHROOT | sed 's/ M           V - //' ) ; do 
    if [ -h $UPDATEDIR_REPO_MAKERS/make.buildpkg.${file}.sh ] ; then
      true
    else
      ln -s $REPODIR/makers/*/*/make.buildpkg.${file}.sh $UPDATEDIR_REPO_MAKERS 
    fi
  done
  
  # Show builders's links.
  if [ -z "$(ls -1A $UPDATEDIR_REPO_MAKERS )"  ] ; then
  	echo ""
  	echo "No updates found."
  else
  	echo ""
  	echo "Makers's links to upgrade repository builders."
  	ls -1 $UPDATEDIR_REPO_MAKERS/*
  fi
else
  echo "/pkg/tools/scripts/repo-status.sh not found."
fi
