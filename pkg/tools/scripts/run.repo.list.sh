#!/bin/bash

# make a ordered list with repo-status.sh like:
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " > /tmp/run.repo.list
# sh-5.2# cat /tmp/run.repo.list | head -10
#  M B P I     V L make_buildpkg_dirty_package_manager-0.0.1-all-1_DIRTY_current_Viel.0.0.3
#  M B P I     V L filesystem_hierarchy-3.0-all-1_DIRTY_current_Viel.0.0.3
#  M B P I     V L man-pages-6.13-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L iana-etc-20250407-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L glibc-2.41-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L tzdata-2025b-all-1_MLFS_current_Viel.0.0.3
#  M B P I     V L zlib-1.3.1-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L bzip2-1.0.8-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L xz-5.8.1-x86_64-1_MLFS_current_Viel.0.0.3
#  M B P I     V L lz4-1.10.0-x86_64-1_MLFS_current_Viel.0.0.3

# Edit the list /tmp/run.repo.list as:
# Add # at start of each line.
# D will try decode sources from builder than have it.
# M will run the maker again.
# B will run the builder again.
# I will run the package with install option.
# Example after edit the list:
# # D M B I glibc-2.41-x86_64-1_MLFS_current_Viel.0.0.3
# when taks wass successfull will edit /tmp/run.repo.list and remove successfull task.

ROOT=${ROOT:-}
RUN_REPO_LIST=$ROOT/tmp/run.repo.list
REPO=dirty-0.0
REPODIR=$ROOT/pkg/repository/$REPO
INSTALLED_DIR="$ROOT/installed"
BLACKLISTED_DIR="$ROOT/blacklisted"

line_num=0
cat $RUN_REPO_LIST | while read line ; do 
DECODE_SOURCES=0
RUN_MAKER=0
RUN_BUILDER=0
RUN_PACKAGE=0
current_line="$line"
line_num=$(( line_num +1 ))
echo "Processing:$current_line"
#sed -n "${line_num}p" $RUN_REPO_LIST
# Check if it is needed to extract sources.
if [ "${current_line:2:1}" == "D" ] ; then DECODE_SOURCES=1 ; fi
# Check if it is needed to run the maker.
if [ "${current_line:4:1}" == "M" ] ; then RUN_MAKER=1 ; fi
# Check if it is needed to run the builder.
if [ "${current_line:6:1}" == "B" ] ; then RUN_BUILDER=1 ; fi
# Check if it is needed to install the package.
if [ "${current_line:8:1}" == "I" ] ; then RUN_PACKAGE=1 PACKAGE_ARG=install ; fi

#SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"
SOURCE_DATE_EPOCH="1746190997"

pkg_name=$(echo "${current_line}" | cut -c 11-)
maker=make.buildpkg.${pkg_name}.sh
builder=buildpkg.${pkg_name}.sh
package=${pkg_name}.sh
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
maker_full_path="$REPODIR/makers/$first_pkg_char/$name/$maker"
builder_full_path="$REPODIR/builders/$first_pkg_char/$name/$builder"
package_full_path="$REPODIR/packages/$first_pkg_char/$name/$package"

if [ $DECODE_SOURCES -eq 1 ] ; then
  echo "Tring to decode $name-$ver sources from builders."
  SKIP=1 DECODE=0 bash $builder_full_path
  if [ $? -eq 0 ] ; then 
    sed -i "${line_num}s/ D /   /" $RUN_REPO_LIST || exit 1
  else 
    SKIP=1 DECODE=0 bash $REPODIR/builders/$first_pkg_char/$name/buildpkg.$name-$ver*
    if [ $? -eq 0 ] ; then 
      sed -i "${line_num}s/ D /   /" $RUN_REPO_LIST || exit 1
    else exit 1 ; fi
  fi
fi
if [ $RUN_MAKER -eq 1 ] ; then 
  #echo "bash $maker_full_path"
  bash $maker_full_path
  if [ $? -eq 0 ] ; then 
    sed -i "${line_num}s/ M /   /" $RUN_REPO_LIST || exit 1
  else exit 1 ; fi
fi
if [ $RUN_BUILDER -eq 1 ] ; then 
  #echo "bash $builder_full_path"
  SOURCE_DATE_EPOCH="1746190997" bash $builder_full_path
  if [ $? -eq 0 ] ; then 
    bash /pkg/tools/tone
    sed -i "${line_num}s/ B /   /" $RUN_REPO_LIST || exit 1
  else exit 1 ; fi
fi
if [ $RUN_PACKAGE -eq 1 ] ; then 
  #echo "bash $package_full_path $PACKAGE_ARG"
  bash $package_full_path $PACKAGE_ARG
  if [ $? -eq 0 ] ; then
    sed -i "${line_num}s/ I /   /" $RUN_REPO_LIST || exit 1
  else exit 1 ; fi
fi
# Sound alert when done a line
echo "++++++++++++++++++++++++++++++"                  
done


