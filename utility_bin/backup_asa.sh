#!/bin/sh
# grab a backup of Cisco ASA configuration and save to /etc/asa-backup/config

set -e

wget -q -O /etc/asa-backup/config --user=admin --password=ASA_SECURE_PASSWORD --no-check-certificate https://10.10.10.1:8443/admin/exec/show%20running-config/show%20running-config%20asdm
