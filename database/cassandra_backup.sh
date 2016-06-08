#!/bin/bash
# @date:                10oct14
# @author:              Austin Matthews
# @description:         create tarballs of cassandra data files and archive into NAS and data disk
# @parameter:           Perform backup to NAS if first parameter = "YES"
# @retention:           Archival:  save daily snapshoot, commitlog log, and logs for 7 days
#                                 save sunday backup for 4 weeks
#                       Disk:     snapshoot saved in the same way in /data/cassandra-snapshots/
#                                 commitlog saved for 7 days in /data/cassandra-commitlog/
#                                 logs saved for 90 days in /var/log/example
# @debug:               enable DEBUG mode with 'set -x -v'
# set -x -v

# @variables:
now=$(date +"%Y%m%d.%H%M")
day=$(date +%d)
weekday=$(date +%u)
X=$0                              # save $0 - aka cmdName
Y=${X##*/}                        # remove dir part
Z=${Y%.*}                         # remove the extension
DB_HOST=(`grep -m 1 "DB_HOST" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
sLogDir="/var/log/example"
logFile="${sLogDir}/${Z}_${DB_HOST}_${now}.log"
statFile="${sLogDir}/status.log"
container="${DB_HOST}_backup"
backupPassword="$iMpl3_p@s$W0rd"
SITE_PREFIX=(`grep -m 1 "SITE_PREFIX" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
REMOTE1_NAME=(`grep "$SITE_PREFIX"REMOTE1_NAME /opt/example/conf/site.properties  | awk -F "=" '{print $2}' `)
NAS=(`grep -w NAS /opt/example/conf/site.properties | grep -v '^#' | awk -F "=" '{print $2}' `)

# @functions:
logTee() {
  echo "$(timeStamp): $*" | tee -a $statFile
}

checkLast() {
  if [ ! $1 -eq 0 ]; then
    logTee "[ERROR] checkLast on " "$2"
    exec 1>&6 6>&-                                  # Reset redirection, output will be deliver to administrator
    echo "$(timeStamp): [ERROR] $2"
    exit 1
  fi
}

timeStamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

verifyDBUser() {
  echo "select userid,username,deleted from ${NAS}.userid ;" > /tmp/fetch.sql
  userId=(`cqlsh $DB_HOST --file=/tmp/fetch.sql | \
          grep -w False | grep -w 'system' | awk '{print $1}' `)
  echo "select accountid,accountname,deleted from ${NAS}.accountid ;" > /tmp/fetch.sql
  accountId=(`cqlsh $DB_HOST --file=/tmp/fetch.sql | \
          grep -w False | grep -w 'system' | awk '{print $1}' `)
  echo "select * from ${NAS}.AccountIDUserID where accountid=$accountId and userid=$userId ;" > /tmp/fetch.sql
  cqlsh $DB_HOST --file=/tmp/fetch.sql | grep $accountId &> /dev/null
  if [ $? -ne 0 ]; then 
    logTee "Creating DB User and Account"
    PYTHONPATH=/opt/example python /opt/example/install/admin_user.py
  fi
}

# @start:  send everything to log file as the process run as cron job
exec 6>&1
exec &>>${logFile}
logTee "START ${Z} process"
cd /tmp
logTee "Generating a daily snapshot"
nodetool -h localhost -p 7199 clearsnapshot $NAS
nodetool -h localhost -p 7199 snapshot $NAS
rm ${DB_HOST}-*.tgz
tar -zcvf ${DB_HOST}-cassandra-snapshot-daily-$now.tgz /data/lib/cassandra/data/$NAS/*/snapshots/
if [ "$1" == "YES" ]; then # backup to vault
  if [ $weekday -eq 7 ]; then
    secRetain='+10368000'
  else
    secRetain='+604800'
  fi
  verifyDBUser
  tar -zcvf ${DB_HOST}-commitlog-daily-$now.tgz /ssd/lib/cassandra/commitlog/
  tar -zcvf ${DB_HOST}-varLogRemote-$now.tgz /var/log/example/
  tarFiles="${DB_HOST}-cassandra-snapshot-daily-$now.tgz ${DB_HOST}-commitlog-daily-$now.tgz ${DB_HOST}-varLogRemote-$now.tgz"
  # retain files for 7 days (604800 seconds), weekly files saved for 4 weeks
  for file in $tarFiles; do
    PYTHONPATH=/opt/example/ python /opt/example/client $file \
         scv://system@${DB_HOST}:8080/system/$container -k $backupPassword -x $secRetain
    checkLast $? "Failed to backup ${file} via client into vault, check ${logFile}"
    logTee "Sucessfully copied $file into vault using client. Retention seconds $secRetain"
  done
fi
if [ $weekday -eq 7 ]; then
  mv ${DB_HOST}-cassandra-snapshot-daily-$now.tgz ${DB_HOST}-cassandra-snapshot-weekly-$now.tgz 
fi
mv /tmp/*cassandra-snapshot* /data/cassandra-snapshots/

# clean out old files
echo "$(timeStamp) Deleting old snapshots"
find /data/cassandra-snapshots/*daily* -mtime +7 -exec rm {} \;
find /data/cassandra-snapshots/ -mtime +30 -exec rm {} \;
find /data/cassandra-commitlog/commitlog/ -mtime +7 -exec rm {} \;
find /var/log/example/* -mtime +90 -exec rm {} \;
rm ${DB_HOST}-*.tgz
logTee "END ${Z} process "
