#!/bin/bash
# archive deb packages older than a week or month

# load common functions
sLib="/root/bin/functions"
if [ -f ${sLib} ]; then
  . ${sLib}; logTee "[OK] sourced function library -- ${sLib}"
else
  echo "[FATAL] failed to import function library -- check ${sLib}"; exit 2
fi

# pre-flight checks
checkRoot
logsOn

# move files to archives older than a month
archiveMonth /opt/devel

# keep last weeks files
#archiveWeek /opt/devel

# remove stuff in archives older than a year
delYear /opt/archives

# remove stuff in archives older than a month
delMonth /opt/archives

# re-scan the
scanDpkg /opt/devel

# end
logsOff && exit 0