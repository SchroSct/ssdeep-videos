#!/bin/bash
dname="$1"
locbase="/foo/bar/files"
mapfile -t matches < <(ssh $user@$server ssdeep-date.bash "$dname")
let n=0
tmp=$(mktemp -d)
for match in "${matches[@]}"
do
   file1=$(echo "$match" | cut -d" " -f1)
   file2=$(echo "$match" | cut -d" " -f2)
   chance=$(echo "$match" | cut -d" " -f3)
if [[ "$file1" == "$file2" ]]
then
   echo "$file1 matched itself"
else
   cp -vpn "${locbase}${file1}" "$tmp"
   cp -vpn "${locbase}${file2}" "$tmp"
   echo "Files Copied to $tmp"
   for line in "${matches[@]}"
   do
      echo "$line" | grep "$(basename ${file1})"
   done
   echo "Chance of a match is ${chance}%"
   echo "File 1 is $file1"
   echo "File 2 is $file2"
   ls -lah "${locbase}$file1"
   ls -lah "${locbase}$file2"
   echo "Press Return to start comparison"
   read nothing
   mpv --no-audio --loop=inf --speed=1.33 "${tmp}/$(basename ${file1})" &>/dev/null &
   mpv1=$!
   mpv --no-audio --loop=inf --speed=1.33 "${tmp}/$(basename ${file2})" &>/dev/null &
   mpv2=$!
   select opt in $(echo "KeepFile1" ; echo "KeepFile2" ; echo "KeepBoth" ; echo "RemoveBoth")
   do
      echo "You chose $opt"
      case $opt in
         "KeepFile1")
            echo "Keeping $file1"
            echo "Press return to delete $file2"
            read nothing
            rm -v "${locbase}${file2}"
            break
            ;;
         "KeepFile2")
            echo "Keeping $file2"
            echo "Press return to delete $file1"
            read nothing
            rm -v "${locbase}${file1}"
            rm -v "${tmp}/$(basename $file1)"
            break
            ;;
         "KeepBoth")
            echo "Keeping $file1 & $file2"
            break
            ;;
         "RemoveBoth")
            echo "Removing $file1 & $file2"
            echo "Press return to delete $file1 & $file2"
            read nothing
            rm -v "${locbase}${file1}"
            rm -v "${tmp}/$(basename $file1)"
            rm -v "${locbase}${file2}"
            break
            ;;

          *)
            break
            ;;
      esac
   done
   kill -- "$mpv1"
   kill -- "$mpv2"
   let n=n+1
   nfile1=$(echo "${matches[$n]}" | cut -d" " -f1)
   if [[ "$nfile1" == "$file1" ]]
   then
      rm -v "${tmp}/$(basename $file2)"
   else
      rm -v ${tmp}/*
   fi
fi
done
