#!/bin/bash

ORI_TRACKER="$1"
DST_TRACKER="$2"

username=""
password=""
host="localhost:9091"

TRBIN=`which transmission-remote`


if [ "x" = "x$TRBIN" ]; then
    echo 'Command not found: transmission-remote'
    exit 1
fi

if [ ! -z "$username" ] && [ ! -z "$password" ]; then 
    TRBIN="$TRBIN -n $username:$password"
fi


ALL_ID=`$TRBIN $host -l | awk '{print $1}' | grep -o -P '\d+'`
sum=0

for id in $ALL_ID; do
    torrent_info=`$TRBIN $host -t $id -it -i | grep -E 'Name|Tracker [0-9]+:'`
    if echo "$torrent_info" | grep -q $ORI_TRACKER; then
        echo '-------'
        echo "ID: $id"
        echo "$torrent_info"
        let sum++
        tracker_id=`echo $torrent_info | awk -F: '/Tracker/{print $1}' | grep -o -P '\d+'`
        $TRBIN $host -t $id -tr $tracker_id && \
            $TRBIN $host -t $id -td $DST_TRACKER
        if [ $? -ne 0 ]; then
            echo 'change torrent tracker failed'
            exit 1
        fi
    fi
done

echo '================='
echo "Change $sum torrent tracker."


