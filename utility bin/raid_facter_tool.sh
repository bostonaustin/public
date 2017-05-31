#!/bin/bash
# setup or verify the server's raid configuration is ready for application

create_directory() 
{
    if
    [ ! -d "$1" ]; then
        sudo mkdir "$1"
        echo "$1" "created"
    else
        echo "$1" "already exists"
    fi
}

check_last_command()
{
  if [ ! $1 -eq 0 ]; then
    echo "*** Check failure:"
    echo "*** $2"
    exit 1
  fi
}

if [ "$USER" != "root" ]; then
  echo ""
  echo "[ERROR] install should run by root user ***"
  exit 1
else
  echo ""
  echo "*** Welcome to the RAID tool ***"
  echo ""
  echo "  [OK] starting to verify the RAID configuration for this node."
fi

is_facter="/usr/bin/facter"

if [ -f "$is_facter" ]; then
  echo ""
  echo "  [OK] $is_facter is installed and found properly."
else
  echo ""
  echo "[ERROR] a required package $is_facter was not found."
  echo ""
  echo "Attempting to install the missing facter pacakge via apt-get ..."
  echo ""
  apt-get install facter -y --force-yes
fi

[ `which facter` == /usr/bin/facter ]
check_last_command $? "[ERROR] exiting because facter is not installed properly ..."

if [ `/usr/bin/facter kernelrelease` != 3.2.0-58-generic ]; then
  echo ""
  echo "[ERROR] wrong kernel version"
  echo ""
  echo "Please Contact Customer Support"
  echo ""
  exit 1
fi

## DETECT a VM enviroment and exit (at least for now)
if [ `/usr/bin/facter is_virtual` != false ]; then
  echo ""
  echo "[ERROR] this operation is not required for Virtual environments."
  echo ""
  echo "Please Contact Customer Support"
  echo ""
  exit 1
fi

if [ `/usr/bin/facter physicalprocessorcount` == 2 ]; then
  if [ `/usr/bin/facter processorcount` == 16 ]; then
    if [ `/usr/bin/facter processor0` == "AMD Opteron(TM) Processor 6212" ]; then
      HOST_TYPE="STOR"
      INSTALL_TYPE="INSTALL"
    fi
  fi
fi

if [ `/usr/bin/facter physicalprocessorcount` == 1 ]; then
  if [ `/usr/bin/facter processorcount` == 8 ]; then
    if [ `/usr/bin/facter interfaces` == eth0,eth1,lo ]; then
      HOST_TYPE="CASS"
      INSTALL_TYPE="INSTALL"
    fi
  fi
fi

if [ `/usr/bin/facter physicalprocessorcount` == 1 ]; then
  if [ `/usr/bin/facter processorcount` == 8 ]; then
    if [ `/usr/bin/facter netmask_bond0` == 255.255.255.0 ]; then
      HOST_TYPE="MGMT"
      INSTALL_TYPE="INSTALL"
    fi
  fi
fi

echo "  [OK] Compatible Server Detected"
echo "       Host type detected: $HOST_TYPE"
echo "       Install type detected: $INSTALL_TYPE"

if [ "$HOST_TYPE" != "STOR" ]; then
  df -H | grep '/data' 1> /dev/null 2> /dev/null
  if [ $? -eq 0 ]; then
    echo "  [OK] required /data volume is already defined properly"
    echo ""
    echo "*** RAID tool completed sucessfully ***"
    echo ""
  else
    # configure the raid1 for 4TB /data
    grep -w sdc /proc/mdstat > /dev/null
    if [ $? -eq 0 ]; then
      MDDEV=`grep -w -m 1 sdc /proc/mdstat | awk '{print "/dev/"$1}'`
    else
      MDDEV="/dev/md7"
      echo "y" | mdadm --create $MDDEV --level=1 --raid-devices=2 /dev/sdc /dev/sdd
    fi
    if [ "$HOST_TYPE" != "MGMT" ] || [ $MGMTN -eq 1 ]; then
      echo "y" | mkfs -t ext3 $MDDEV
      create_directory "/data"
      mount $MDDEV /data
      df -H | grep '/data' 1> /dev/null 2> /dev/null
      check_last_command $? "Failed DATA RAID configuration. Aborting RAID tool"
      echo "# /data was on $MDDEV during installation" >> /etc/fstab
      UUID=`lsblk -o UUID,MOUNTPOINT | grep -m 1 '/data' | awk '{print $1}'`
      echo "UUID=$UUID  /data ext3 nobootwait 0 0" >> /etc/fstab
      echo ""
      echo "  [OK] required /data volume is defined properly"
      echo ""
      echo "*** RAID tool completed sucessfully ***"
      echo ""
    fi
  fi
fi

if [ "$HOST_TYPE" == "CASS" ]; then
  df -H | grep '/ssd' 1> /dev/null 2> /dev/null
  if [ $? -eq 0 ]; then
    echo "/ssd volume already defined"
  else
    # configure /ssd volume
    grep -w sde /proc/mdstat > /tmp/sde_in_mdstat
    if [ -b "/dev/sdf" ]; then
      if [ -s "/tmp/sde_in_mdstat" ]; then
        SSDDEV=`grep -w -m 1 sde /proc/mdstat | awk '{print "/dev/"$1}'`
      else
        SSDDEV="/dev/md9"
        mdadm --create $SSDDEV --level=0 --raid-devices=2 /dev/sde /dev/sdf
      fi
    else
      SSDDEV="/dev/sde"
    fi
    echo y | mkfs -t ext3 $SSDDEV
    create_directory "/ssd"
    mount $SSDDEV /ssd
    df -H | grep '/ssd' 1> /dev/null 2> /dev/null
    check_last_command $? "Failed SSD configuration. Aborting RAID tool"
    UUID=`lsblk -o UUID,MOUNTPOINT | grep -m 1 '/ssd' | awk '{print $1}'`
    echo "# /ssd was on $SSDDEV during installation" >> /etc/fstab
    echo "UUID=$UUID /ssd ext3 nobootwait 0 0" >> /etc/fstab
    echo ""
    echo "  [OK] required /ssd volume is defined properly"
    echo ""
    echo "*** RAID tool completed sucessfully ***"
    echo ""
  fi
fi
exit 0