# @description:   puppet module for loading custom set of Python modules using pip
#                 comment-out content line and enable source to use remote file settings
# @author:        Austin Matthews

class pip_reqs {

  file { "/requirements.txt":
      ensure => file,
      #source => 'puppet:///modules/pip_reqs/files/requirements.txt',
      content => "
# puppet controlled file -- DO NOT EDIT --
#
# Note, there's another file - testing-requirements.txt - with libraries only required for testing
#
# -i option does not work within requirements.txt, use this syntax to run manually on the command line:
#
# pip install -i http://ftp.example.com/pip -r /opt/example/requirements.txt

WebOb==1.2.3
Routes==1.13
zc-zookeeper-static==3.4.4
kazoo==1.2.1
Jinja2==2.6
python-magic==0.4.3
eventlet==0.9.16
python-ldap==2.4.10
lxml==3.1beta1
Flask==0.9
websocket==0.2.1
Cython==0.19.2
gevent==1.0
gevent-socketio==0.3.6
gevent-websocket==0.3.6
redis==2.7.2
hiredis==0.1.1
kairos==0.1.5
cql==1.4.1
py-rrdtool==1.0b1
gipc==0.4.0
setproctitle==1.0.1
psutil==0.7.1
ws4py==0.3.0-beta
wsgiref==0.1.2
python-logstash==0.1.3
pyzmq==13.1.0
elasticsearch==0.4.3
requests==2.1.0
thrift==0.9.1
pycrypto==2.6.1
zope.interface==4.0.5
"
  }

  exec { "pip install requirements":
    command => '/usr/bin/pip install -r /requirements.txt',
    require => Package['python-pip'],
  }
  
}
