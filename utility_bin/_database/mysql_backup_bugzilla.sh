#!/bin/bash
# @descirption:     basic cron to dump mysql bugzilla DB into local .BACKUPS folder

NOW=$(/bin/date +%Y%m%d%H%M%S)

# use this line below, if the DB requires a password
# /usr/bin/mysqldump -h bugzilla_host -u bugzilla_user -pbugzilla_pasword DB_name > bugzilla-backup-${NOW}.sql 2> /tmp/mysqldump.out

# dump the DB_name into /root/.BACKUPS
/usr/bin/mysqldump -h bugzilla_host DB_name > /root/.BACKUPS/bugzilla/bugzilla-backup-${NOW}.sql 2> /tmp/mysqldump.out

# check last command exited cleanly before gzip and remove backups older than 30days
# send email if last command failed
if [[ $? -ne 0 ]] ; then
  cat /tmp/mysqldump.out | mailx -s "Bugzilla backup failed" root@localhost
  exit 1
else
  /bin/gzip -9 /root/.BACKUPS/bugzilla/bugzilla-backup-${NOW}.sql
  find /root/.BACKUPS/bugzilla/ -type f -name "bugzilla-backup*" -mtime +30 -delete
  exit 0
fi


