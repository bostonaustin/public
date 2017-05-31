#!/bin/bash
# setup and configure logrotate for mongo DB

# log location (change as necessary)
mongodb_log="/etc/logrotate.d/mongodb"

# ensure logrotate is installed on server
type logrotate >/dev/null 2>&1 || apt-get -y -qq install logrotate

# check to see if mongoDB logrotate config file exists and create if missing
if [ ! -f "${mongodb_log}" ]; then
  cat > /etc/logrotate.d/mongodb <<EOF
/var/log/mongodb/*.log {
daily
rotate 7
compress
dateext
missingok
notifempty
sharedscripts
copytruncate
}
EOF
  echo "restarting the logrotate service to apply changes ... "
  service logrotate restart
else
  echo "[ERROR] the file ${mongodb_log} exists already, please remove manually and re-run ${basename}"
  exit "2"
fi

echo ""
echo "[PASSED] a MongoDB logrotate entry has been added successfully for this server"
exit "0"
