#!/bin/bash
#
# File: get_error_info.sh
# Desc: get the message of error torrents in transmission.
# Date: 2022-03-19

# ============EDIT THIS============
TRBIN='transmission-remote'
HOST='10.0.0.3:9091'
AUTH='username:password'
# =================================

declare -A ERR_INFO_ARRAY
declare -A TORRENT_INFO_ARRAY

ALL_ERR_LIST=`$TRBIN $HOST -n $AUTH -l 2>&1 | awk '/[0-9]*\*/{split($1,a,"*"); print a[1]}'`


red_echo(){
    echo -e "\033[31m$1 \033[0m"
}

green_echo(){
    echo -e "\033[32m$1 \033[0m"
}

get_all_error(){
    for id in $ALL_ERR_LIST; do
        info=$($TRBIN $HOST -n $AUTH -t $id -i -it 2>/dev/null)
        err=$(echo "$info" | awk -F: '/Tracker gave an error/{print $2}' | xargs)
        name=$(echo "$info" | awk -F: '/Name:/{print $2}')
        tracker=$(echo "$info" | grep 'Tracker 0' | sed 's/ *Tracker 0://g' | xargs)
        TORRENT_INFO_ARRAY[$id]="$name|$tracker"
        ERR_INFO_ARRAY["${err}|"]+="$id|"
    done
}

print_all_error(){
    errlist=`echo "${!ERR_INFO_ARRAY[@]}" | sed 's/| /\n/g' | sed 's/|$//g'`
    while read err_type; do
        red_echo "-----${err_type}-----"
        for id in `echo "${ERR_INFO_ARRAY[${err_type}|]}" | sed 's/|/ /g'`; do
            echo "${id}|${TORRENT_INFO_ARRAY[$id]}"
        done
    done <<< "$errlist"
}


main(){
    get_all_error
    print_all_error
}

main
