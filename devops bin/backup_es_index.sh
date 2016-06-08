#! /bin/bash
# @date:            24dec14
# @version:         1.5.1
# @name:            backup_es_index
# @description:     Rotate and archive Elasticsearch index and cron should run at midnight daily
# 					Maintains only 8 indicies (1 week) of logstash logs
# 					Removes the oldest one (as well as any 1970s-era log indices, as these are a product of timestamp fail).
# 					ES would rather delete everything than nothing...
# @indices location:
# 					/var/lib/elasticsearch/<server-vip>/nodes/0/indices
# 					/data/elasticsearch/<server-vip>/nodes/0/indices
# @retention:       Save the index for 30 days
# @debug mode:		change to 'set -x -v' for debug
#set -x

# @variable
SITE_PREFIX=(`grep -m 1 "SITE_PREFIX" /opt/example/conf/host.properties  | awk -F "=" '{print $2}' `)
SERVER_VIPNAME=(`grep ${SITE_PREFIX}MGMT_VIPNAME /opt/example/conf/site.properties | grep -v '^#' | awk -F "=" '{print $2}'`)
TODAY=`date +"%Y.%m.%d"`
INDEXNAME="logstash-$TODAY"                                               # this had better match the index name in ES
INDEXDIR="/data/elasticsearch/$SERVER_VIPNAME/nodes/0/indices"
BACKUPDIR="/data/elasticsearch/backups"
logFile=/var/log/backup_es_index${TODAY}.log

timeStamp() {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# run only on active server
if [ ! -d $INDEXDIR ]; then
  echo "$(timeStamp) [ERROR] not being run on active server, exiting ..."
  exit 0
fi
exec &>>${logFile}
echo "$(timeStamp) Started Elasticsearch log rotate"
# delete any 1970 indices
TIMESTAMPFAIL=`curl -s localhost:9200/_status?pretty=true |grep index |grep log |sort |uniq |awk -F\" '{print $4}' |grep 1970 |wc -l`
if [ -n $TIMESTAMPFAIL ]; then
  curl -s localhost:9200/_status?pretty=true |grep index |grep log |sort |uniq |awk -F\" '{print $4}' |grep 1970 | while read line; do
    echo "$(timeStamp) Indices with corrupt timestamps found; removing"
    echo "$(timeStamp) Deleting index $line: "
    curl -s -XDELETE http://localhost:9200/$line/
    echo "$(timeStamp) DONE!"
  done
fi

# Get list of indices
INDEXCOUNT=`curl -s localhost:9200/_status?pretty=true |grep index |grep log |sort |uniq |awk -F\" '{print $4}' |wc -l`
if [ $INDEXCOUNT -lt "9" ]
	then
		echo "$(timeStamp) Less than 8 indices, exiting ..."
		exit 0
	else
		echo "$(timeStamp) More than 8 indices, archiving"
		OLDESTLOG=`curl -s localhost:9200/_status?pretty=true |grep index |grep log |sort |uniq |awk -F\" '{print $4}' |head -n1`
		echo "$(timeStamp) Deleting oldest index, $OLDESTLOG: "
		curl -s -XDELETE http://localhost:9200/$OLDESTLOG/
		echo "$(timeStamp) DONE!"
fi

# create mapping file with index settings.  this metadata is required by ES to use index file data
echo "$(timeStamp) Backing up metadata... "
curl -XGET -o /tmp/mapping "http://localhost:9200/$INDEXNAME/_mapping?pretty=true" &> /dev/null
cat /tmp/mapping > /tmp/mappost
echo "$(timeStamp) DONE!"

# tar up our data files.  they are huge, so lets be nice
echo "$(timeStamp) Backing up data files (this may take some time)... "
mkdir -p $BACKUPDIR
cd $INDEXDIR
nice -n 19 tar czf $BACKUPDIR/$INDEXNAME.tar.gz $INDEXNAME
echo "$(timeStamp) DONE!"

# time to create our restore script! scripts creating scripts, that's maddness :)
echo "$(timeStamp) Creating restore script... "
cat << EOF >> $BACKUPDIR/$INDEXNAME-restore.sh
#!/bin/bash
# This requires an $INDEXNAME.tar.gz to restore it into ElasticSearch.
#
# **NOTE**  The index being restored can NOT exist in ElasticSearch already.
#
# If it does exist, corruption will occur during restore process by duplicating records.
#
# DELETE the orginal index from ElasticSearch, BEFORE trying to restore data.

# create index and mapping
echo -n "Creating index and mappings ... "
curl -XPUT 'http://localhost:9200/$INDEXNAME/' -d '`cat /tmp/mappost`' > /dev/null 2>&1

# extract our data files into place
echo -n "Restoring index (this may take a while)... "
cd $INDEXDIR
tar xzf $BACKUPDIR/$INDEXNAME.tar.gz
echo "DONE!"

# restart ES to allow it to open the new dir and file data
echo -n "Restarting Elasticsearch ... "
/etc/init.d/elasticsearch restart
echo "DONE!"
EOF
echo "$(timeStamp) DONE!" # restore script done

# cleanup tmp files and old files
rm /tmp/mappost
rm /tmp/mapping
find /var/log/elasticsearch/ -mtime +90 -exec rm {} \;
find /data/elasticsearch/backups -mtime +30 -exec rm {} \;
exit 0