#!/bin/bash
# @date:            10feb15
# @author:          Austin Matthews
# @description:     upgrade example application software
# @examples:        upgrade.sh -v 1.0.0

# @variables:    change repo here until added as arg option
LIST="/etc/apt/sources.list"
VFLAG=${1:-"-v"}
DEFVER="1.0.0"                              # Default version is 1.0.0
VER=${2:-$DEFVER}
RFLAG=${3:-"-r"}
DEFREPO="prod"                              # Default repo is prod
REPO=${4:-$DEFREPO}
CURR_VER=$DEFVER
EXAMPLE_REPO=repo.example.com
NOW=`date`
HOUR=`date +"%R"`
TODAY=`date +"%d%^b%Y"`
YEARMONTH=`date +"%Y-%m"`

# @functions:
function createDir {
  if [ ! -d "$1" ]; then
    sudo mkdir "$1"
    echo "  [OK]" "$1" "created "
  else
    echo "  [WARN]" "$1" "already exists "
  fi
}

function checkLast {
  if [ ! $1 -eq 0 ]; then
    echo "[ERROR] " "checkLast on" "$2"
    exit 1
  fi
}

function USAGEXIT ()
{
  printf "Usage: %s [options] -v|version -b|backout -h|help \n" $(basename $0)
  echo ""
  SHOWHELP
  exit 2
} >&2

function RUNBACKOUT {
  echo ""
  echo " *** example SOFTWARE BACKOUT REQUESTED  *** "
  echo ""
  echo " *** THIS WILL DESTROY YOUR CURRENT SETTINGS and RESTORE RELEASE $VER CONFIGURATION *** "
  echo ""
  read -r -p "Are you sure? [y/n] " response
  response=${response,,}                        # to lower case
  if [[ $response =~ ^(yes|y)$ ]]; then
    echo ""
    echo "  RUNNING BACKOUT STEPS "
    echo ""
    if [ -d /opt/$VER ]; then
 echo "  stopping the example services... "
       sudo -u example PYTHONPATH=/opt/example python /opt/example/common/utilities/sys_procs.py -d
       sleep 5
 echo "  removing the suspect /opt/example ... "
 rm -rf /opt/example
 echo "    [OK] suspect directory removed "
 echo ""
 echo "  restoring the backup taken from $VER... "
 rsync -arl /opt/$VER/example/ /opt/example/
 echo "    [SUCCESS] last upgrade has been backed-out and system is restored to $VER configuration "
       echo "    [WARN] May need manual effort to reconfigure syscfg and other configurations "
       sudo -u example PYTHONPATH=/opt/example python /opt/example/common/utilities/sys_procs.py -u
    fi
  else
    echo ""
    echo "[EXIT] BACKOUT operation cancelled "
    echo ""
    exit 0
  fi
}

function SHOWHELP {
  echo "Usage: upgrade.sh [options] "
  echo ""
  echo "Options: "
  echo "-h this helpful text "
  echo "-v specify a version (-v 1.0.0) "
  # HIDDEN #echo "-r change to QA repo (-r qa) "
  echo "-b backout the last run of upgrade.sh to restore to prior configuration "
  echo ""
  echo "Default values: "
  echo "    'upgrade.sh' is the same as 'upgrade.sh -v $DEFVER' "
  echo ""
  echo "Examples: "
  echo "[upgrade to version 1.0.0 from example repo, works w/o '-v'] "
  echo "    upgrade.sh -v 1.0.0 "
  echo ""
  echo "[backout the last run and restore to prior configuration] "
  echo "    upgrade.sh -b "
  echo ""
}

function FIXPERMS {
  if [ -d /opt/example ]; then
    echo "checking /opt/example folder perms and ownership ... "
    chmod -R 700 /opt/example
    find /opt/example -type d -exec chmod 755 {} \;
    chmod 444 /opt/example/Makefile
    chmod 444 /opt/example/requirements.txt
    chmod 444 /opt/example/version
    chmod 755 /opt/example/monitor/nrpe_plugins/*
    chmod 644 /opt/example/.env
    find /opt/example -name "*.py" -exec chmod 755 {} \;
    find /opt/example -name "*.sh" -exec chmod 755 {} \;
    find /opt/example -name "*.cql" -exec chmod 750 {} \;
    find /opt/example -name "*.odt" -exec chmod 644 {} \;
    find /opt/example -name "*.rst" -exec chmod 644 {} \;
    find /opt/example -name "*.org" -exec chmod 644 {} \;
    find /opt/example -name "*.conf" -exec chmod 644 {} \;
    find /opt/example -name "*.cfg" -exec chmod 644 {} \;
    find /opt/example -name "*.list" -exec chmod 644 {} \;
    find /opt/example -name "*.properties" -exec chmod 644 {} \;
    find /opt/example -name "*.skel" -exec chmod 444 {} \;
    find /opt/example -name "*.txt" -exec chmod 444 {} \;
    find /opt/example -name "*README" -exec chmod 444 {} \;
    find /opt/example -name "*.pyc" -exec rm -f {} \;
    echo "  [OK] folder permissions and owners are correct "
  else
    echo "  [ERROR] check /opt/example for perms or owner issues "
  fi
}

## Start Upgrade Script

# DISABLE for development
# remove comment for internal only for command line testing purposes
#checkLast 1 "This is an internal script. Use 'install-server.sh' instead."

# max args
if [ $# -gt 4 ]; then
echo "  [ERROR] too many arguments given "
  USAGEXIT
fi

## take action if CLI args given
while getopts ":b:v:r:h" opt; do
  case $opt in
    b  ) VER=$OPTARG 
         RUNBACKOUT
         exit 0
         ;;
    v  ) VER=$OPTARG
         ;;
    r  ) if [ $# -eq 1 ]; then
           echo "[WARN] -r used w/o a version specified, applying defaults '-v $VER -r $REPO' "
         else
           REPO=$OPTARG
         fi
         ;;
    h  ) SHOWHELP
         USAGEXIT
         ;;
    *  ) USAGEXIT
  esac
done

## check for values in host and site.properties
if [ -f /opt/example/conf/host.properties ]; then
  CURR_VER=(`grep -m 1 "CURR_VER" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
fi
if [ "$CURR_VER" == "" ]; then
  checkLast 1 "Missing Current Version! double-check host.properties "
fi
if [ -f /opt/example/conf/site.properties ]; then
  EXAMPLE_REPO=(`grep "EXAMPLE_REPO" /opt/example/conf/site.properties | grep -v "^#" | awk -F "=" '{print $2}' `)
fi
if [ "$EXAMPLE_REPO" == "" ]; then
  checkLast 1 "Missing EXAMPLE_REPO! - double-check site.properties "
fi

## check for correct user
if [ "$USER" != "root" ]; then
  echo ""
  echo "[ERROR] install should run by root user, exiting "
  echo ""
  echo "hint: re-run with sudo (if example user)"
  echo ""
  exit 1
fi

## enable logging here
if [ -f /home/example/upgrade.log.$TODAY ]; then
  mv /home/example/upgrade.log.$TODAY /home/example/upgrade.log.$TODAY.$HOUR
fi
export PYTHONPATH=/opt/example
exec > >(tee -a /home/example/upgrade.log.$TODAY) 2>&1
echo "*** example application software upgrade started at $NOW *** "

## DEBUG - uncomment for debug level messages
#echo "DEBUG MESSAGES: "
#echo "  arg1 is set to $VFLAG"
#echo "  version set to $VER"
#echo "  curr version set to $CURR_VER"
#echo "  repo is set to $REPO"
#echo "  EXAMPLE_REPO is set to $EXAMPLE_REPO "
#echo "  $0: $# parameters:"
#echo " ... sleeping for 15 seconds - ctrl-c to exit ... "
#sleep 15

## check for existing .example directories
echo "checking system for previous upgrades ... "
if [ ! -d /opt/$CURR_VER ]; then
  echo "  [WARN] no backups folder found "
  createDir /opt/$CURR_VER
else
  echo "  [WARN] Previous backup folder detected, removing its contents "
  rm -rf /opt/$CURR_VER/* &> /dev/null
fi

## stop sys_procs on server
echo "checking for running sys_procs on server ... "
case "$(ps -ef | grep sys- | wc -l)" in
0)  echo "  [PASS] example process not running "
    ;;
*)  echo "  [OK] an instance of example process was detected and stopped by upgrade.sh:   $(date)" >> /var/log/example/upgrade.log.$TODAY
    sudo -u example PYTHONPATH=/opt/example python /opt/example/common/utilities/sys_procs.py -d > /dev/null
    ;;
esac

# wait for sys-vault-stat to shutdown
COUNT=0
while [ "$(pidof sys-vault-stat | wc -w)" == "1" ] && [ $COUNT -lt 30 ]; do 
  sleep 1
  let COUNT=$COUNT+1
done

# recheck for running sys- pids
echo "Recheck for running example process on server ... "
case "$(ps -ef | grep sys- | wc -l)" in
0)  echo "  [PASS] example proceses not running "
    ;;
*)  echo "  [WARN] an instance of example process was detected. Retry stop process by upgrade.sh:  $(date) "
    echo "  [WARN] an instance of example process was detected. Retry stop process by upgrade.sh:  $(date) " >> /var/log/example/upgrade.log.$TODAY
    sudo -u example PYTHONPATH=/opt/example python /opt/example/common/utilities/sys_procs.py -d > /dev/null
    pkill sys-
    ps -ef | grep sys- | awk '{print "kill -9 "$2" &> /dev/null"}' | /bin/bash
    ;;
esac

## create backup file(s)
echo "creating a backup of existing configuration files ... "
# save network interfaces file
cp /etc/network/interfaces /opt/$CURR_VER/
# puppet general config
puppet --genconfig > /opt/$CURR_VER/puppet_genconfig
# grab a syscfg copy
sudo -u example PYTHONPATH=/opt/example python /opt/example/common/create_syscfg.py > /opt/$CURR_VER/syscfg.out

# mysqldump for icinga DB
echo "checking for running mysql server ... "
case "$(pidof mysqld | wc -w)" in
0)  echo "  [PASS] mysql not detected "
    ;;
1)  echo "  [OK] mysql was detected, dump the database by upgrade.sh:   $(date)" >> /var/log/example/upgrade.log
    mysqldump --user=root --password=St1ckyB1t --all-databases --events --ignore-table=mysql.events > /opt/$CURR_VER/mysql_backup_`date +%Y%m%d`.sql
    ;;
*)  echo "Removed extra mysql pids:    $(date)" >> /var/log/example/upgrade.log
    kill $(pidof mysqld | awk '{print $1}')
    ;;
esac

## BACKUP existing /opt/example --> /opt/$CURR_VER/example
if [ -d /opt/example ]; then
  echo "  [OK] active /opt/example detected "
  rsync -arl /opt/example /opt/$CURR_VER
  echo "  [OK] active /opt/example copied to /opt/$CURR_VER "
else
  checkLast 1 "Missing /opt/example directory! Aborting at $NOW "
fi

## APT switch to PROD, DEVEL or QA repos with -r repo
echo "checking the example package repository settings ... "
if [ "$REPO" == "prod" ]; then
  sed "/^deb http:\/\/$EXAMPLE_REPO/d" -i /etc/apt/sources.list
  sed "/^deb http:\/\/updates.example.com/d" -i /etc/apt/sources.list
  sed "/^deb-src http:\/\/updates.example.com/d" -i /etc/apt/sources.list
  sed "$ a\deb http:\/\/$EXAMPLE_REPO\/$VER\/archives .\/ " -i /etc/apt/sources.list
  echo "retrieving latest $REPO version of software from $EXAMPLE_REPO ... "
else
  echo "  [WARN] QA or DEVEL apt repo detected ... "
  echo "    -*-*- development purposes only -*-*- "
  echo "        -*-*- USE AT OWN RISK -*-*- "
  sed "/^deb http:\/\/$EXAMPLE_REPO/d" -i /etc/apt/sources.list
  sed "/^deb http:\/\/updates.example.com/d" -i /etc/apt/sources.list
  sed "/^deb-src http:\/\/updates.example.com/d" -i /etc/apt/sources.list
  #pull regular pkgs but switch between QA + DEVEL example.debs
  sed "$ a\deb http:\/\/updates.example.com\/$VER\/archives .\/ " -i /etc/apt/sources.list
  sed "$ a\deb http:\/\/updates.example.com\/$REPO .\/ " -i /etc/apt/sources.list
  echo "retrieving latest $REPO version of software from http://updates.example.com/$REPO ... "
fi

## install example deb package
apt-get update -yqq
apt-get install --reinstall example=$VER* --force-yes -yqq
checkLast $? "Failed to retrieve example package! Aborting at $NOW"
echo "  [OK] latest example $REPO version installed successfully "

# check /opt/example perms
FIXPERMS

## CASS DB schema upgrade
echo "checking for cassandra DB schema verification ... "
if [ -f /opt/example/conf/site.properties ]; then
  VAULT=`grep VAULT /opt/example/conf/site.properties | grep -v '^#' | awk -F "=" '{print $2}'`
  CNAME=`grep CASS1_NAME /opt/example/conf/site.properties | grep -v '^#' | awk -F "=" '{print $2}'`
else
  echo "  [WARN] missing site.properties file causes unknown keyspace name "
fi
case "$(dpkg -l | grep cassandra | wc -l)" in
  0)  echo "  [SKIP] no cassandra package is installed on this server "
      echo "  [SKIP] no cassandra package is installed on this server: $(date) " >> /var/log/example/upgrade.log.$TODAY
      ;;
  1)  echo "  [OK] cassandra package was detected by upgrade.sh: $(date) "
      echo "  [OK] cassandra package was detected by upgrade.sh: $(date) " >> /var/log/example/upgrade.log.$TODAY
      python /opt/example/cassandra/create_keyspace.py upgrade $(echo $VAULT | cut -f 2 -d "=" ) -s $(echo $CNAME | cut -f 2 -d "=" )
      ;;
  *)  echo "  [WARN] unknown cassandra was not properly detected by upgrade.sh: $(date) "
      echo "  [WARN] unknown cassandra was not properly detected by upgrade.sh: $(date) " >> /var/log/example/upgrade.log.$TODAY
      python /opt/example/cassandra/create_keyspace.py upgrade $(echo $VAULT | cut -f 2 -d "=" ) -s $(echo $CNAME | cut -f 2 -d "=" )
      ;;
esac

# copy new reports from templates
if [ -d /etc/pnp4nagios/templates ]; then
  cp /opt/example/monitor/pnp4nagios/*.php /etc/pnp4nagios/templates/
  chmod 755 /etc/pnp4nagios/templates/*.php
  cp /opt/example/monitor/pnp4nagios/Special/*.php /etc/pnp4nagios/templates.special/
  chmod 755 /etc/pnp4nagios/templates.special/*.php
fi

if [ -s /sbin/zpool ]; then
  apt-get install -y libboost-program-options1.46-dev libboost-python1.46-dev libboost-regex1.46-dev
fi

# update config and restart process
if [ -f /opt/example/conf/host.properties ]; then
  SITE_PREFIX=(`grep -m 1 "SITE_PREFIX" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
fi

if [ -f /opt/example/conf/site.properties ]; then
  COPIES=(`grep "$SITE_PREFIX"COPIES /opt/example/conf/site.properties | awk -F "=" '{print $2}' `)
fi

if [ "$COPIES" == "1" ]; then
  grep -n -i -m 1 'maintenance.copy_subobjects.performCopySubObjects' /opt/example/maintenance/default.cfg | \
          awk -F ":" '{print "sed -i \x27"$1+2",+0 s/True/False/\x27 /opt/example/maintenance/default.cfg"}' \
          | /bin/sh
fi

# turn sys_procs back on (run it as example user)
if [ -d /opt/example/common/utilities ]; then
  echo "re-starting sys_procs -u ... "
  sudo -u example PYTHONPATH=/opt/example python /opt/example/common/utilities/sys_procs.py -u
  echo "  [OK] sys_procs re-started "
fi

# respawn the maint jobs with default
echo "re-starting maintenance reporting jobs ... "
sudo -u example PYTHONPATH=/opt/example python /opt/example/maintenance/maintenance_cli.py -l /opt/example/maintenance/default.cfg
echo "  [OK] maintenance reporting jobs re-started "

# end message
if dpkg-query -l example | grep -q '^i'; then
  echo "verifying the example software is installed properly ... "
  echo "  [SUCCESS] example Software Application has been updated with $REPO package at $NOW "
else
  echo ""
  echo "  [ERROR] failed to upgrade the example Software Application, exiting at $NOW "
  echo ""
fi
exit 0