#!/bin/bash
# run jenkins post-build tests and generate reports

# setup vitural env if available or setup local PYTHONPATH to WORKSPACE
export PATH=$PATH:/usr/local/bin:/usr/local/share/python
cd $WORKSPACE
if hash virtualenv 2>/dev/null; then
  virtualenv vsg
  export PATH=$WORKSPACE/vsg/bin:$PATH
  . vsg/bin/activate
  export PATH=$WORKSPACE/vsg/bin:$PATH:/usr/local/bin:/usr/local/share/python
  pip install -i http://ftp.example.com/pip -r $WORKSPACE/example/requirements.txt --upgrade
  BRANCH=`echo ${GIT_BRANCH} | cut -d "/" -f 2`
  SERVER="jenkins-server"
  CONNECTION_TIMEOUT_MS=30000
else
  BRANCH="local"
  SERVER="localhost"
  CONNECTION_TIMEOUT_MS=5000
fi
export PYTHONPATH=$WORKSPACE/example
cd $WORKSPACE/example

# underscores not permitted due to _test keyspace names and period ('.') not allowed by cassandra
KEYSPACE="`echo "${BRANCH}" | sed -e s/[-_]//g -e s/\\\\./dot/g`"
echo "$KEYSPACE@jenkins-server" > /opt/example/.examplenv
python common/create_syscfg.py -cassandraServer $SERVER -consoleApiServer $SERVER -externalApiServer $SERVER -zooKeeperServer $SERVER -connectionTimeoutMS $CONNECTION_TIMEOUT_MS -examplenv ${KEYSPACE} -write

# set build tag
cd $WORKSPACE/example
echo "Build Tag:$BUILD_TAG"
echo $BUILD_NUMBER > current_build_number

# coverage is recorded in a .coverage file by nose which appends coverage from each project
# once all projects are run, use coverage directly to produce the combined report
set +e

# get list of python projects (ie example subfolders) -- excluding those that definitely don't have tests
cd $WORKSPACE/example
PROJECTS=${@:1}
if [ "$PROJECTS" == "" ]; then
  PROJECTS=`ls -d1 -- */ | grep -E -e '^(bin)|(conf)|(doc)|(documentation)|(derisking)|(misc)|(puppet)|(specifications)/$' -v`
fi
cd $WORKSPACE
OUTPUT_FOLDER=$WORKSPACE/output
mkdir $OUTPUT_FOLDER || rm -rf $OUTPUT_FOLDER/*
rm .coverage
rm `find . -name *.pyc`

# drop the keyspace
python cassandra/create_keyspace.py delete ${KEYSPACE}_test -s $SERVER
echo "running tests for $PROJECTS ..."
for project in $PROJECTS
do
  project=${project%/}
  PYFILES=`find example/$project -name *.py | wc -l`
  if [ $PYFILES -eq 0 ]; then
    echo "Skipping non-python folder $project"
  else
    NOSE_COVERAGE="--with-coverage"
    NOSE_DEBUG="--debug=DEFAULT --nologcapture"
    NOSE_XUNIT="--with-xunit --xunit-file=$OUTPUT_FOLDER/nosetests-$project.xml"
    NOSE_ARGS="-vs $NOSE_COVERAGE $NOSE_DEBUG $NOSE_XUNIT"
    nosetests example/$project $NOSE_ARGS > $OUTPUT_FOLDER/nosetests-$project.log
  fi
done

echo "creating coverage reports ..."
coverage xml --include=example/* -o $OUTPUT_FOLDER/coverage.xml
coverage html --include=example/* -d $OUTPUT_FOLDER/coverage

echo "running phantom js tests ..."
cd $WORKSPACE/operator_console/web-content/public/js/tests
`which phantomjs` js/qunit-runner.js test.html --xunitOnly > $OUTPUT_FOLDER/jstests.xml
set -e

if hash deactivate 2>/dev/null; then
  deactivate
  exit 0
fi