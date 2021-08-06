#!/bin/bash
#
# File: backup_unraid.sh
# Desc: backup appdata and unraid system config:
#    1. Incrementally backup user data with rsync: /mnt/user/appdata/ /boot/config/
#    2. Fully backup some appdata with tar
#    3. rotate backups, keep the last 10 backups.
# Date: 2021-08-01

BACKDIR='/mnt/user/Backup2'

APPDATA_DIR='/mnt/user/appdata/'
UNRAID_CONF='/boot/config/'

APPDATA_BACK_DIR="$BACKDIR/appdata/"
UNRAID_CONF_BACK_DIR="$BACKDIR/config/"
TAR_BACK_DIR="$BACKDIR/tar"

KEEP_BACKUP_TIME=10

echo
echo
echo '#############################'
echo '#        BACKUP START       #'
echo '#############################'
####
# general backup
####

# backup appdata using rsync
date "+[%F %T] start backup all appdata..."
rsync -av --exclude .git --exclude log --exclude cache $APPDATA_DIR $APPDATA_BACK_DIR

# backup unraid config using rsync
date "+[%F %T] start backup unraid config..."
rsync -av  $UNRAID_CONF $UNRAID_CONF_BACK_DIR

####
# special backup
####

cd $BACKDIR
if [ $? -ne 0 ]; then
    echo "cannot cd main backup directory: $BACKDIR"
    exit 1
fi

[ ! -d $TAR_BACK_DIR ] && mkdir -p $TAR_BACK_DIR
date "+[%F %T] start backup special tar file..."
tar --exclude panel -zcvf $TAR_BACK_DIR/special.tar.gz-`date +"%F"` \
    appdata/FileBrowserEnhanced \
    appdata/aria2-with-ariang \
    appdata/cloudreve \
    appdata/frp \
    appdata/iyuuplus \
    appdata/jd/config \
    appdata/nginx \
    appdata/pthelper \
    appdata/qiandao \
    appdata/unblockneteasemusic
date "+[%F %T] start backup jellyfin tar file..."
tar --exclude CJKfonts --exclude metadata -zcvf $TAR_BACK_DIR/jellyfin.tar.gz-`date +"%F"` appdata/jellyfin
date "+[%F %T] start backup transmission tar file..."
tar -zcvf $TAR_BACK_DIR/transmission.tar.gz-`date +"%F"` appdata/transmission


####
# rotate backup
####
date "+[%F %T] delete backup file..."
_delete_time=`expr $KEEP_BACKUP_TIME \* 7 - 1`
find tar -type f -mtime +$_delete_time
find tar -type f -mtime +$_delete_time -exec rm -f {} \;

date "+[%F %T] done"

