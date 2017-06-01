code samples and reference materials
------------------------------------

   [ansible](https://github.com/bostonaustin/public/blob/master/ansible/)
   * a single ec2 webserver running petclinic with Maven, NGINX and Spring

   [bootstrap](https://github.com/bostonaustin/public/blob/master/bootstrap/)
   * AWS user_data for a replace-able WordPress blog with S3 sync
   * AWS CloudFormation template for a self-healing, multi-AZ WP Blog
   * postinstall + firstboot init.d scripts to run commands w/o using user_data

   [puppet](https://github.com/bostonaustin/public/tree/master/puppet)
   * module to install 3rd party software repos
   * module to add ssh w/o passwords and updating python modules

   [python](https://github.com/bostonaustin/public/tree/master/python)
   * last production script I wrote -- checking SSL expiration dates
   * second to last production script -- creates an AWS RDS snapshot
   * reference syntax basics with tic-tac-toe, blackjack and geek translator dictionary

   [utility_bin](https://github.com/bostonaustin/public/blob/master/utility_bin/)
   * binaries for everyday usage, automating jobs and troubleshooting purposes
   * includes DevOps automation tasks (ssh-no-password, raid, rsync, sed/awk)

       `utility bin folders`

       [database](https://github.com/bostonaustin/public/blob/master/utility_bin/_database/)
       ~~~
       * verify a cassandra keyspace user
       * archive a keyspace
       * backup a mysql database
       ~~~
       [monitoring](https://github.com/bostonaustin/public/tree/master/utility_bin/_monitoring)
       ~~~
       * perl scripts for nagios service checks
       * PHP based PHP4nagios graph templates
       * NRPE client configuration file
       ~~~
       [tests](https://github.com/bostonaustin/public/tree/master/utility_bin/_tests)
       ~~~
       * jenkins build post-commit test
       * POST/DELETE/ 1MB objects via REST API
       ~~~
       [virtualization](https://github.com/bostonaustin/public/tree/master/utility_bin/_virtualization)
       ~~~
       * Dockerfile sample from an icinga container
       * Vagrantfile for a 4-node VM cluster
       ~~~