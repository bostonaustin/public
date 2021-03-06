#!/usr/bin/env bash

# This script is used by vagrant

USERNAME="ubuntu"
PASSWORD="password"

echo "Changing password for: $USERNAME"
sudo echo $USERNAME:$PASSWORD | sudo chpasswd

echo "Writing ssh key"
sudo cat << EOF > /home/ubuntu/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGGd8HHyfdn5TYRMTV7OSvRzs1xJL/SwSuudvUlqfAWQxJ8kE6z2EccZPTjlRDUNnd8iVEAh5SwcQqs4+ZgoJmABH/qqAU9QOq98NCv99J5DeLaDbAbyGwAUBypIl134P2dZlI9UQ6Xsl+il/cG+ASssl9B5wXP03NnNZBjyw/HBjMsiZcFeDRcETTAF6ymK1VP973sPhrZOBFPwfQdCiNVBtU1YTVRm1p5SIJWEKiSkJCPSOCug7EPwtfXNM/sZuKDTTEw8g1HhxU6GMkksXvun/KTVY3vruJj44AfX6p7U5Zo2Yv48OFuP8R94ols2zz9gk/D+tPKXaT3SNUTNPZ ubuntu
EOF
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod 644 /home/ubuntu/.ssh/authorized_keys

cp