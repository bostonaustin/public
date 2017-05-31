#!/bin/bash
# @date:                13jan15
# @author:              Austin Matthews
# @name:                add_nis_user
# @description:         Add user to NIS database and update services
# @example:             add_nis_user.sh amatthews
# @debug:               enable DEBUG mode with 'set -x -v'
#set -x -v

# @functions:
sLib="/root/bin/functions"
if [ -f ${sLib} ]; then
  . ${sLib}; logTee "  [OK] imported function library -- ${sLib} "
else
  echo "[FATAL] failed to import function library -- check ${sLib}"; exit 2
fi

# @pre-flight:
checkRoot
logsOn

logTee "Generating random 8-10 chars using symbol/number/cap/lower, no I, l or 1 to avoid confusion of similar characters or quotes"
pass=`/usr/bin/apg -a 1 -n 1 -m 8 -x 10 -M SNCL -E Il1\"`

logTee "Adding user ${uname} with password ${pass}"
/usr/sbin/useradd -m -g Users -G 4,20,24,27,46,100,108,109 -b /home -s /bin/bash -p `mkpasswd ${pass}` "${uname}"
if [[ $? > 0 ]]; then
  logTee "useradd failed to add ${uname} with password ${pass}"; exit 1
fi

logTee "Restarting services for NIS server"
service portmap restart
service ypserv restart
service yppasswdd restart
sleep 10
service ypserv status > /dev/null 2>&1
if [[ $? > 0 ]]; then
  logTee "NIS did not restart"; exit 1
fi

logTee "Updating NIS database ..."
make -C /var/yp

logTee "Send a notification email with password ..."
mailx -s "NIS user account created for ${uname}" ${uname}@example.com << EOF_MAIL

Congrats, you now have a NIS user account.

Use it for accessing the example Lab and QA servers.

    Username = ${uname}

    Password = ${pass}

Example $ ssh ${uname}@lab-db1

To update your NIS password run " $ yppasswd " while connected to a Lab server.

Please send any questions to ops@example.com

EOF_MAIL
exit