#!/bin/bash
# test read/write on container using curl get with 1mb test object

address="10.10.10.12:8080"
container="testContainer"
target="${address}/v1/default/${container}"
auth_key=$(curl -i -k -H 'x-auth-user:admin' -H 'X-Auth-Key:password' ${address}/auth -X GET --silent | grep X-Auth-Token | awk '{print $2}')
f="1mb-test.img"
fName="/root/${f}"

# verify
# DEBUG set -x; echo "$auth_key"; echo "$address"; echo "$container"; echo "$fname"

echo "verify the container $container is $target"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" $target -X GET

echo "verify $target/$f exists in the container $container"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" $target/$f -X GET