#!/bin/bash
# simple loop to rsync directories in web app farm

app_servers="lab-app01 lab-app02 lab-app03 lab-app04"

if [[ -e /tmp/rsyncprod.tmp ]]
  then
  echo "[ERROR] rsync to $app_servers is already running"
  exit 2
else
  if [ -f /junk.txt ]
  then
    cat /junk.txt > /tmp/rsyncprod.tmp
  fi
  # run a rsync loop
  for app_server in $app_servers
  do
    echo "-----------------------------------------------------------"
    echo "starting rsync to $app_server"
    /usr/bin/rsync -varl --delete --password-file=/etc/rsyncd.secret \
      --exclude-from=/etc/rsyncd.exclude /var/www/apps/website1.com  \
      rshtdocs@${app_server}::website1.com
    /usr/bin/rsync -varl --delete --password-file=/etc/rsyncd.secret \
      --exclude-from=/etc/rsyncd.exclude /var/www/apps/website2.com  \
      rshtdocs@${app_server}::website2.com
    echo "ending rsync to $app_server"
    echo "-----------------------------------------------------------"
    echo ""
  done
  rm -f /tmp/rsyncprod.tmp
fi
exit 0