#!/bin/bash
# @author:          Austin Matthews
# @description:     script to to configure management server HA
#                   run this script on the two management server simoultanously after running install-server.sh
#                   Part 2 install and configure peacemker and heartbeat

function check_condition {
# First parameter status
# Second parameter message
  if [ ! $1 -eq 0 ]; then
    echo "*** Check failure:"
    echo "*** $2"
    exit 1
  fi
}

function create_dir {
    if
    [ ! -d "$1" ]; then
        sudo mkdir "$1"
        echo "$1" "created"
    else
        echo "$1" "already exists"
    fi
}

# start logging
exec > >(tee -a /root/heartbeat.log) 2>&1
set -x -v

# Verify that site.properties  were updated
grep INSTALLER_INPUT /opt/example/conf/site.properties > /dev/null
if [ $? -eq 0 ]; then
  check_condition 1 "Please update /opt/example/conf/site.properties file ***"
fi

# Verify that install is running by root user
if [ "$USER" != "root" ]; then
  check_condition 1 "Install should run by root user ***"
fi

HOST_TYPE=(`grep -m 1 "HOST_TYPE" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
if [ "$HOST_TYPE" != "MGMT" ];  then
  check_condition 1 "This script should run only on Management Servers ***"
fi

grep `hostname` /opt/example/conf/site.properties | grep -v '^#' | grep -m 1 "=" | \
    awk -F "=" '{print $1}' | grep '1' > /dev/null
if [ $? -eq 0 ]; then
  PRIMARY="PRIMARY"
  drbdadm primary r0
  crm node online mgmt1
fi

MGMTN=`grep -E MGMT.?_NAME /opt/example/conf/site.properties | grep -v ^# | wc -l`
if [ ! "$MGMTN" -eq "2" ]; then
  check_condition 1 "Not Redundant Management servers! ***"
fi

SYNC=`drbd-overview | grep r0 | awk '{print $4}'`
if [ "$PRIMARY" == "PRIMARY" ] && [ "$SYNC" != "UpToDate/Inconsistent" ]; then
  check_condition 1 "DRBD volume is not UpToDate ***"
fi

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

# Stop running services before moving their data to common location.
service icinga stop
service logstash-central stop
service logstash-agent stop
service elasticsearch stop
service npcd stop
service redis-server stop
service mysql stop
service zookeeper stop

# Remove init script from HA controlled service
update-rc.d -f icinga remove
update-rc.d -f mysql remove
update-rc.d -f npcd remove
update-rc.d -f elasticsearch remove
update-rc.d -f apache2 remove
update-rc.d -f drbd remove

## move directories from local to shared (move old to /backup for restore)
if [ "$PRIMARY" == "PRIMARY" ] && [ -d /data ]; then
  if [ ! -d /backup ]; then
    create_dir /backup
    create_dir /backup/spool
    chown -R nagios:nagios /data/spool
    chmod 755 /data/spool
  fi
  if [ -d /data/spool ]; then
    create_dir /data/spool
  fi
  if [ -d /var/lib/redis ]; then
    cp -r /var/lib/redis/ /data/
    chown -R redis:redis /data/redis/
  fi
  if [ -d /var/lib/elasticsearch ]; then
    cp -r /var/lib/elasticsearch/ /data/
    chown -R elasticsearch:elasticsearch /data/elasticsearch
  fi
  if [ -d /var/spool/pnp4nagios ]; then
    cp -r /var/spool/pnp4nagios/ /data/spool/
    chown -R nagios:www-data /data/spool/pnp4nagios
  fi
  if [ -d /var/lib/pnp4nagios ]; then
    cp -r /var/lib/pnp4nagios/ /data/
    chown -R nagios:www-data /data/pnp4nagios
  fi
  if [ -d /var/lib/mysql/ ]; then
    cp -r /var/lib/mysql/ /data
    chown -R mysql:mysql /data/mysql
    chmod -R 660 /data/mysql/mysql
    chmod 755 /data/mysql
    chmod 660 /data/mysql/ib*
    chmod 700 /data/mysql/mysql
  fi
  if [ ! -f /backup/.HA_files_moved_to_backup_dir ]; then
    mv /var/lib/redis/ /backup/
    mv /var/lib/elasticsearch/ /backup/
    mv /var/spool/pnp4nagios/ /backup/spool
    mv /var/lib/pnp4nagios/ /backup/
    mv /var/lib/mysql/ /backup
    touch /backup/.HA_files_moved_to_backup_dir
  else
    echo "  [OK] /backup/.HA_files_moved_to_backup_dir exists already "
  fi
elif [ -d /data ]; then
  chown -R nagios:nagios /data/spool
  chmod 755 /data/spool
  chown -R redis:redis /data/redis/
  chown -R elasticsearch:elasticsearch /data/elasticsearch
  chown -R nagios:www-data /data/spool/pnp4nagios
  chown -R nagios:www-data /data/pnp4nagios
  chown -R mysql:mysql /data/mysql
  chmod -R 660 /data/mysql/mysql
  chmod 755 /data/mysql
  chmod 660 /data/mysql/ib*
  chmod 700 /data/mysql/mysql
fi

## redis
if [ -d /data ] && [ -d /var/lib/redis ]; then
  ln -fs /data/redis /var/lib
  sed -i 's&dir /var/lib/redis&dir /data/redis&' /etc/redis/redis.conf
fi
# set sysctl for redis-server
sysctl vm.overcommit_memory=1

## elasticsearch
if [ -d /data ] && [ -f /etc/elasticsearch/elasticsearch.yml ]; then
  ln -fs /data/elasticsearch /var/lib
  sed -i 's&# path.data: /path/to/data$&path.data: /data/elasticsearch&' /etc/elasticsearch/elasticsearch.yml
  sed -i 's&# path.logs: /path/to/logs&path.logs: /data/logs/elasticsearch&' /etc/elasticsearch/elasticsearch.yml
fi

## pnp4nagios
if [ -d /data ] && [ -f /etc/elasticsearch/elasticsearch.yml ]; then
  ln -fs /data/spool/pnp4nagios /var/spool
  sed -i 's&perfdata_spool_dir = /var/spool/pnp4nagios/npcd/&perfdata_spool_dir = /data/spool/pnp4nagios/npcd/&' /etc/pnp4nagios/npcd.cfg
  sed -i 's&perfdata_file = /var/spool/pnp4nagios/nagios/perfdata.dump&perfdata_file = /data/spool/pnp4nagios/nagios/perfdata.dump&' /etc/pnp4nagios/npcd.cfg
  ln -fs /data/pnp4nagios /var/lib
  sed -i 's&RRDPATH = /var/lib/pnp4nagios/perfdata&RRDPATH = /data/pnp4nagios/perfdata&' /etc/pnp4nagios/process_perfdata.cfg
fi
chmod 777 -R /data/spool/pnp4nagios/

# MySql (for ocf:mysql added link from /var/lib/mysqld)
if [ -d /data ] && [ -f /var/lib/mysqld ]; then
  ln -fs /data/mysql /var/lib
  ln -fs /data/mysql /var/lib/mysqld
  sed -i 's&^datadir\t\t= /var/lib/mysql&datadir\t\t= /data/mysql&' /etc/mysql/my.cnf
  sed -i 's&/var/lib/mysql/&/data/mysql/&' /etc/apparmor.d/usr.sbin.mysqld
fi
# reset mysql data location
chown -R mysql.mysql /data/mysql

# Install init script for example_initial_folder
cp /opt/example/install/sc_mgmt_procs.txt /etc/init.d/sc_mgmt_procs
chmod +x /etc/init.d/sc_mgmt_procs

# Install heartbeat cluster stack (v.3.0 is called cluster-glue)
if [ ! -d /etc/heartbeat ]; then
  apt-get install -y heartbeat cluster-glue pacemaker
fi

# Heartbeat configuration
grep bond0 /etc/network/interfaces | grep -E -v '^#' > /dev/null
if [ $? -eq 0 ]; then
  VIP="bond0:1"
else
  VIP="eth0:1"
fi

if [ "$PRIMARY" == "PRIMARY" ]; then
  cat > /etc/ha.d/haresources <<EOF
MGMT1_NAME IPaddr::MGMT_HA_VIP/24/$VIP
EOF
  grep 'MGMT1_NAME' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
    awk -F "=" '{print "s/"$1"/"$2"/g /etc/ha.d/haresources"}' | xargs -n2 sed -i
  grep 'MGMT_HA_VIP' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
    awk -F "=" '{print "s/"$1"/"$2"/g /etc/ha.d/haresources"}' | xargs -n2 sed -i

  cat > /etc/ha.d/ha.cf <<EOF
autojoin none
#mcast bond0 239.0.0.43 694 1 0
node MGMT1_NAME
node MGMT2_NAME
bcast eth2
warntime 15
deadtime 30
initdead 120
keepalive 2
pacemaker respawn
EOF
  grep 'MGMT' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
    awk -F "=" '{print "s/"$1"/"$2"/g /etc/ha.d/ha.cf"}' | xargs -n2 sed -i

  # generate the ha.d authkeys (on PRI only - then scp to PEER)
  ( echo -ne "auth 1\n1 sha1 "; dd if=/dev/urandom bs=512 count=1 | openssl md5 ) > /etc/ha.d/authkeys
  chmod 600 /etc/ha.d/authkeys
  # scp should work w/o a password now
  scp /etc/ha.d/authkeys $PEER:/etc/ha.d/*
  drbdadm primary r0
  crm node online $hostname
else
  # Wait for authkeys transfer complete
  while [ ! -s "/etc/ha.d/authkeys" ]; do
    echo "Waiting for authkeys from peer before continue"
    read -n1 -rsp $'Press A or a key to Abort or other key to continue...\n' key
    if [ "$key" == "A" ] || [ "$key" == "a" ]; then
      exit
    fi
    echo "`date` waiting for authkeys file transfer"
  done
  drbdadm primary r0
  crm node online $hostname
fi
service heartbeat start

# Wait intil the nodes are registered
COUNT=0
crm status | grep Online 1> /dev/null 2>&1
while [ ! $? -eq 0 ] && [ COUNT -lt 10 ]; do
  echo "`date` Waiting for cluster to come Online"
  sleep 10
  crm status | grep Online 1> /dev/null 2>&1
  count +1
done

set -x
if [ "$PRIMARY" == "PRIMARY" ]; then
  ## CRM setup cluster resources for icinga / ido2db / logstash / redis / elasticsearch
  cp /opt/example/install/crm.skel crm.txt
  grep 'MGMT' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
  awk -F "=" '{print "s/"$1"/"$2"/g crm.txt"}' | xargs -n2 sed -i
  grep 'MGMT_HA_VIP' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
    awk -F "=" '{print "s/"$1"/"$2"/g crm.txt"}' | xargs -n2 sed -i
  ## load crm settings into crm console
  #cibadmin -C -o resources -x crm.txt
  cibadmin -E --force
  crm configure < crm.txt
  sleep 10
  crm status
  RESOURCES="p_drbd_data:0 p_drbd_data:1 p_sc_mgmt_procs p_elasticsearch p_redis-server p_icinga p_npcd p_mysql p_apache2 p_ip_shared p_fs_data"
  crm status | grep p_sc_mgmt_procs | grep Started > /dev/null

  # Modify syscfg consoleApiServer to be MGMT_HA_VIP
  grep 'MGMT_HA_VIP' /opt/example/conf/site.properties | grep "=" | grep -v "^#" | \
    awk -F "=" '{print "python /opt/example/common/create_syscfg.py -consoleApiServer "$2" -w"}' | /bin/sh
fi
crm status
sleep 5

echo ""
echo "[SUCCESS] HA configuration completed. Verify the HA health by running:  # crm status "
echo ""
exit 0