#!/bin/bash
#
# File: check_meta_change.sh
# Desc: check nfo and images file if edit when hard link to tmm.
# Date: 2021-07-24

#set -e
#set -o pipefail

DEBUG=false

if [ "x$1" = 'x-d' ]; then
    DEBUG=true
    set -e
    set -o pipefail
fi


red_echo(){
    echo -e "\033[31m$1 \033[0m" 
}

green_echo(){
    echo -e "\033[32m$1 \033[0m"
}


find ./* -type d -maxdepth 0 | while read mdir; do
    $DEBUG && echo "change directory to $mdir"
    cd "$mdir"
    if [ $? -ne 0 ]; then
        red_echo "cd failed, continue next."
        continue
    fi
    if ls | grep -qiE '\.nfo$|\.jpg$|\.png$'; then
        if [ `ls -hl | awk '/rw/{print $6,$7,$8}' | sort -u | wc -l` -ne 1 ]; then
            movie_ts=`date "+%s"`
            movie_old="None"
            while read movie; do
                if [ "x$movie" = 'x' ]; then
                    green_echo "directory does not have movie file: $mdir"
                    continue
                fi
                this_ts=$(ls -lh --time-style="+%s" "$movie" | awk '/rw/{print $6}')
                if [ $this_ts -lt $movie_ts ]; then
                    movie_ts="$this_ts"
                    movie_old="$movie"
                fi
            done <<< `find . -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.iso' -o -iname '*.wav'`
            $DEBUG && echo "[$movie_old] `date -d @$movie_ts '+%F %T'` -- the oldest mtime movie file"
            find . -iname '*.nfo' -o -iname '*.jpg' -o -iname '*.png' | while read metafile; do
                meta_ts=$(ls -lh --time-style="+%s" "$metafile" | awk '/rw/{print $6}')
                if [ $meta_ts -gt $movie_ts ]; then
                    green_echo "[$mdir] need to check"
                    break
                else
                    $DEBUG && echo "[$metafile] `date -d @$meta_ts '+%F %T'` -- meta file mtime is normal"
                fi
            done
        else
            $DEBUG && echo 'all file in this directory have the same change time.'
        fi
    else
        $DEBUG && echo 'directory does not have meta files, skip'
    fi
    cd ..
    $DEBUG && echo -e '-----------------------\n\n'
done

