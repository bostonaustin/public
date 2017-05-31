Ansible playbooks
-----------------

Folder contents:
* playbook to setup an AWS webserver running PetClinic application with Maven, Selenium and Spring 
* dynamic inventory using standard ec2.py and ec2.ini
* vagrant configuration files for testing locally in a sandbox envirnoment

AWS CLI command basics:
  ~~~
  $ aws ec2 describe-instances --output json | grep InstanceId
  $ ansible-playbook -i inv.prod src/util_ec2.yml -vvv
  $ ansible-playbook -i hosts.vagrant launch-instance.yml -vv
  $ aws ec2 terminate-instances --instance-ids <i-xxxxx i-xxxxx> --dry-run
  ~~~


Ansible notes:

1. set your shell ENV to skillseval keys
  ~~~
  export ANSIBLE_HOME=/media/psf/Home/Dropbox/austin-playbooks/
  export ANSIBLE_HOSTS=/media/psf/Home/Dropbox/austin-playbooks/ec2.py
  export EC2_INI_PATH=/media/psf/Home/Dropbox/austin-playbooks/ec2.ini
  export AWS_ACCESS_KEY_ID=ExAmPleC7VEW5D7HExAmPle
  export AWS_SECRET_ACCESS_KEY=ExAmPleMpS6w8G4jyQpxEsJ6t3lVExAmPle
  ~~~

2. setup ssh to use the correct pem file for connecting to AWS instance
  ~~~
  ssh-add -l
  eval \$(ssh-agent); ssh-add /root/.ssh/kp_se_eval.pem; ssh-add /media/psf/Home/Dropbox/austin-playbooks/vagrant/files/ubuntu_vagrant; ssh-add -l
  ~~~

3. test the ssh configuration
  ~~~
  ssh -i ~/.ssh/path_to_ssh_keyfile.pem ubuntu@<ec2.public.IP>

  might require other default user 'ec2-user'
  ~~~