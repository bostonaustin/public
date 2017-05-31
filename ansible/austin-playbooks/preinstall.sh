#!/bin/bash

# Description: Run this script to ensure your local Ansible Control Station is ready
#
# To reset and re-run this script from scratch to reset all settings:
#     a. # rm ~/.preinstall_has_run_breadcrumb
#     b. re-run ./preinstall.sh

# variables
AWS_CONFIG=~/.aws/config
SSH_ENV=$HOME/.ssh/environment
AWS_KEY=/root/.ssh/kp_se_eval.pem
VAGRANT_KEY=/media/psf/Home/Dropbox/austin-playbooks/install-app-host/vagrant/files/ubuntu_vagrant

# functions
checkDir()         {
  if [ ! -d "$1" ]; then
    echo "[pre-flight] creating directory $1"; mkdir -p "$1" || echo "Failed to create directory $1"
  else
    echo "[pre-flight] directory already exists -- $1"
  fi
}

# ensure this script is being run as root
if [ "$(whoami)" != "root" ]; then
  echo "[ERROR] pre-flight script must be run as root, please try again with sudo?"; exit 1
else
  echo "[pre-flight] starting to check localhost pre-reqs ..."
fi

# add the PPA for the latest version of ansible locally on the control station
if [ ! -f ~/.preinstall_has_run_breadcrumb ]; then
  apt-add-repository -y ppa:ansible/ansible
  apt-get -y update
  apt-get -y install ansible
  apt-get -y install aptitude
  apt-get -y install software-properties-common
  apt-get -y install python-setuptools
  apt-get -y install python-dev
  apt-get -y install g++
  apt-get -y install python2.7-dev
  apt-get -y install sshpass
  apt-get -y install autoconf
  apt-get -y install python-pip
  apt-get -y install libssl-dev
  apt-get -y install libffi-dev
  apt-get -y install build-essentials
  apt-get autoremove
  pip install ansible
  pip install boto
  pip install Jinja
  pip install six
  pip install PyYAML
  pip install httplib2
  pip install paramiko
fi
echo "[pre-flight] apt-get updates ran successfully"

# check if AWS CLI is install already
command -v aws >/dev/null 2>&1 || { echo >&2 "[WARN] AWS CLI not installed - attempting to install via apt-get."; apt-get -y install awscli; }
command -v aws >/dev/null 2>&1 || { echo >&2 "[ERROR] AWS CLI package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] AWS CLI installed properly"

# check if Ansible is install already
command -v ansible >/dev/null 2>&1 || { echo >&2 "[WARN] AWS CLI not installed - attempting to install via apt-get."; apt-get -y install ansible; }
command -v ansible >/dev/null 2>&1 || { echo >&2 "[ERROR] AWS CLI package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] Ansible installed properly"

# check if python3 is install already
command -v python3 --version >/dev/null 2>&1 || { echo >&2 "[WARN] python3 not installed - attempting to install via apt-get."; apt-get -y install python3; }
command -v python3 --version >/dev/null 2>&1 || { echo >&2 "[ERROR] python3 package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] python3 installed properly"

# add .pem key to ssh-agent
echo "[pre-flight] checking SSH remote key is imported to ssh-agent ..."
checkDir ~/.ssh
if [ ! -f ${AWS_KEY} ]; then
  echo "[ERROR] SSH remote host key missing, double-check ~/.ssh/ for *.pem file"; exit 1
else
  echo "[pre-flight] SSH remote key is detected"
fi

# set ssh-agent keys
if [ ! -f ~/.preinstall_has_run_breadcrumb ]; then
  # add ssh-agent to bash_profile to enable at boot
  if [ -f ~/.bash_profile ]; then
    cp ~/.bash_profile ~/.bash_profile.preinstall_backup
# TODO -- remove hardcoded env vars from .bash_profile after testing for security reasons
cat > ~/.bash_profile <<EOF
# hard code skillseval keys
export ANSIBLE_HOME=/media/psf/Home/Dropbox/austin-playbooks/
export ANSIBLE_HOSTS=/media/psf/Home/Dropbox/austin-playbooks/ec2.py
export EC2_INI_PATH=/media/psf/Home/Dropbox/austin-playbooks/ec2.ini

export AWS_ACCESS_KEY_ID=AKIAJOXCC7VEW5D7HWXQ
export AWS_SECRET_ACCESS_KEY=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

ssh-add -l
if [ $? == 0 ]; then
    echo
    echo "[pre-flight] manually run this to setup ssh-agent:"
    echo " "
    echo -e 'eval \$(ssh-agent); ssh-add /root/.ssh/kp_se_eval.pem; ssh-add /media/psf/Home/Dropbox/austin-playbooks/vagrant/files/ubuntu_vagrant; ssh-add -l '
    echo " "
else
  echo "ssh-agent is running -- double-check the keys loaded with # ssh-add -l"
fi
EOF
  fi
fi

# check for AWS keys in env
echo "[pre-flight] checking for AWS config file ..."
checkDir ~/.aws

if [ ! -f ${AWS_CONFIG} ]; then
  # TODO -- REMOVE after testing for security
cat > ${AWS_CONFIG} <<EOC
[default]
output = text
region = us-east-1
aws_access_key_id = AKIAJOXCC7VEW5D7HWXQ
aws_secret_access_key = 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
EOC
  chmod 600 ${AWS_CONFIG}
  if [[ ${ANSIBLE_HOSTS} == "" ]]; then
    echo "export ANSIBLE_HOSTS=/root/austin-playbooks/ec2.py" >> ~/.bash_profile
  fi
  if [[ ${EC2_INI_PATH} == "" ]]; then
    echo "export EC2_INI_PATH=/root/austin-playbooks/ec2.ini" >> ~/.bash_profile
  fi
  if [[ ${AWS_DEFAULT_PROFILE} == "" ]]; then
    echo "export AWS_DEFAULT_PROFILE=default" >> ~/.bash_profile
  fi
  # TODO -- un-comment out 'continue' to by-pass checking for AWS env key variables
  #continue
  # AWS ENV VARS ARE BEING IGNORED by 'aws configure' -- config file works better
  if [[ ${AWS_ACCESS_KEY_ID} == "" ]]; then
    echo " "
    echo "[ERROR] missing AWS_ACCESS_KEY_ID"
    echo "  Please set the environmental variable for AWS_ACCESS_KEY_ID"
    echo "    i.e. # export AWS_ACCESS_KEY_ID=eXaMpleAccessKeyID"
    echo " "; exit 1
    if [[ ${AWS_SECRET_ACCESS_KEY} == "" ]]; then
      echo " "
      echo "[ERROR] missing AWS_SECRET_ACCESS_KEY"
      echo "  Please set the environmental variable for AWS_SECRET_ACCESS_KEY"
      echo "    i.e. # export AWS_SECRET_ACCESS_KEY_ID=eXamPleAWSsecretKeyisLongerThanTheAccessKey"
      echo " "; exit 1
    fi
    else
      echo " "
      echo "[pre-flight] AWS env vars detected with these values:"
      echo "[debug] using for ACCESS key = $AWS_ACCESS_KEY_ID"
      echo "[debug] using for SECRET key = $AWS_SECRET_ACCESS_KEY"
    fi
else
  echo "[pre-flight] AWS config file detected, run '# aws configure' to verify settings"
fi

# TODO -- REMOVE after testing for security
cat > ~/reset-austin-env-vars.sh <<EOK
#!/bin/bash

# reset the AWS env keys for the skillseval account
export AWS_ACCESS_KEY_ID=AKIAJOXCC7VEW5D7HWXQ
export AWS_SECRET_ACCESS_KEY=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

# set dynamic inventory env vars
export ANSIBLE_HOME=/media/psf/Home/Dropbox/austin-playbooks/
export EC2_INI_PATH=/media/psf/Home/Dropbox/austin-playbooks/ec2.ini
export ANSIBLE_HOSTS=/media/psf/Home/Dropbox/austin-playbooks/ec2.py

ssh-add -l
if [ $? == 0 ]; then
    echo
    echo "manually run this to setup ssh-agent:"
    echo " "
    echo -e ' eval \$(ssh-agent); ssh-add /root/.ssh/kp_se_eval.pem; ssh-add /media/psf/Home/Dropbox/austin-playbooks/vagrant/files/ubuntu_vagrant; ssh-add -l '
    echo " "
else
  echo "ssh-agent is running -- double-check the keys loaded with # ssh-add -l"
fi
EOK
chmod 700 ~/reset-austin-env-vars.sh
#source ~/reset-austin-env-vars.sh

echo "[pre-flight] ~/reset-aws-keys-skilleval.sh has been created "

echo "[pre-flight] run '# ~/reset-austin-env-vars.sh' to reset AWS env variables"

echo "[pre-flight] attempting to start ssh-agent ..."
ssh-add -l
if [ $? == 2 ]; then
  echo "[warning] manually run this to setup ssh-agent for AWS and vagrant keys:"
  echo " "
  echo -e '  eval $(ssh-agent); ssh-add /root/.ssh/kp_se_eval.pem; ssh-add /media/psf/Home/Dropbox/austin-playbooks/vagrant/files/ubuntu_vagrant; ssh-add -l '
else
  echo "[warning] ssh-agent is already running -- double-check the keys loaded with 'ssh-add -l'"
  echo "          manually run this to setup ssh-agent for AWS and vagrant keys:"
  echo " "
  echo -e '          pkill ssh-agent; eval $(ssh-agent); ssh-add /root/.ssh/kp_se_eval.pem; ssh-add /media/psf/Home/Dropbox/austin-playbooks/vagrant/files/ubuntu_vagrant; ssh-add -l '
fi
# success -- drop breadcrumb to avoid extra work on next execution
touch ~/.preinstall_has_run_breadcrumb
echo " "
echo "[pre-flight] preinstall script completed successfully"
echo " "
exit 2