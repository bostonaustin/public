#!/bin/bash
# test read/write on container using add/verify via curl with 1mb test object

address="10.10.10.18:8080"
container="testContainer"
target="${address}/${container}"
auth_key=$(curl -i -k -H 'x-auth-user:admin' -H 'X-Auth-Key:password' ${address}/auth -X GET --silent | grep X-Auth-Token | awk '{print $2}')
f="1mb-test.img"
fName="/root/${f}"

# DEBUG mode
#set -x -v; echo "$auth_key"; echo "$address"; echo "$container"; echo "$fname"

echo "attempt to add the container $container"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" $target -X PUT

echo "verify $target exists in the container $container"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" $target -X GET

echo "attempt to put $f into the container $container"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" "$target/$f" -X PUT -T $fName

echo "verify $target/$f exists in the container $container"
curl -i -k -s -S -H "x-auth-user:admin" -H "X-Auth-Key:password" -H "x-auth-Token: $auth_key" $target/$f -X GET

# delete test object
#echo "delete $target/$f from the container $container"
#curl -i -k -H "x-auth-Token: $auth_key" "$target/$f" -X DELETE
