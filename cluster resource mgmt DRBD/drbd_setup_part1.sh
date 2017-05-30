#!/bin/bash
# @date:            21MAY14
# @author:          Austin Matthews
# @description:     script to to configure management server HA
#                   run this script on the two management server simoultanously after running install-server.sh
#                   Part 1 create drbd resource r_data with the clustered /data volume

## define functions
# create_dir
function create_dir {
  if [ ! -d "$1" ]; then
    sudo mkdir "$1"
    echo "  [OK]" "$1" "created "
  else
    echo "  [WARN]" "$1" "already exists "
  fi
}
# check_condition
function check_condition {
  if [ ! $1 -eq 0 ]; then
    echo "[ERROR] " "check_condition on " "$2"
    exit 1
  fi
}

exec > >(tee -a /root/drbd.log) 2>&1

# check for correct user
if [ "$USER" != "root" ]; then
  echo ""
  echo "[ERROR] install should run by root user, exiting "
  echo ""
  echo "hint: re-run with sudo (if example user)"
  echo ""
  exit 1
else
  export PYTHONPATH=/opt/example
  echo ""
  echo "*** Welcome to the example management server High Availability [HA] tool ***"
  echo ""
  echo "starting to verify apt sources.list ... "
fi

# add LINBIT supported account to APT sources.list
if grep -q 'deb http://packages.linbit.com/LINBIT_KEY/8.4' /etc/apt/sources.list; then
  echo "  [OK] LINBIT apt repo includes support hashID for example "
elif grep -v 'deb http://packages.linbit.com/LINBIT_KEY/8.4' /etc/apt/sources.list; then
  echo "  [WARN] LINBIT support hashID not detected ... attempting to add "
  sed "$ a\deb http:\/\/packages.linbit.com\/LINBIT_KEY\/8.4\/ubuntu precise main " -i /etc/apt/sources.list
  echo "  [OK] LINBIT apt repo includes hash for example "
else
  echo "[OK] LINBIT incorrect apt repo detected, correctly setting hashID "
  sed "s/^deb http:\/\/packages.linbit.com/deb http:\/\/packages.linbit.com\/LINBIT_KEY\/8.4\/ubuntu precise main " -i /etc/apt/sources.list
fi

# NEED to fix missing gpg pubkeys & get latest version of DRBD8
# GOES INTERNET
echo ""
echo "checking the apt repo public keys ... "
if [ ! -d /root/.gnupg ]; then
  gpg --keyserver pgp.mit.edu --recv-keys 0x282B6E23
  gpg --export -a 282B6E23 | sudo apt-key add -
  gpg --keyserver pgp.mit.edu --recv-keys 0x36862847
  gpg --export -a 36862847 | sudo apt-key add -
  gpg --keyserver pgp.mit.edu --recv-keys 0xB999A372
  gpg --export -a B999A372 | sudo apt-key add -
  cp -R ~/.gnupg/ /home/example/
  chown -R example:example /home/example
else
  gpg --keyserver pgp.mit.edu --recv-keys 0x282B6E23
  gpg --export -a 282B6E23 | sudo apt-key add -
  cp -R ~/.gnupg/ /home/example/
  chown -R example:example /home/example
  echo "  [OK] apt repo public keys detected "
fi

# Verify that site.properties were updated
grep INSTALLER_INPUT /opt/example/conf/site.properties > /dev/null
if [ $? -eq 0 ]; then
  check_condition 1 "Please update /opt/example/conf/site.properties file ***"
fi
HOST_TYPE=(`grep -m 1 "HOST_TYPE" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
if [ "$HOST_TYPE" != "MGMT" ];  then
  check_condition 1 "This script should run only on Management Servers ***"
fi
grep `hostname` /opt/example/conf/site.properties | grep -v '^#' | grep -m 1 "=" | \
    awk -F "=" '{print $1}' | grep '1' > /dev/null
if [ $? -eq 0 ]; then
  PRIMARY="PRIMARY"
fi
MGMTN=`grep -E MGMT.?_NAME /opt/example/conf/site.properties | grep -v ^# | wc -l`
if [ ! "$MGMTN" -eq "2" ]; then
  check_condition 1 "[ERROR] Missing a Management pair of servers, check your site.properties settings "
fi

# do not start if no md7 raid device
cat /proc/mdstat | grep -w 'md7' > /dev/null
check_condition $? "[ERROR] No /dev/md7 RAID device detected, check your mdadm settings  "

# debug info
ifconfig eth2
cat /etc/udev/rules.d/70-persistent-net.rules
dmesg | grep eth2

# Verify that eth2 (heartbeat) works properly
if [ "$PRIMARY" == "PRIMARY" ]; then
  PEER="`grep MGMT2_HEARTBEAT /opt/example/conf/site.properties| grep -v ^# | awk -F "=" '{print $2}'`"
else
  PEER="`grep MGMT1_HEARTBEAT /opt/example/conf/site.properties| grep -v ^# | awk -F "=" '{print $2}'`"
fi
nmap -p22 $PEER |  grep 'Host is up' 1>/dev/null 2>/dev/null
while [ ! $? -eq 0 ]; do
  echo "The peer server is not ready yet"
  echo "Make sure that the server/IP $PEER is ready before continue"
  read -n1 -rsp $'Press A or a key to Abort or other key to continue...\n' key
  if [ "$key" == "A" ] || [ "$key" == "a" ]; then
    exit
  fi
  nmap -p22 $PEER |  grep 'Host is up' 1>/dev/null 2>/dev/null
done

## High Availability configuration
echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
echo ""
echo "fetching latest stable version of DRBD8 ... "
apt-get update -yqq
apt-get install -y --force-yes drbd8-utils drbd8-module-`uname -r`
echo "  [OK] successfully downloaded DRBD8 utilities "

# setup drbd.conf resources
cat > /etc/drbd.d/global_common.conf <<EOFg
global {
  usage-count yes;
}
common {
  net {
    protocol C;
  }
}
EOFg

cat > /etc/drbd.d/r0.res <<EOFd
# Resource r0 DRBD0 /dev/md7: 4000.0 GB
resource r0 {
  protocol        C;
  device          minor 1;
  disk            /dev/md7;
  meta-disk       internal;

  disk {
    resync-rate     3G;
  }
  on MGMT1_NAME {
    address MGMT1_HEARTBEAT:7789;
  }
  on MGMT2_NAME {
    address MGMT2_HEARTBEAT:7789;
  }
}
EOFd
grep 'MGMT' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
  awk -F "=" '{print "s/"$1"/"$2"/g /etc/drbd.d/r0.res"}' | xargs -n2 sed -i

## export SSH keys to PEER
## *STOPS* and waits 60 secs for remote server's root ssh password (security risk storing plain-text)
## prefer to have Site Installer insert of ensure the customer set a root password
#
# *GIVE ROOT PASSWORD FOR EACH PEER ONCE*
#
#sshpass -e ssh -oBatchMode=no example_initial_folder@$PEER

if [ "$PRIMARY" == "PRIMARY" ] && [ ! -f /root/.ssh/id_rsa.pub ]; then
  ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
  echo "StrictHostKeyChecking no" > /root/.ssh/config
  if [ ! -f /root/.example-rsa-sent ]; then
    echo "yes \n" | ssh-copy-id root@$PEER
    touch /root/.example-rsa-sent
  fi
  scp /etc/drbd.d/* root@$PEER:/etc/drbd.d/
  scp /opt/example/conf/* root@$PEER:/opt/example/conf
elif [ ! -f /root/.ssh/id_rsa.pub ]; then
  ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
  echo "StrictHostKeyChecking no" > /root/.ssh/config
  if [ ! -f /root/.example-rsa-sent ]; then
    echo "yes \n" | ssh-copy-id root@$PEER
    touch /root/.example-rsa-sent
  fi
elif [ "$PRIMARY" == "PRIMARY" ] && [ -f /root/.ssh/id_rsa.pub ]; then
  echo "StrictHostKeyChecking no" > /root/.ssh/config
  if [ ! -f /root/.example-rsa-sent ]; then
    echo "yes \n" | ssh-copy-id root@$PEER
    touch /root/.example-rsa-sent
  fi
  scp /etc/drbd.d/* root@$PEER:/etc/drbd.d/
  scp /opt/example/conf/* root@$PEER:/opt/example/conf
fi

# create metadata
RTMP=`drbd-overview | grep -w r0 | awk '{print $1}' | cut -c1`
if [ "$RTMP" != "1" ]; then
  dd if=/dev/zero of=/dev/md7 bs=1024k count=100
  echo "yes" | drbdadm create-md r0
  modprobe drbd
else
  echo "resource r0 already configured "
fi

# for 8.4.4 - restart DRBD to finish configuring the resource
service drbd restart

# wait for connection to be complete sync and get Pri UpToDate
CONN=`drbd-overview | grep -w r0 | awk '{print $2}'`
while [ "$CONN" != "Connected" ] && [ "$CONN" != "SyncTarget" ] && [ "$CONN" != "SyncSource" ]; do
  sleep 5
  drbd-overview
  CONN=`drbd-overview | grep -w r0 | awk '{print $2}'`
done

# Online on the primary node:
if [ "$PRIMARY" == "PRIMARY" ] && [ "$CONN" == "Connected" ]; then
  drbdadm primary --force r0
fi
set +x

# Wait for initial sync to complete
if [ "$PRIMARY" == "PRIMARY" ]; then
  SYNC=`drbd-overview | grep r0 | awk '{print $4}'`]
  while [ "$SYNC" != "UpToDate/Inconsistent" ]; do
    sleep 5
    date
    drbd-overview
    SYNC=`drbd-overview | grep r0 | awk '{print $4}'`
  done
fi
set -x

if [ "$PRIMARY" == "PRIMARY" ] && [ ! -d /data ]; then
  mkfs.ext4 /dev/drbd0
  create_dir "/data"
  mount -t ext4 /dev/drbd0 /data
elif [ ! -d /data ]; then
  create_dir "/data"
fi
set +x

echo ""
echo "[SUCCESS] run mgmt_ha_part2.sh on both nodes to finish HA configuration "
echo ""
exit 0