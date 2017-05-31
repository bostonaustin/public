#!/bin/bash
# create a client_gateway installation with install.sh for *NIX

ver="1.0.0"
branches="beta develop 1.0.0"                 # set static version numbers
count="cat /root/.count"                      # pull count from git commit ID
status_log_folder=/var/log/example
statFile=${status_log_folder}/status_deb_mkr.log
logFile=${status_log_folder}/client_portal_mkr.log
utility_functions=/root/bin/functions
sysArch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

# load utility functions
if [ -f ${utility_functions} ]; then
  source ${utility_functions}
else
  echo "[FATAL] failed to import function library - check ${utility_functions} "; exit 2
fi

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
# load required packages for python and example client Portal

alias sys_procs='python /opt/example/common/utilities/sys_procs.py'
export PYTHONPATH=/opt/example
echo "alias sys_procs='python /opt/example/common/utilities/sys_procs.py'" >> ~/.bashrc
echo "export PYTHONPATH=/opt/example" >> ~/.bashrc

create_dir() 
{
  path="\$1"
  if [ ! -d "\$path" ]; then
    echo "[OK] Creating directory \$path "
    mkdir -p "\$path" || error 2 "Failed to create directory \$path "
  else
    echo "[WARN] \$path already exists "
  fi
}

detect_python() 
{
  if hash python 2>/dev/null; then
    echo "python detected"
    pyhtonInstalled="Y"
  else
    echo "[FATAL] Python 2.7 environment not detected - please double-check "
    pythonInstalled="N"
  fi
}

check_root() 
{
  if [ "\$USER" != "root" ]; then
    echo "*** Install should run by root user ***"
    exit
  fi
}

check_root
create_dir /opt
create_dir /opt/example
create_dir /opt/example/client_portal
create_dir /data
create_dir /data/example

# install python based on OS
detect_python
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

# post a copy to apache download folder
cp /tmp/clientPortal-${ver}.tgz /var/www/${ver}/
logsOff