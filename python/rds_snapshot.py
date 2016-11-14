#!/usr/bin/env python
# coding:utf-8
__author__ = "Austin Matthews (boston.austin@gmail.com)"

"""
@description:

Script is an automated cron job that creates a manual RDS snapshot

Here are the steps:
        - script will need to use IAM credentials to create a manual RDS snapshot
        - include aws-secure account in RDS clean-ups

example cronjob one-liner:

    $ /tools/linuxx86_64/python-3.3.6-aws/bin/python ./rds_snapshot.py -a aws-secure -i rds-zabbix-test  > ./rds_snapshot.log 2>&1

@requirements:

    AWS IAM keyfile -- /awsoperations/users/{your username}/aws/{AWS account keyfile}

"""


from boto3.session import Session
from datetime import datetime
import argparse
import sys
import os


LOG_LEVEL = 2
NOW = datetime.now()
CONFIG_DATA = dict()
AWS_CRED_PATH = '/awsoperations/users/'
AWS_REGION = 'us-east-1'
AWS_USER_ACCT = os.getlogin()


def log(message, severity):
    """ print to stdout with custom timestamp """
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if LOG_LEVEL >= severity:
        print(" %s %s" %(current_time, message))


def start_aws_client(product_line, instance_name):
    """ start aws client session using IAM keys for environment and open a boto.client object to list all snapshots """
    aws_cred_file = AWS_CRED_PATH + AWS_USER_ACCT + "/aws/" + product_line + ".keyfile"
    aws_region_name = AWS_REGION
    log("  [START] Connecting to RDS Environment ... ", 1)
    log("     -| Product      : %s" %product_line, 1)
    log("     -| Instance Name: %s" %instance_name, 1)
    log("     -| Cred File    : %s" %aws_cred_file, 1)
    log("     -| Region       : %s" %aws_region_name, 1)
    
    with open(aws_cred_file) as ins:
        a_aws_keys = dict()
        lines = filter(None, (line.rstrip() for line in ins))
        for line in lines:
            (aws_key, aws_value) = line.strip().split("=")
            a_aws_keys[aws_key] = aws_value

    session = Session(aws_access_key_id = a_aws_keys["AWS_ACCESS_KEY"], aws_secret_access_key = a_aws_keys["AWS_SECRET_KEY"], region_name = aws_region_name)
    return session


def create_rds_snapshot(p_aws_session, p_instance_name):
    """ generate an RDS snapshot """
    rds = p_aws_session.client('rds')
    SNAPSHOT_ID = p_instance_name + "-" + datetime.now().strftime("%Y-%m-%d-%H-%M")
    INSTANCE_NAME = p_instance_name
    log("  [START] Creating the RDS SnapshotID ... ", 1)
    log("     -| Snapshot     : %s" %SNAPSHOT_ID, 1)
    log("     -| Instance Name: %s" %INSTANCE_NAME, 1)
    log("     -| AWS response : \n ", 1)
    response = rds.create_db_snapshot(
        DBSnapshotIdentifier = SNAPSHOT_ID,
        DBInstanceIdentifier = INSTANCE_NAME,
        # add custom tags to db-snapshot here:
        # Tags=[
        #     {
        #     'Snapshot type': 'manual',
        #     },
        # ]
        )
    print(response)
    print("")
    log("  [COMPLETE] %s finished successfully ... " %__file__, 1)
    sys.exit(1)


def main():
    """ create a manual rds DB snapshot backup """
    parser = argparse.ArgumentParser(description='Create a manual RDS snapshot', usage='%(prog)s')
    parser.add_argument('-a', dest='product_line', help='AWS Product Line or Account Name [i.e. aws-secure | aws-blackops] ')
    parser.add_argument('-i', dest='instance_name', help='AWS Instance/Cluster Name')
    args=parser.parse_args()

    if args.product_line is None:
        parser.print_help()
        sys.exit(1)
    else:
        product_line = args.product_line

    if args.instance_name is None:
        parser.print_help()
        sys.exit(1)
    else:
        instance_name = args.instance_name.lower()

    try:
        aws_session = start_aws_client(product_line, instance_name)
        create_rds_snapshot(aws_session, instance_name)

    except Exception as err:
        print(err)
        log("  [ERROR] %s failed to complete properly -- please try again" %__file__, 1)
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except Exception as err_main:
        print(err_main)