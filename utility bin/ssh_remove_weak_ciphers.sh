#!/bin/bash
ssh_conf="/etc/ssh/ssh_config"
sshd_conf="/etc/ssh/sshd_config"

if grep -q Ciphers ${ssh_conf}; then
  sed -i.bak '/Ciphers.*/c\    Ciphers aes128-ctr,aes192-ctr,aes256-ctr' $ssh_conf
  sed -i.bak '/MACs.*/c\    MACs hmac-sha1,hmac-ripemd160' $ssh_conf
else
  echo "" >> $ssh_conf
  echo "# lines added to remove weak SSH Ciphers "
  echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" >> $ssh_conf
  echo "MACs hmac-sha1,hmac-ripemd160" >> $ssh_conf
fi

if grep -q Ciphers ${sshd_conf}; then
  sed -i.bak '/Ciphers.*/c\Ciphers aes128-ctr,aes192-ctr,aes256-ctr' $sshd_conf
  sed -i.bak '/MACs.*/c\MACs hmac-sha1,hmac-ripemd160' $sshd_conf
else
  echo "" >> $sshd_conf
  echo "# lines added to remove weak SSH Ciphers" >> $sshd_conf
  echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" >> $sshd_conf
  echo "MACs hmac-sha1,hmac-ripemd160" >> $sshd_conf
fi

service ssh restart
if [ ! "$?" -eq "0" ]; then
  echo "[ERROR] SSH service not found, trying SSHD instead on this EC2 NAT image ..."
  service sshd restart
fi
exit 0