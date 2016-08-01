#!/bin/bash
dname="$1"
locbase=""
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
      let n=$n+1
   elif [[ ! -r "${locbase}${file1}" ]] || [[ ! -r "${locbase}${file2}" ]]
   then
      echo "One of the files is not readable, skipping."
      let n=$n+1
   else
      cp -vpn "${locbase}${file1}" "$tmp"
      cp -vpn "${locbase}${file2}" "$tmp"
      echo "Files Copied to $tmp"
      for line in "${matches[@]}"
      do
         f1=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f1)
         f2=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f2)
         cha=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f3)
         if [[ "$f1" != "$f2" ]]
         then
            echo "File1: $f1 $f2 $cha"
         fi
      done
      for line in "${matches[@]}"
      do
         f1=$(echo "$line" | grep "$(basename ${file2})" | cut -d" " -f1)
         f2=$(echo "$line" | grep "$(basename ${file2})" | cut -d" " -f2)
         cha=$(echo "$line" | grep "$(basename ${file2})" | cut -d" " -f3)
         if [[ "$f1" != "$f2" ]]
         then
            echo "File2: $f1 $f2 $cha"
         fi
      done
      echo "Chance of a match is ${chance}%"
      echo "File 1 is $file1"
      echo "File 2 is $file2"
      ls -lah "${locbase}$file1"
      ls -lah "${locbase}$file2"
      echo "$(echo "$(ffprobe "${tmp}/$(basename ${file1})" 2>&1 | grep -i duration | sed -e 's/.*Duration: //g' -e 's/,.*//g' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }') * .${chance}" | bc) seconds overlap"
      echo "$(echo "$(ffprobe "${tmp}/$(basename ${file2})" 2>&1 | grep -i duration | sed -e 's/.*Duration: //g' -e 's/,.*//g' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }') * .${chance}" | bc) seconds overlap"
      echo "Press Return to start comparison"
      read nothing
      sleep 1.5
      WIDTH=`xdpyinfo | grep 'dimensions:' | cut -f 2 -d ':' | cut -f 1 -d 'x'`;
      HALF=$(($WIDTH/2));
      mpv --no-audio --loop=inf --speed=1.33 "${tmp}/$(basename ${file1})" &>/dev/null &
      mpv1=$!
      mpv --no-audio --loop=inf --speed=1.33 "${tmp}/$(basename ${file2})" &>/dev/null &
      mpv2=$!
      until wmctrl -l -p | grep -i "$mpv1" &>/dev/null || wmctrl -l -p | grep -i "$mpv2" &>/dev/null
      do
         sleep .5
      done
      wid=$(wmctrl -l -p | grep -i "$mpv1" | sed -e 's/\ .*//g')
      wmctrl -r "$wid" -i -b add,maximized_vert && wmctrl -r "$wid" -i -e 0,0,0,$HALF,-1
      wid=$(wmctrl -l -p | grep -i "$mpv2" | sed -e 's/\ .*//g')
      wmctrl -r "$wid" -i -b add,maximized_vert && wmctrl -r "$wid" -i -e 0,$HALF,0,$HALF,-1
      select opt in $(echo "KeepFile1" ; echo "KeepFile2" ; echo "KeepBoth" ; echo "RemoveBoth")
      do
         echo "You chose $opt"
         case $opt in
            "KeepFile1")
               echo "Keeping $file1"
               rm -v "${locbase}${file2}"
               rm -v "${tmp}/$(basename $file2)"
               break
               ;;
            "KeepFile2")
               echo "Keeping $file2"
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
               rm -v "${locbase}${file1}"
               rm -v "${tmp}/$(basename $file1)"
               rm -v "${locbase}${file2}"
               rm -v "${tmp}/$(basename $file2)"
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
      nfile2=$(echo "${matches[$n]}" | cut -d" " -f2)
      if [[ "$nfile1" != "$file1" ]] && [[ "$nfile2" != "$file1" ]]
      then
         rm -v "${tmp}/$(basename $file1)"
      fi
      if [[ "$nfile1" != "$file2" ]] && [[ "$nfile2" != "$file2" ]]
      then
         rm -v "${tmp}/$(basename $file2)"
      fi
      clear
   fi
done
