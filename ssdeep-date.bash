#!/bin/bash
dname="$1"
mapfile -t dirs < <(dirname $(cat ~/foo/bar/flvlist.txt ) | sort | uniq | grep -i -- "$dname")
let s=0
for i in "${dirs[@]}"
do
   tmpdir=$(mktemp -d)
   mapfile -t files < <(find "$i" -type f -iname "*.flv" 2>/dev/null)
   for n in "${files[@]}"
   do
      ffmpeg -i "$n" -vn -codec copy "${tmpdir}/$(basename ${n/.flv/.wav})" &>/dev/null
   done
   tmpdirs[$s]=${tmpdir}
   let s=$s+1
done
ssdeep $(find "${tmpdir}" -type f -iname "*.wav" 2>/dev/null) > /tmp/ssdeep.txt
mapfile -t files < <(find "${tmpdir}" -type f -iname "*.wav" 2>/dev/null)
for i in "${files[@]}"
do
   mapfile -t matches < <(ssdeep -m /tmp/ssdeep.txt "$i" 2>/dev/null | cut -d" " -f1,3,4)
   for m in "${matches[@]}"
   do
      file1=$(basename $(echo "$m" | cut -d" " -f1 | sed -e 's/.wav/.flv/g'))
      file2=$(basename $(echo "$m" | cut -d" " -f2 | sed -e 's/.wav/.flv/g'))
      let chance=$(echo "$m" | cut -d" " -f3 )
      file1loc=$(grep "$file1" ~/foo/bar/flvlist.txt | sed -e 's/remove any directory prefixes//g')
      file2loc=$(grep "$file2" ~/foo/bar/flvlist.txt | sed -e 's/remove any directory prefixes//g')
       echo "$file1loc $file2loc $chance"
   done
   sed -i "/$(basename $i)/d" /tmp/ssdeep.txt
done

find /tmp/ -type f -iname "*.wav" -delete 2>/dev/null
rmdir /tmp/* 2>/dev/null
