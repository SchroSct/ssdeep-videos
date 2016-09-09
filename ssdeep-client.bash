#!/bin/bash
dname="$1"
locbase=""
mapfile -t matches < <(ssh user@server ssdeep-all-compare.bash "$dname")
let n=0
mkdir /foo/bar/
tmp=/foo/bar/
function mflist(){
      for line in "${matches[@]}"
      do
         f1=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f1)
         f2=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f2)
         cha=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f3)
         if [[ "$f1" != "$f2" ]] && [[ -r "${locbase}${f1}" ]] && [[ -r "${locbase}${f2}" ]]
         then
            echo "$f1"
            echo "$f2"
         fi
      done
}
function chlist(){
      let chan=0
      for line in "${matches[@]}"
      do
         cha=$(echo "$line" | grep "$(basename ${file1})" | cut -d" " -f3)
         let chan=$chan+$cha
      done
      echo "$chan"
}

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
      mapfile -t files < <(mflist | sort | uniq )
      let chance=$(chlist)
      let filenum=0
      for file in "${files[@]}"
      do
         echo "File $filenum is ${files[$filenum]}"
         cp -pn "${locbase}${file}" "$tmp"
         ls -lah "${locbase}$file"
         echo "$(echo "$(ffprobe "${tmp}/$(basename ${file})" 2>&1 | grep -i duration | sed -e 's/.*Duration: //g' -e 's/,.*//g' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }') * .${chance}" | bc) seconds overlap"
      done
      echo "Chance of a match is ${chance}%"
      echo "Press Return to start comparison"
      read nothing
      let mpvnum=0
      for file in "${files[@]}"
      do
         mpv --pause --no-audio --loop=inf --speed=1.33 "${tmp}/$(basename ${file})" &>/dev/null &
         mpvpid[$mpvnum]=$!
         let mpvnum=$mpvnum+1
      done
      sleep 1.5
      let lastmpv=${#mpvpid}-1
      until wmctrl -l -p | grep -i "${mpvpid[0]}" &>/dev/null || wmctrl -l -p | grep -i "$mpvpid[${lastmpv}]" &>/dev/null
      do
         sleep .5
      done
      sleep 2
      rearrange.py mpv
      select opt in $(for t in "${files[@]}" ; do echo "$t" ; done ; echo "None" )
      do
          case "$opt" in
             "None")
                echo "Deleting None"
                break
                ;;
             *)
                echo "Deleting $opt"
                read nothing
                rm -v "${locbase}${opt}"
                rm -v "${tmp}/$(basename $opt)"
                break
                ;;
         esac
      done
      for i in "${mpvpid[@]}"
      do
         kill -- "$i"
      done
      let n=n+1
      clear
   fi
done
