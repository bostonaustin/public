austin-playbooks
----------------

Create a standalone AWS ec2 instance running nginx, maven, spring and petclinic application

1. Pre-requisites for Ansible Control Station (i.e. your laptop or build-host):
  ~~~
  - root user access/privileges `$ sudo -i` or `$ su`
  - ansible version >= 2.0.2.0
  - vagrant >= 1.9
  - virtualbox >= 5.0
  - python version >= 2.6
  - python-pip version >= 1.5
  - boto version >= 2.4
  - awscli version >= 1.2
  ~~~

2. Un-zip austin-playbook.zip into /root/ directory ~/

3. Run `~/austin-playbooks/preinstall.sh` to configure localhost for running ansible-playbooks

4. Setup the Ansible Control Station environmental variables for AWS user account
  - ensure private `kp_se_eval.pem` is in `~/.ssh/` with 0600 perms
  - Two options, either edit `~/.aws/config` to contain:
    ~~~
    [default]
    region=us-east-1
    output=text
    aws_secret_access_key = loNgEr_eXamPle_AwS_aCCeSs_kEy_iD
    aws_access_key_id = sHoRteR_eXamPLe_sECreT
    ~~~

  - Or run ` # aws configure ` to verify settings or manually add the key/secret

5. Ensure 'ssh-agent' is running with `ssh-add -l` and that the necessary keys are loaded

### To verify the variables are set, run this:
  ~~~
  # env | grep AWS; env | grep ec2
  ~~~

### Set envirnoment varibles for the AWS account: ###
  ~~~
  export AWS_ACCESS_KEY_ID = EXAMPLE_AWS_ACCESS_KEY
  export AWS_SECRET_ACCESS_KEY = EXAMPLE_AWS_SECRET_SHOULD_BE_THE_LONGER_VALUE
  export ANSIBLE_HOSTS=/root/austin-playbooks/install-app-host/ec2.py
  export EC2_INI_PATH=/root/austin-playbooks/install-app-host/ec2.ini
  ~~~

### INSTALL -- Run playbooks from ~/austin-playbooks ###
  * `ansible-playbook launch-instance.yml`
  * `ansible-playbook webservers.yml`

### Clean-up ###
1. Check for a detailed list of all "running" instances:
  ~~~
  aws ec2 describe-instances --output text | grep -B14 running
  ~~~

2. Check for any instances in AWS:
  ~~~
  aws ec2 describe-instances --output json | grep InstanceId

  expected output -                    "InstanceId": "i-example3fc2b3ecfa",
  ~~~

3. Terminate instances to remove them from service:
  ~~~
  aws ec2 terminate-instances --instance-ids i-example3fc2b3ecfa
  ~~~