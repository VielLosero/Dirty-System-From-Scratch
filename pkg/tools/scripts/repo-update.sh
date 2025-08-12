#!/bin/bash


REPO=${REPO:-*}
REPODIR=/pkg/repository/$REPO
REPOLIST=/pkg/tools/lists_of_packages/dirty-0.0_current_list.txt
UPDATEDIR_REPO_MAKERS_UP_TO_DATE=/tmp/updates/repository/makers-up-to-date
UPDATEDIR_REPO_MAKERS_FAILED=/tmp/updates/repository/makers-failed
UPDATEDIR_REPO_MAKERS_WITH_NEW_VER=/tmp/updates/repository/makers-with-new-ver

[ ! -d $UPDATEDIR_REPO_MAKERS_UP_TO_DATE ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_UP_TO_DATE
[ ! -d $UPDATEDIR_REPO_MAKERS_FAILED ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_FAILED
[ ! -d $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER ] && mkdir -vp $UPDATEDIR_REPO_MAKERS_WITH_NEW_VER

cd $(dirname $0) && CWD=$(pwd) || exit 1


# find orphan libs
cat /pkg/installed/*/index | grep "\.so\." | rev | cut -d / -f1 | rev | sort -u >/tmp/installed2
cat /pkg/installed/*/needed-libs | cut -d':' -f2 | sed 's/,/\n/g' | sort -u > /tmp/needed
cat /tmp/installed1 /tmp/installed2 | sort -u >/tmp/installed
comm -13 /tmp/installed /tmp/needed

