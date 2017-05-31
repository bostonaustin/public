#!/bin/bash

if [[ $AWS_ACCESS_KEY_ID == "" ]]; then
    echo "The Environment Variable 'AWS_ACCESS_KEY_ID' must be set"
    exit 1
fi

if [[ $AWS_SECRET_ACCESS_KEY == "" ]]; then
    echo "The Environment Variable 'AWS_SECRET_ACCESS_KEY' must be set"
    exit 1
fi

PS3="Which Environment To Build In? "
options=("Staging - Ubuntu 14.04" "Staging - Ubuntu 16.04" "Prod - Ubuntu 14.04" "Prod - Ubuntu 16.04" )
select opt in "${options[@]}"; do
    case "$REPLY" in
        1 ) region="ami-1824620f"
        ubuntu="Ubuntu-14.04"
        break
        ;;

        2 ) region="ami-34377023"
        ubuntu="Ubuntu-16.04"
        break
        ;;

        3 ) region="ami-540c4d43"
        ubuntu="Ubuntu-14.04"
        break
        ;;

        4 ) region="ami-4c15545b"
        ubuntu="Ubuntu-16.04"
        break
        ;;
    esac
done

packer build \
    -var "aws_access_key=$AWS_ACCESS_KEY_ID" \
    -var "aws_secret_key=$AWS_SECRET_ACCESS_KEY" \
    -var "ami=$region" \
    -var "ubuntu=$ubuntu" \
    build_host.json
