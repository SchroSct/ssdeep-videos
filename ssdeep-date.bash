#!/bin/bash
dname="$1"
mapfile -t dirs < <(dirname $(cat ~/foo/bar/flvlist.txt ) | sort | uniq | grep -i -- "$dname")
echo "ssdeep,1.1--blocksize:hash:hash,filename" > "/tmp/ssdeep-${dname}.txt"
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
ssdeep $(find /tmp/ -type f -iname "*.wav" 2>/dev/null) | grep -v -- "ssdeep,1.1--blocksize:hash:hash,filename" >> "/tmp/ssdeep-${dname}.txt"
mapfile -t files < <(find /tmp/ -type f -iname "*.wav" 2>/dev/null)
for i in "${files[@]}"
do
   mapfile -t matches < <(ssdeep -m "/tmp/ssdeep-${dname}.txt" "$i" 2>/dev/null | cut -d" " -f1,3,4)
   for m in "${matches[@]}"
   do
      file1=$(basename $(echo "$m" | cut -d" " -f1 | sed -e 's/.wav/.flv/g'))
      file2=$(basename $(echo "$m" | cut -d" " -f2 | sed -e 's/.wav/.flv/g'))
      let chance=$(echo "$m" | cut -d" " -f3 )
      file1loc=$(grep "$file1" ~/foo/bar/flvlist.txt | sed -e 's/\/foo\/bar\///g')
      file2loc=$(grep "$file2" ~/foo/bar/flvlist.txt | sed -e 's/\/foo\/bar\///g//g')
      echo "$file1loc $file2loc $chance"
   done
   sed -i "/$(basename $i)/d" "/tmp/ssdeep-${dname}.txt"
done

for dir in "${tmpdirs[@]}"
do
   rm ${dir}/* &>/dev/null
   rmdir "${dir}" &>/dev/null
   rm "/tmp/ssdeep-${dname}.txt" &>/dev/null
done
