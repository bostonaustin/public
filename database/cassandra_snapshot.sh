#!/bin/bash
# @descritpion:     create a snapshot of cassandra keyspace
#                   store the snapshots as tar files on 2 seperate disk RAID arrays
#                   remove old snapshots and archive commitlog
#                   save a week of daily and a year of monthly
#
# @author:          Ausitn Matthews
# @date:            11oct14

now=$(date +%Y%m%d-%H%M)
day=$(date +%d)
KEYSPACE="keyspace_to_snapshot"

echo "Starting to generate a snapshot"
cd /tmp
if [ $day == 01 ]; then
  echo "Generating a monthly snapshot on the first day of the month"
  nodetool -h localhost -p 7199 clearsnapshot KEYSPACE
  nodetool -h localhost -p 7199 snapshot KEYSPACE
  rm `hostname`-cassandra-snapshot*.tar.gz
  tar -zcvf `hostname`-cassandra-snapshot-monthly-$now.tar.gz /data/lib/cassandra/data/KEYSPACE/
  tar -zcvf `hostname`-commitlog-monthly-$now.tar.gz /ssd/lib/cassandra/commitlog/
else
  echo "Generating a daily snapshot"
  nodetool -h localhost -p 7199 clearsnapshot KEYSPACE
  nodetool -h localhost -p 7199 snapshot KEYSPACE
  rm `hostname`-cassandra-snapshot*.tar.gz
  tar -zcvf `hostname`-cassandra-snapshot-daily-$now.tar.gz /data/lib/cassandra/data/KEYSPACE/
  tar -zcvf `hostname`-commitlog-daily-$now.tar.gz /ssd/lib/cassandra/commitlog/
fi

echo "Moving snapshot and deleting old snapshots"
mv /tmp/*cassandra-snapshot* /data/cassandra-snapshots/
mv /tmp/*commitlog* /data/cassandra-snapshots/
find /data/cassandra-snapshots/*daily* -mtime +7 -exec rm {} \;
find /data/cassandra-snapshots/*monthly* -mtime +365 -exec rm {} \;
find /data/cassandra-snapshots/*commitlog* -mtime +365 -exec rm {} \;