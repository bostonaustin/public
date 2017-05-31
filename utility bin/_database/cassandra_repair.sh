#!/bin/bash
# @date:            3jan15
# @name:            cass_repair
# @description:     run a nodetool repair on all cassandra keyspaces
# @debug mode:      un-comment next line "set -x -v"
#set -x -v

# @variables
X=$0                # save $0 in a local variable
Y=${X##*/}          # remove dir part
Z=${Y%.*}           # remove extension - if you want to do so
sLogDir="/var/log"
logFile="${sLogDir}/${Z}_${HOSTNAME}_$(date +"%d%^b%Y").log"
statFile="${sLogDir}/status.log"

# @functions
# timestamp as Cassandra repair return full time stamp - Wed Sep 17 14:31:55 EDT 2014
timeStamp() {
  echo -n "["$(date +"%Y-%m-%d %H:%M:%S,%3N")"] "
}

# write out to logFile + console
logCon() {
  echo "$(timeStamp): $*"
}

# check to see if last command passed cleanly, if not exit
checkLast() {
  if [ ! $1 -eq 0 ]; then
    echo "$(timeStamp): [ERROR] check last command failed on " "$2"
    exec 1>&6 6>&-
    echo "$(timeStamp): [ERROR] $2"
    exit 1
  fi
}

# @start:
exec 6>&1
exec &>>$logFile 
logCon "START example Cassandra nodetool repair "
/usr/bin/nodetool repair -pr
checkLast $? "Failed to execute the nodetool repair command - please check $logFile "
logCon "END example Cassandra nodetool repair "
exit 0
