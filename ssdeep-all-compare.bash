#!/bin/bash
dirbase=""
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
   tmpdirs[$s]="${tmpdir}"
   let s=$s+1
done
mapfile -t files < <(find /tmp/ -type f -iname "*.wav" 2>/dev/null)
for i in "${files[@]}"
do
   mapfile -t matches < <(ssdeep -m ~/foo/bar/ssdeep-all.txt "$i" 2>/dev/null | cut -d" " -f1,3,4)
   for m in "${matches[@]}"
   do
      file1=$(basename $(echo "$m" | cut -d" " -f1 | sed -e 's/.wav/.flv/g'))
      file2=$(basename $(echo "$m" | cut -d" " -f2 | sed -e 's/.wav/.flv/g'))
      file1loc=$(grep "$file1" ~/foo/bar/flvlist.txt | sed -e 's/\/foo\/bar\///g')
      file2loc=$(grep "$file2" ~/foo/bar/flvlist.txt | sed -e 's/\/foo\/bar\///g')
      if [[ "$file1" != "$file2" ]] && [[ -f "${dirbase}${file1loc}" ]] && [[ -f "${dirbase}${file2loc}" ]]
      then
         let chance=$(echo "$m" | cut -d" " -f3 )
         echo "$file1loc $file2loc $chance"
      fi
   done
done

for dir in "${tmpdirs[@]}"
do
   rm ${dir}/* &>/dev/null
   rmdir "${dir}" &>/dev/null
   rm "/tmp/ssdeep-${dname}.txt" &>/dev/null
done
