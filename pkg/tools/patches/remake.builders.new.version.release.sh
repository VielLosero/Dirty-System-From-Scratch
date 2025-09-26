#!/bin/bash

REPO=${REPO:-dirty-0.0} # * all repos
REPODIR=/pkg/repository/$REPO
PKG_DB=/pkg/installed
BLACKLIST=/pkg/blacklist
LOGFILE=/var/log/make.buildpkg.log


cat /pkg/tools/lists_of_packages/dirty-0.0_current_list.txt | grep -v "^#"  | while read pkg ; do 

bash /pkg/tools/scripts/repo-status.sh ${pkg}  | grep " V " | grep "\-.\..\.._"  | while read line ; do


pkg_name="$(echo "$line" | cut -c 19-)"
name="${pkg_name%-*-*-*}" 
pkg_ver="${pkg_name%-*-*}" ; ver="${pkg_ver/$name-/}"
pkg_arch="${pkg_name%-*}" ; arch=${pkg_arch/$name-$ver-/}
rel_and_tag=${pkg_name/$name-$ver-$arch-/}
first_pkg_char=$(printf %.1s ${name,})
rel=${rel_and_tag%%_*}
tag=${rel_and_tag/${rel}_}
rel_m=${rel%%.*}
rel_p=${rel##*.}
rel_b=${rel/${rel_m}.} ; rel_b=${rel_b/.${rel_p}}
tag1=${tag/_*}
tag2=${tag/${tag1}_} ; tag2=${tag2/_*}
tag3=${tag/${tag1}_${tag2}_}

#echo "$pkg_name"
if [ ! -e "$REPODIR/builders/$first_pkg_char/$name/buildpkg.$name-$ver-$arch-${rel}_${tag}.sh" ] ; then
ls -1 $REPODIR/builders/$first_pkg_char/$name/buildpkg.$name-$ver-$arch-1_${tag}.sh || exit 1 && \
SKIP=1 DECODE=0 bash $REPODIR/builders/$first_pkg_char/$name/buildpkg.$name-$ver-$arch-1_$tag.sh || exit 1 && \
cp /tmp/dirty-0.0/sources-all/* /tmp/sources-all/
#sleep 5
bash $REPODIR/makers/$first_pkg_char/$name/make.buildpkg.$name-$ver-$arch-${rel}_${tag}.sh || exit 1 && \
rm /tmp/sources-all/* 
rm /tmp/dirty-0.0/sources-all/*
echo +++++++++++++++++++++++++++++++++++++++++++++++++
fi

done
done

