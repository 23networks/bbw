#!/bin/bash

# If no mysql process is running, we aren't on a mysql server
ps cax | grep mysqld > /dev/null || exit 0

# Main directory where backup will be stored
MBD="/var/backups/mysql"
# Last successful dump is less than 6 hours ago -> skip
if [ -e $MBD/ts_finish ];then
if [ 0 = $(( (`date +%s` - `stat -L --format %Y $MBD/ts_finish`) > (6*60*60) )) ]
then
  exit 0
fi;fi

# This is needed by mysqldump to locate the .my.cnf
export HOME=/root

LOGFILE=/tmp/mysqldump.log

# Linux bin paths, change this if it can't be autodetected via which command
MYSQL="$(which mysql) --defaults-extra-file=/etc/mysql/debian.cnf"
MYSQLDUMP="$(which mysqldump) --defaults-extra-file=/etc/mysql/debian.cnf"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"


if test ! -d "${MBD}"; then
    mkdir -p "${MBD}"
    chown 0.0 "${MBD}"
    chmod 700 "${MBD}"
else
    find "${MBD}" -type f -exec rm {} \;
fi

date > $MBD/ts_start

# Get hostname
HOST="$(hostname)"

# Get data in dd-mm-yyyy format
NOW="$(date +"%d-%m-%Y")"

# File to store current backup file
FILE=""
# Store list of databases

DBS=""

# DO NOT BACKUP these databases
IGGY="test information_schema performance_schema"

[ ! -d $MBD ] && mkdir -p $MBD || :

# Get all databases list first
DBS="$($MYSQL -Bse 'show databases')"

if test -f "${LOGFILE}"; then
    rm "${LOGFILE}"
fi

ERROR=0

for db in $DBS
do
    skipdb=-1
    if [ "$IGGY" != "" ];
    then
    for i in $IGGY
    do
        [ "$db" == "$i" ] && skipdb=1 || :
    done
    fi

    if [ "$skipdb" == "-1" ] ; then
    FILE="$MBD/$db.$HOST.$NOW"
        #$MYSQLDUMP $db 2>>"${LOGFILE}"| CODE=$? $GZIP -6 > $FILE
        #if test ! ${PIPESTATUS[0]} -eq 0; then
        $MYSQLDUMP $db 2>>"${LOGFILE}" > $FILE
        if test ! $? -eq 0; then
            ERROR=1
            echo "Error while dumping database: ${db}" >>"${LOGFILE}"
        fi
    fi
done

if test ${ERROR} -eq 1; then
    mail -s "MySQL dump error" root@localhost < "${LOGFILE}"
fi

date > $MBD/ts_finish

