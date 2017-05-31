#!/bin/sh
# @description:     postinstall.sh preps firstboot script to run cmds and updates
#                   this gets run during CD or ISO after the OS is finished installing
#                   pulls the management server template to configure the server for monitoring
# @author:          Austin Matthews

# grab firstboot script
/usr/bin/curl -o /root/firstboot-mgmt.sh http://example.com/install/firstboot-mgmt.sh
chmod +x /root/firstboot-mgmt.sh

# create a service that will run firstboot script upon boot
cat > /etc/init.d/firstboot <<EOF
### BEGIN INIT INFO
# Provides:        firstboot
# Required-Start:  $networking
# Required-Stop:   $networking
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: A script that runs once to add a firstboot configuration
# Description: A script that runs once to add a firstboot configuration
### END INIT INFO

cd /root; /usr/bin/nohup sh -x /root/firstboot-mgmt.sh &
EOF

# install the firstboot service
chmod +x /etc/init.d/firstboot
update-rc.d firstboot defaults

echo "finished postinstall-mgmt ..."