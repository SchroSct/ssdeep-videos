#!/bin/bash
dname="$1"
mapfile -t matches < <(ssh $user@$server ssdeep-date.bash "$dname")
let n=0
tmp=$(mktemp -d)
for match in "${matches[@]}"
do
   file1=$(echo "$match" | cut -d" " -f1)
   file2=$(echo "$match" | cut -d" " -f2)
   chance=$(echo "$match" | cut -d" " -f3)
   cp -vpn "/path/to/files/$file1" "$tmp"
   cp -vpn "/path/to/files/$file2" "$tmp"
   echo "Files Copied to $tmp"
   echo "Chance of a match is ${chance}%"
   echo "File 1 is $file1"
   echo "File 2 is $file2"
   mpv --no-audio --loop=inf "${tmp}/$(basename ${file1})" &>/dev/null &
   mpv1=$!
   mpv --no-audio --loop=inf "${tmp}/$(basename ${file2})" &>/dev/null &
   mpv2=$!
   read nothing
   kill -- "$mpv1"
   kill -- "$mpv2"
   let n=n+1
   nfile1=$(echo "${matches[$n]}" | cut -d" " -f1)
   if [[ "$nfile1" == "$file1" ]]
   then
      rm -f "${tmp}/$(basename $file2)"
   else
      rm -f "${tmp}/*"
   fi
done
