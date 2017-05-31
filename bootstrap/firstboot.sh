#!/bin/bash
# example of how-to configure a node from CD or USB drive
# create a init file to be run on first boot of the machine

VERSION=1.0.0
REPO=install.example.com

# detect USB or CDROM offline/online media
case $(ps -o stat= -p $$) in
  *+*) # attached process
       # Verify that install is running by root user
       if [ "$USER" != "root" ]; then
         echo "[ERROR] Install should run by root user "
         exit 1
       fi
       # Check existance of install media
       if [ -d "/media/usb/install" ]; then
         MEDIA=usb
         echo "  [OK] USB Install "
       elif [ -d "/media/cdrom/install" ]; then
         MEDIA=cdrom
         echo "  [OK] CDROM Install "
       else
         echo "[WARN] no offline install media detected"
         echo ""
         read -n1 -rsp $'Press X to exit, or any other key to continue online install [default - continue]\n' key
         if [ "$key" == "X" ] || [ "$key" == "x" ]; then
           echo ""
           exit 1
         fi
         MEDIA=network
       fi
       if [ -f /home/example/.firstboot.log ]; then
         mv /home/example/.firstboot.log /home/example/.firstboot.log.prev
       fi
       ;;
  *)   MEDIA=network
       ;;
esac

echo "[WARN] Please wait for kernel re-configuration"
set -x -v
exec 1>/home/example/.firstboot.log 2>&1

# create minimum directory structure
mkdir /opt/example/conf
mkdir /opt/example/install
mkdir /var/log/example
chown example:example /var/log/example
chown -R example:example /opt/example

# set apt to example
if [ ! -e "/etc/apt/sources.list.bkp" ]; then
  cp /etc/apt/sources.list /etc/apt/sources.list.bkp
fi

# modify apt sources.list
case $MEDIA in
  network)
cat > /etc/apt/sources.list << EOF
deb http://$REPO/$VERSION/archives ./
EOF
          ;;
  usb|cdrom)
cat > /etc/apt/sources.list << EOF
# set apt sources to only use CD or USB
deb file:/media/$MEDIA/archives/ /
EOF
          ;;
esac

# fetch site.properties and bootstrap installer file
case $MEDIA in
  network)
    /usr/bin/curl -o /root/README http://$REPO/$VERSION/install/README
    /usr/bin/curl -o /opt/example/install/install-server.sh http://$REPO/$VERSION/install/install-server.sh
    /usr/bin/curl -o /tmp/apt-keys.tgz http://$REPO/$VERSION/install/apt-keys.tgz
    ;;
  usb|cdrom)
    cp /media/$MEDIA/install/README                           /root/README
    cp /media/$MEDIA/install/install-server.sh                /opt/example/install/install-server.sh
    cp /media/$MEDIA/install/apt-keys.tgz                     /tmp/apt-keys.tgz
    ;;
esac
chmod 755 /opt/example/install/install-server.sh
chown -R example:example /opt/example

# clean up
update-rc.d -f firstboot remove
rm /etc/init.d/firstboot
rm /root/firstboot*.sh
rm -rf /root/nohup.out
date

# fix apt-get missing pubkeys
cd /tmp
tar xzvf apt-keys.tgz 
apt-key add apt-key-2847.asc 
apt-key add apt-key-A372.asc 
rm apt-key*

/usr/bin/apt-get update -y -qq

# set kernel to 3.2.0-58
if [ `uname -r` != "3.2.0-58-generic" ]; then
  apt-get install -y linux-image-3.2.0-58-generic linux-headers-3.2.0-58-generic --force-yes
  apt-mark hold linux-image-3.2.0-58-generic linux-headers-3.2.0-58-generic
  update-initramfs -u
  /sbin/init 6
elif [ `uname -r` == "3.2.0-58-generic" ]; then
  apt-mark hold linux-image-3.2.0-58-generic linux-headers-3.2.0-58-generic
fi
exit 0