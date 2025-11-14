#!/bin/bash

# Version 0.0.1

#cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do echo "Adding $pkg to list." ; bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | sed 's/#/# C/g ; s/ M /   /g ; s/ B /   /g ; s/ P /   /g ; s/ I /   /g' > /tmp/run.repo.list

REPO_PKG_LIST=/pkg/tools/lists_of_packages/dirty-0.0_current_list.txt
TMP_RUN_REPO_LIST=/tmp/run.repo.list
CREATE_CHECK_RELEASE_LIST=0
CREATE_NEW_MAKERS_LIST=0
CREATE_BUILD_INSTALL_LIST=0

if [ -e $TMP_RUN_REPO_LIST ] ; then
  if grep "^# C " $TMP_RUN_REPO_LIST ; then
    echo "Found \"C\" sources to check."
    
  elif grep "^# N " $TMP_RUN_REPO_LIST ; then
    echo "Found \"N\" new makers to do."
  
  elif grep "^# F " $TMP_RUN_REPO_LIST ; then
    echo "Found \"F\" failed sources to recheck."

  elif grep "^# . M " $TMP_RUN_REPO_LIST ; then
    echo "Found \"M\" makers to run."
  
  elif grep "^# . . B " $TMP_RUN_REPO_LIST ; then
    echo "Found \"B\" builder to run."

  elif grep "^# . . . . I " $TMP_RUN_REPO_LIST ; then
    echo "Found \"I\" package to install."
  # if pass just here nothing to do on the list .. so
  else 
    if grep "################### CHECK_RELEASE_LIST" $TMP_RUN_REPO_LIST ; then
      CREATE_NEW_MAKERS_LIST=1
    elif grep "################### NEW_MAKERS_LIST" $TMP_RUN_REPO_LIST ; then
      CREATE_BUILD_INSTALL_LIST=1
    elif grep "################### BUILD_INSTALL_LIST" $TMP_RUN_REPO_LIST ; then
      echo "All up to date."
      exit 0
    else
      CREATE_CHECK_RELEASE_LIST=1
    fi
  fi
else
    CREATE_CHECK_RELEASE_LIST=1
fi

if [ $CREATE_CHECK_RELEASE_LIST -eq 1 ] ; then 
  if [ -e $TMP_RUN_REPO_LIST ] ; then
    echo "Removing $TMP_RUN_REPO_LIST to run CHECK_RELEASE."
    rm $TMP_RUN_REPO_LIST || exit 
  fi
  echo "Creating new $TMP_RUN_REPO_LIST from $REPO_PKG_LIST"
  echo "################### CHECK_RELEASE_LIST" > $TMP_RUN_REPO_LIST
  cat $REPO_PKG_LIST | grep -v "^#"  | while read pkg ; do
    #
    #PKG=$(bash /pkg/tools/scripts/repo-status.sh ${pkg} | grep " V " | grep "\-[0-9]\.[0-9]\.[0-9]_")
    PKG=$(bash /pkg/tools/scripts/repo-status.sh ${pkg} | grep " V " )
    if [ -z "$PKG" ] ; then
      echo "[!] $pkg maker, builder, package not found."
    elif [ "$(echo $PKG | wc -l)" -gt 1 ] ; then
      echo "[!] $pkg match with more than 1 file."
    else
      LINE=$(echo "$PKG" | sed 's/#/# C/g ; s/ M /   /g ; s/ B /   /g ; s/ P /   /g ; s/ I /   /g' )
      echo "[+]  $LINE"
      echo "$LINE" >> $TMP_RUN_REPO_LIST
    fi
  done 
fi

if [ $CREATE_NEW_MAKERS_LIST -eq 1 ] ; then
  # run new makers
  #cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep "# M           V " | sed 's/#/#  /g' > /tmp/run.repo.list
  if [ -e $TMP_RUN_REPO_LIST ] ; then
    echo "Removing $TMP_RUN_REPO_LIST to run NEW_MAKERS."
    rm $TMP_RUN_REPO_LIST || exit 
  fi
  echo "Creating new $TMP_RUN_REPO_LIST from $REPO_PKG_LIST"
  echo "################### NEW_MAKERS_LIST" > $TMP_RUN_REPO_LIST
  cat $REPO_PKG_LIST | grep -v "^#"  | while read pkg ; do
    #
    PKG=$(bash /pkg/tools/scripts/repo-status.sh ${pkg} | grep "# M       " | grep " V " ) 
    if [ -z "$PKG" ] ; then
      echo "[-] $pkg maker, builder, package not found."
    elif [ "$(echo $PKG | wc -l)" -gt 1 ] ; then
      echo "[!] $pkg match with more than 1 file."
    else
      #LINE=$(echo "$PKG" | sed 's/#/# C/g ; s/ M /   /g ; s/ B /   /g ; s/ P /   /g ; s/ I /   /g' )
      LINE=$(echo "$PKG" | sed 's/#/#  /g')
      echo "[+]  $LINE"
      echo "$LINE" >> $TMP_RUN_REPO_LIST
    fi
  done 
fi

if [ $CREATE_BUILD_INSTALL_LIST -eq 1 ] ; then
  if [ -e $TMP_RUN_REPO_LIST ] ; then
    echo "Removing $TMP_RUN_REPO_LIST to run BUILD_INSTALL."
    rm $TMP_RUN_REPO_LIST || exit 
  fi
  echo "Creating new $TMP_RUN_REPO_LIST from $REPO_PKG_LIST"
  echo "################### BUILD_INSTALL_LIST" > $TMP_RUN_REPO_LIST
  cat $REPO_PKG_LIST | grep -v "^#"  | while read pkg ; do
    #
    PKG=$(bash /pkg/tools/scripts/repo-status.sh ${pkg} | grep "# M B     " | grep " V " ) 
    if [ -z "$PKG" ] ; then
      echo "[-] $pkg maker, builder, package not found."
    elif [ "$(echo $PKG | wc -l)" -gt 1 ] ; then
      echo "[!] $pkg match with more than 1 file."
    else
      #LINE=$(echo "$PKG" | sed 's/#/# C/g ; s/ M /   /g ; s/ B /   /g ; s/ P /   /g ; s/ I /   /g' )
      LINE=$(echo "$PKG" | sed 's/# M B     /#     B   I /g' ) 
      echo "[+]  $LINE"
      echo "$LINE" >> $TMP_RUN_REPO_LIST
    fi
  done 

fi

echo "- Runing the list ..."

bash /pkg/tools/scripts/run.repo.list.sh






