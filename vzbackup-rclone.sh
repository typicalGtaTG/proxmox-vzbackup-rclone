#!/bin/bash
# ./vzbackup-rclone.sh rehydrate YYYY/MM/DD file_name_encrypted.bin

############ /START CONFIG
drive="gd-backup_crypt"
dumpdir="/backups/dump/" # Set this to where your vzdump files are stored
MAX_AGE=1 # This is the age in days to keep local backup copies. Local backups older than this are deleted.
MAX_CLOUD_AGE=1095 # This is the age in days to keep cloud backup copies. Cloud backups older than this are deleted
############ /END CONFIG

_bdir="$dumpdir"
rcloneroot="$dumpdir/rclone"
timepath="$(date +%Y-%m-%d)"
rclonedir="$rcloneroot/$timepath"
COMMAND=${1}
rehydrate=${2} #enter the date you want to rehydrate in the following format: YYYY/MM/DD
if [ ! -z "${3}" ];then
        CMDARCHIVE=$(echo "/${3}" | sed -e 's/\(.bin\)*$//g')
fi
if [ -z ${TARGET+x} ]; then 
    tarfile=${TARFILE}
else
    tarfile=${TARGET}
fi
exten=${tarfile#*.}
filename=${tarfile%.*.*}

if [[ ${COMMAND} == 'rehydrate' ]]; then
    #echo "Please enter the date you want to rehydrate in the following format: YYYY/MM/DD"
    #echo "For example, today would be: $timepath"
    #read -p 'Rehydrate Date => ' rehydrate
    rclone --config /root/.config/rclone/rclone.conf \
    --drive-chunk-size=32M copy $drive:/$rehydrate/ $dumpdir \
    -v --stats=60s --transfers=16 --checkers=16
fi

if [[ ${COMMAND} == 'job-start' ]]; then
    echo "Deleting backups older than $MAX_AGE days."
    find $dumpdir -type f -mtime +$MAX_AGE -exec /bin/rm -f {} \;
fi

if [[ ${COMMAND} == 'backup-end' ]]; then
    echo "Backing up $tarfile to remote storage"
    echo "rcloning $rclonedir"
    
    rclone --config /root/.config/rclone/rclone.conf \
    --drive-chunk-size=32M copy $tarfile $drive:/$timepath \
    -v --stats=60s --transfers=16 --checkers=16
fi