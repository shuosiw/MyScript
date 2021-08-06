#!/bin/bash
#
# File: skip_check_auto.sh
# Desc: get check seed and auto detect whether it can skip check by name.
# Date: 2021-08-06

# ============EDIT THIS============
TRBIN='transmission-remote'
HOST='127.0.0.1:9091'
AUTH='username:password'
# =================================

STATUS='Verify'
ALL_LIST_INFO=`$TRBIN $HOST -n $AUTH -l 2>&1`
SKIP_CHECK_LIST=''
ALL_CHECK_LIST=''
NO_EXIT_RES_LIST=''

### DEBUG MODE
DEBUG=false

detect_args(){
    if [ "x$1" = 'x-d' ]; then
        DEBUG=true
        echo "Enter Debug Mode..."
    fi
}

get_check_seed(){
    # args: none
    # returns: seed id and name which need to check
    #   'ID1|seedname1
    #   ID2|seedname2'
    check_seed=`echo "$ALL_LIST_INFO" | grep $STATUS | grep -v ID`
    [ "x$check_seed" = 'x' ] && exit 1
    id_name_list=`echo "$check_seed" | awk '{printf("%s|", $1); for (i=10;i<=NF;i++)printf("%s ", $i); print " "}'`
    # TODO get checksum group by seed name
    if [ "x$DEBUG" = 'xtrue' ]; then
        echo "[DEBUG] seed info which need to be checked: " >&2
        echo "$id_name_list" >&2
    fi
    echo "$id_name_list"
}


get_complete_seed_with_name(){
    # args:
    #   seed_name: 'seedname1'
    # returns: id list of complete seeds
    #   '1234
    #   1578'
    seed_name="$1"
    complete_seed_id_list=`echo "$ALL_LIST_INFO" | grep -F "$seed_name" | grep -v $STATUS | awk '{print $1}'`
    if [ "x$DEBUG" = 'xtrue' ]; then
        echo "[DEBUG] the id list of completed seed which has same name： $seed_name" >&2
        echo "$complete_seed_id_list" >&2
    fi
    echo "$complete_seed_id_list"
}


get_check_seed_md5_with_id(){
    # args:
    #   seed_id: '1234'
    # return: the md5sum of seed info(delete index and progress)
    #   '0fafdfb4a2361dfa4d19064e53c4ac3b'
    seed_id="$1"
    seed_info=`$TRBIN $HOST -n $AUTH -t $seed_id -if 2>/dev/null`
    if [ "x$seed_info" = "x" ]; then
        echo "cannot get seed info with id: $seed_id" >&2
        exit 1
    else
        seed_info_md5=`echo "$seed_info" | awk '{$1=""; $2=""; print}' | sort -bk 3 | md5sum | awk '{print $1}'`
    fi
    if [ "x$DEBUG" = 'xtrue' ]; then
        echo "[DEBUG] the md5sum of specified seed id: $seed_id" >&2
        echo "$seed_info_md5" >&2
    fi
    echo "$seed_info_md5"
}

check_with_complete_seed_info(){
    # args:
    #   check_seed_id: '1303'
    #   complete_seed_ids: '205 605 1136'
    # return: print seed id which can be skip and the id of match complete seed
    check_seed_id="$1"
    check_seed_name="$2"
    complete_seed_ids="$3"
    check_seed_md5=`get_check_seed_md5_with_id $check_seed_id`
    ALL_CHECK_LIST=`echo -e "$check_seed_id|$check_seed_name|$check_seed_md5\n$ALL_CHECK_LIST"`
    for cpid in $complete_seed_ids; do
        cpmd5=`get_check_seed_md5_with_id $cpid`
        if [ "x$check_seed_md5" = "x$cpmd5" ]; then
            echo "md5sum match: $check_seed_id & $cpid, skip other same seed check"
            echo -n "old seed info:"
            echo "$ALL_LIST_INFO" | grep " $cpid " | awk '{$5=""; $6=""; $7=""; print}'
            echo
            SKIP_CHECK_LIST="$SKIP_CHECK_LIST $check_seed_id"
            break
        fi
    done
}


check_for_skip(){
    # args:
    #   check_list:
    #       'ID1|seedname1
    #       ID2|seedname2'
    check_list="$1"
    if [ "x$check_list" = 'x' ]; then
        echo 'No seed need to be check, skip'
        exit 1
    fi
    echo
    echo "########### SAME SEED CHECK ###########"
    while read check_seed; do
        chkid=`echo "$check_seed" | awk -F\| '{print $1}'`
        chkname=`echo "$check_seed" | awk -F\| '{print $2}'`
        if [ "x$DEBUG" = 'xtrue' ]; then
            echo "[DEBUG] checking seed id: $chkid" >&2
            echo "[DEBUG] checking seed name: $chkname" >&2
        fi
        echo "----------- check $check_seed"
        cplids=`get_complete_seed_with_name "$chkname"`
        if [ "x$cplids" = 'x' ]; then
            NO_EXIT_RES_LIST="$chkid|$chkname|-\n$NO_EXIT_RES_LIST"
            echo "no completed seed with same name: $chkname"
            echo
        else
            check_with_complete_seed_info "$chkid" "$chkname" "$cplids"
        fi
    done <<< "$check_list"
    if [ "x$DEBUG" = 'xtrue' ]; then
        echo "[DEBUG] all check seed info: " >&2
        echo "$ALL_CHECK_LIST" >&2
        echo "[DEBUG] all skip check seed id: " >&2
        echo "$SKIP_CHECK_LIST" >&2
    fi
}


generate_skip_check_info(){
    # args:
    #   check_seed_info_list: information of all check seeds
    #   skip_check_seed_list: id list of skip check seeds
    # return:
    #   print final information of script
    check_seed_info_list="$1"
    skip_check_seed_list="$2"
    no_exit_resource_list="$3"
    success_info=`for idx in $skip_check_seed_list; do
        echo "$check_seed_info_list" | grep "^${idx}|"
    done`
    failed_info=`echo "$check_seed_info_list" | grep -Fve "$success_info"`
    echo
    echo "######## SKIP CHECK SEED LIST ########"
    echo "$success_info"
    echo
    echo "######## CHECK SEED FAIL LIST ########"
    echo "$failed_info"
    echo -e "$no_exit_resource_list"
}


main(){
    detect_args $@
    chkseed_id_names=`get_check_seed`
    echo
    echo "########### WAIT FOR CHECK ###########"
    echo "$chkseed_id_names"
    check_for_skip "$chkseed_id_names"
    generate_skip_check_info "$ALL_CHECK_LIST" "$SKIP_CHECK_LIST" "$NO_EXIT_RES_LIST"
}


main $@
