# start-up a vagrant environment using init script
#
# usage:
# $ devenv up               # to download the virtual machine image and start it
# $ devenv start            # kicks off the “devenv-inner.sh start” command
# $ devenv update           # pulls the latest environment code from git and updates Docker images in VM

SCRIPT_HOME="$( cd "$( dirname "$0" )" && pwd )"
cd $SCRIPT_HOME/..

case "$1" in
       ssh)
               vagrant ssh
               ;;
       up)
               vagrant up
               ;;
       update)
               git pull
               vagrant ssh -c "sudo /vagrant/bin/devenv-inner.sh update"
               ;;
       *)
               vagrant ssh -c "sudo /vagrant/bin/devenv-inner.sh $1"
               ;;
esac