[cassandra_backup]
- tar up a keyspace and save to 2 seperate remote RAID sets for Disaster Recovery
- save daily snapshot, commitlog log, and logs for 7 days and sunday backup for 4 weeks


[cassandra_repair]
- repair data on a replica by syncing consistentcy with data on other nodes


[cassandra_snapshot]
- grab a snapshot of DB keyspace


[mysql_backup_db]
- dump the DB_name into /root/.BACKUPS
- ensure mysqldump command exited cleanly before gzip and remove backups older than 30days
- send notification email if operation fails
