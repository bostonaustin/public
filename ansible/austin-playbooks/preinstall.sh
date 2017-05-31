#!/bin/bash
# ensure your local Ansible Control Station is ready to run playbooks

# Hard-codes to an AWS account with static ssh keys, AWS access / secret keys and ENV PATH(s)

# Reset and re-run this script from scratch:
#     a. # rm ~/.preinstall_has_run_breadcrumb
#     b. re-run ./preinstall.sh

AWS_CONFIG=~/.aws/config
SSH_ENV=$HOME/.ssh/environment
AWS_KEY=/root/.ssh/kp_se_eval.pem
VAGRANT_KEY=/media/psf/Home/Dropbox/austin-playbooks/install-app-host/vagrant/files/ubuntu_vagrant

check_directory()         {
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
apt_packages="ansible aptitude software-properties-common python-setuptools python-dev g++ python2.7-dev sshpass autoconf python-pip libssl-dev libffi-dev build-essentials"
pip_list="ansible boto Jinja six PyYAML httplib2 paramiko"
if [ ! -f ~/.preinstall_has_run_breadcrumb ]; then
  apt-add-repository -y ppa:ansible/ansible
  apt-get -y update
  for apt_package in $apt_packages
  do
    echo "checking for latest software update of ${apt_package}"
    apt-get -y install ${apt_package}
  done
  apt-get autoremove
  for module in $pip_list
  do
    echo "checking for latest pyhton pip of ${pip_module}"
    pip install ${pip_module}
  done
fi
echo "[pre-flight] apt-get updates and pip installs ran successfully"

# check if AWS CLI is installed
command -v aws >/dev/null 2>&1 || { echo >&2 "[WARN] AWS CLI not installed - attempting to install via apt-get."; apt-get -y install awscli; }
command -v aws >/dev/null 2>&1 || { echo >&2 "[ERROR] AWS CLI package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] AWS CLI installed properly"

# check if Ansible is installed
command -v ansible >/dev/null 2>&1 || { echo >&2 "[WARN] AWS CLI not installed - attempting to install via apt-get."; apt-get -y install ansible; }
command -v ansible >/dev/null 2>&1 || { echo >&2 "[ERROR] AWS CLI package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] Ansible installed properly"

# check if python3 is installed
command -v python3 --version >/dev/null 2>&1 || { echo >&2 "[WARN] python3 not installed - attempting to install via apt-get."; apt-get -y install python3; }
command -v python3 --version >/dev/null 2>&1 || { echo >&2 "[ERROR] python3 package not installed, please correct and re-try."; exit 1; }
echo "[pre-flight] python3 installed properly"

# add .pem key to ssh-agent
echo "[pre-flight] checking SSH remote key is imported to ssh-agent ..."
check_directory ~/.ssh
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
check_directory ~/.aws

if [ ! -f ${AWS_CONFIG} ]; then
  # TODO -- REMOVE after testing for security
cat > ${AWS_CONFIG} <<EOC
[default]
output = text
region = us-east-1
aws_access_key_id = AblahKblahIblahDblah7HWXQ
aws_secret_access_key = hblahMjblahqblahdi5w8G4jyQpxEsJ6t3lVP5sM
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
exit