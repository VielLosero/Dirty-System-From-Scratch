#!/bin/bash

# make a ordered list with repo-status.sh like:
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " > /tmp/run.repo.list
# sh-5.2# cat /tmp/run.repo.list | head -10
# M B P I     V L make_buildpkg_dirty_package_manager-0.0.1-all-1_DIRTY_current_Viel.0.0.3
# M B P I     V L filesystem_hierarchy-3.0-all-1_DIRTY_current_Viel.0.0.3
# M B P I     V L man-pages-6.13-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L iana-etc-20250407-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L glibc-2.41-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L tzdata-2025b-all-1_MLFS_current_Viel.0.0.3
# M B P I     V L zlib-1.3.1-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L bzip2-1.0.8-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L xz-5.8.1-x86_64-1_MLFS_current_Viel.0.0.3
# M B P I     V L lz4-1.10.0-x86_64-1_MLFS_current_Viel.0.0.3
#echo " M B P I S/s U/u/R V L/l package_name "

# Edit the list /tmp/run.repo.list as:
# Add # at start of each line.
# C will Check for new releases.
# D will try decode sources from builder than have it.
# M will run the maker again.
# B will run the builder again.
# I will run the package with install option.
# Example to make a list:
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | sed 's/#/# C/g' > /tmp/run.repo.list
# # D/C M B P I     V L glibc-2.41-x86_64-1_MLFS_current_Viel.0.0.3
# when taks wass successfull will edit /tmp/run.repo.list and remove successfull task.

cd $(dirname $0) && CWD=$(pwd) || exit 1

ROOT=${ROOT:-}
RUN_REPO_LIST=$ROOT/tmp/run.repo.list
REPO=${REPO:-dirty-0.0}
REPODIR=$ROOT/pkg/repository/$REPO
PKG_DB="$ROOT/pkg/installed"
BLACKLIST="$ROOT/pkg/blacklist"

line_num=0
cat $RUN_REPO_LIST | while read line ; do 
CHECK_REL=0
DECODE_SOURCES=0
RUN_MAKER=0
RUN_BUILDER=0
RUN_PACKAGE=0
current_line="$line"
line_num=$(( line_num +1 ))
echo "Processing:$current_line"
#sed -n "${line_num}p" $RUN_REPO_LIST
# Check if it is needed to check release.
if [ "${current_line:2:1}" == "C" ] || [ "${current_line:2:1}" == "F" ] ; then CHECK_REL=1 ; fi
if [ "${current_line:2:1}" == "N" ] ; then CHECK_REL=2 ; fi
# Check if it is needed to extract sources.
if [ "${current_line:2:1}" == "D" ] ; then DECODE_SOURCES=1 ; fi
# Check if it is needed to run the maker.
if [ "${current_line:4:1}" == "M" ] ; then RUN_MAKER=1 ; fi
# Check if it is needed to run the builder.
if [ "${current_line:6:1}" == "B" ] ; then RUN_BUILDER=1 ; fi
# Check if it is needed to install the package.
if [ "${current_line:10:1}" == "I" ] ; then RUN_PACKAGE=1 PACKAGE_ARG=install ; fi

#SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(date +%s)}"
SOURCE_DATE_EPOCH="1746190997"

# make the list
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | sed 's/#/# C/g' > /tmp/run.repo.list
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep " V " | sed 's/#/# N/g' > /tmp/run.repo.list
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep "# M           V " | sed 's/#/#  /g' > /tmp/run.repo.list
# cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do bash /pkg/tools/scripts/repo-status.sh ${pkg}  ; done | grep "# M B         V " | sed 's/#/#  /g' | sed 's/M B    /  B   I/g' > /tmp/run.repo.list


pkg_name=$(echo "${current_line}" | cut -c 21-)
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

# Check correct vars for cut -c 21-.
if [ -e $maker_full_path ] || [ -e $builder_full_path ] || [ -e $package_full_path ] ; then
  true
else
  exit 1
fi

if [ -h $BLACKLIST/*$builder ] ; then
  echo "Blacklisted: $BLACKLIST/*$builder"
  sed -i "${line_num}s/ C / s /" $RUN_REPO_LIST || exit 1
  sed -i "${line_num}s/ N / s /" $RUN_REPO_LIST || exit 1
  sed -i "${line_num}s/ M / s /" $RUN_REPO_LIST || exit 1
  sed -i "${line_num}s/ B / s /" $RUN_REPO_LIST || exit 1
  CHECK_REL=0
  DECODE_SOURCES=0
  RUN_MAKER=0
  RUN_BUILDER=0
  RUN_PACKAGE=0
fi
if [ -h $BLACKLIST/*$package ] ; then
  echo "Blacklisted: $BLACKLIST/*$package"
  sed -i "${line_num}s/ C / S /" $RUN_REPO_LIST || exit 1
  sed -i "${line_num}s/ M / S /" $RUN_REPO_LIST || exit 1
  sed -i "${line_num}s/ I / S /" $RUN_REPO_LIST || exit 1
  CHECK_REL=0
  DECODE_SOURCES=0
  RUN_MAKER=0
  RUN_BUILDER=0
  RUN_PACKAGE=0
fi

if [ $CHECK_REL -eq 1 ] ; then
  # pass the most current versions makers to check updates.sh 
  $CWD/helpers/update-repository-makers-helper.v2.sh ${line_num} $maker_full_path &
fi
if [ $CHECK_REL -eq 2 ] ; then
  CHECK_RELEASE=1 NEW=0 bash $maker_full_path 
  EXIT=$?
  if [ $EXIT -eq 3 ] || [ $EXIT -eq 4 ] ; then 
    sed -i "${line_num}s/ N /   /" $RUN_REPO_LIST || exit 1
  else
    echo "${pkg_name} NEW maker failed."
  fi
fi
if [ $DECODE_SOURCES -eq 1 ] ; then
  echo "Tring to decode $name-$ver sources from builders."
  SKIP=1 DECODE=0 bash $builder_full_path
  if [ $? -eq 0 ] ; then 
    sed -i "${line_num}s/ D /   /" $RUN_REPO_LIST || exit 1
  else 
    SKIP=1 DECODE=0 REPO=* bash $REPODIR/builders/$first_pkg_char/$name/buildpkg.$name-$ver*
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
    # Todo: Sound alert when done a line
    bash /pkg/tools/tone
    sed -i "${line_num}s/ B /   /" $RUN_REPO_LIST || exit 1
  else exit 1 ; fi
fi
if [ $RUN_PACKAGE -eq 1 ] ; then 
  #echo "bash $package_full_path $PACKAGE_ARG"
  # find libs needed 
  cat /pkg/installed/*/index | grep "\.so$" | rev | cut -d / -f1 | rev | sort -u >/tmp/installed1
  cat /pkg/installed/*/index | grep "\.so\." | rev | cut -d / -f1 | rev | sort -u >/tmp/installed2
  cat /pkg/installed/*/needed-libs | cut -d':' -f2 | sed 's/,/\n/g' | sort -u > /tmp/needed
  cat /tmp/installed1 /tmp/installed2 | sort -u >/tmp/installed
  comm -13 /tmp/installed /tmp/needed > /tmp/needed.libs.not.found.${pkg_name}.before

  # install
  bash $package_full_path $PACKAGE_ARG
  if [ $? -eq 0 ] ; then
    sed -i "${line_num}s/ I /   /" $RUN_REPO_LIST || exit 1
  else exit 1 ; fi

  # remove old pkg
  if ls -1d /pkg/installed/$name-[0-9]* >/dev/null ; then 
    echo "Packages installed!"
    ls -1d /pkg/installed/$name-[0-9]*
    for p in $(ls -1d /pkg/installed/$name-[0-9]*-$arch-${rel}* | grep -v "$name-$ver" ) ; do
      remove_pkg=${p##/}
      echo " --> Removing old package $p"
      echo "bash  /pkg/tools/scripts/removepkg.sh $p || exit 1"
    done
  fi
  
  # then find needed libs again.
  cat /pkg/installed/*/index | grep "\.so$" | rev | cut -d / -f1 | rev | sort -u >/tmp/installed1
  cat /pkg/installed/*/index | grep "\.so\." | rev | cut -d / -f1 | rev | sort -u >/tmp/installed2
  cat /pkg/installed/*/needed-libs | cut -d':' -f2 | sed 's/,/\n/g' | sort -u > /tmp/needed
  cat /tmp/installed1 /tmp/installed2 | sort -u >/tmp/installed
  comm -13 /tmp/installed /tmp/needed > /tmp/needed.libs.not.found.${pkg_name}.after

  if diff /tmp/needed.libs.not.found.${pkg_name}.before /tmp/needed.libs.not.found.${pkg_name}.after | grep "^>" ; then
    echo "New lost needed_libs found. Exiting."
    exit 1
  fi

fi




# Todo: Sound alert when done a line
echo "++++++++++++++++++++++++++++++"                  
done




