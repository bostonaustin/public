#!/bin/bash
# @date:            30jan2015
# @description:     create a client_portal tarball with install.sh for *nix*
# @requires:        run on mgmt1
# @debug:           enable DEBUG mode with 'set -x -v'
#set -x -v

# @variables:
ver="1.0.0"
branches="beta develop 1.0.0"                 # set static version numbers
count="cat /root/.count"                      # pull count from git commit ID
sLogDir=/var/log/example
statFile=${sLogDir}/status_deb_mkr.log
logFile=${sLogDir}/client_portal_mkr.log
sLib=/root/bin/functions
sysArch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

# @functions:
if [ -f ${sLib} ]; then
  source ${sLib}
else
  echo "[FATAL] failed to import function library - check ${sLib} "; exit 2
fi

# @start:
pre_flight
logs_on

logTee "START client portal maker "
cd /opt/example
/usr/bin/git checkout beta
/usr/bin/git pull origin beta
cd /tmp
cp /var/www/1.0.0/install/get-pip.py /opt/example/client_portal/get-pip.py

logTee "  generate /opt/example/client_portal/reqs.txt ... "
cat > /opt/example/client_portal/reqs.txt <<EOF
gevent==1.0
gipc==0.4.0
Routes==1.13
Jinja2==2.6
WebOb==1.2.3
pycrypto==2.6.1
setproctitle==1.0.1
ws4py==0.3.0-beta
eventlet==0.9.16
python-logstash==0.1.3
EOF

logTee "  add an install.sh to load the missing pacakages ... "
cat > /opt/example/client_portal/install.sh <<EOF
#!/bin/bash
# @date:            30jan2015
# @name:            install.sh
# @description:     load required packages for python and example client Portal

# @variables:
alias sys_procs='python /opt/example/common/utilities/sys_procs.py'
export PYTHONPATH=/opt/example
echo "alias sys_procs='python /opt/example/common/utilities/sys_procs.py'" >> ~/.bashrc
echo "export PYTHONPATH=/opt/example" >> ~/.bashrc

# @functions:
create_dir() {
  path="\$1"
  if [ ! -d "\$path" ]; then
    echo "[OK] Creating directory \$path "
    mkdir -p "\$path" || error 2 "Failed to create directory \$path "
  else
    echo "[WARN] \$path already exists "
  fi
}

detectPython() {
  if hash python 2>/dev/null; then
    echo "python detected"
    pyhtonInstalled="Y"
  else
    echo "[FATAL] Python 2.7 environment not detected - please double-check "
    pythonInstalled="N"
  fi
}

checkRoot() {
  if [ "\$USER" != "root" ]; then
    echo "*** Install should run by root user ***"
    exit
  fi
}

# @start:
checkRoot
create_dir /opt
create_dir /opt/example
create_dir /opt/example/client_portal
create_dir /data
create_dir /data/example

# install python based on OS
detectPython
if [ "\$pythonInstalled" = "N" ]; then
  ARCH=\$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
  if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=\$DISTRIB_ID
    REL=\$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS=Debian
    REL=\$(cat /etc/debian_version)
    apt-get update -y -qq
    apt-get install -y python2.7 python-software-properties python-setuptools \
    make gcc g++ libevent-dev libldap2-dev libsasl2-dev librrd-dev \
    libxslt1-dev libxml2-dev python2.7-dev
  elif [ -f /etc/redhat-release ]; then
    yum -y update
    yum -y install python
    yum groupinstall -y 'development tools'
  elif [ -f /etc/SuSE-release ]; then
    . /etc/SuSE-release
    OS=SuSE
    REL=\$VERSION
  else
    OS=\$(uname -s)
    REL=\$(uname -r)
  fi
fi

# install pip
python /opt/example/client_portal/get-pip.py
/bin/pip install -i http://ftp.example.com/pip -r /opt/example/client_portal/reqs.txt --upgrade

# fix local perms
if [ -d /opt/example ]; then
  echo "checking /opt/example folder perms and ownership ... "
  chmod -R 700 /opt/example
  find /opt/example -type d -exec chmod 755 {} \;
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

# source changes to .bashrc
. ~/.bashrc
cd
echo "[SUCCESS] client portal install.sh completed "
EOF

# make executable and create a tarball
chmod +x /opt/example/client_portal/install.sh
logTee "   tar up the required directories ... "
tar czhf /tmp/clientPortal-${ver}.tgz \
 --exclude='c_sharp' --exclude='java_client' --exclude='tests' \
 --exclude='example' --exclude='fixtures' --exclude='*.pyc' --exclude='.DS_Store' \
 /opt/example/client_portal

# post a copy to apache directory
cp /tmp/clientPortal-${ver}.tgz /var/www/${ver}/
logsOff