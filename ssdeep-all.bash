#!/bin/bash
mapfile -t files < <(cat ~/foo/bar/flvlist.txt )
echo "ssdeep,1.1--blocksize:hash:hash,filename" >/tmp/ssdeep-all.txt
tmpdir=$(mktemp -d)
for i in "${files[@]}"
do
   nfile=${tmpdir}/$(basename "${i/.flv/.wav}")
   ffmpeg -i "$i" -vn -codec copy "$nfile" &>/dev/null
   if [[ -e "$nfile" ]]
   then
   if ssdeep -s $(find "${tmpdir}" -type f -iname "*.wav" 2>/dev/null) | grep -v "ssdeep,1.1--blocksize:hash:hash,filename" >> /tmp/ssdeep-all.txt
      then
         echo "ssdeep of $i Successful"
      else
         echo "ssdeep of $i failed :("
      fi
   fi
   find "${tmpdir}" -type f -iname "*.wav" -delete
done
rmdir "${tmpdir}"
mv /tmp/ssdeep-all.txt ~/foo/bar/ssdeep-all.txt
