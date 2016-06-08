# cobbler kickstart template in /var/lib/cobbler/kickstarts/example-mgmt
#
# install + configure a new management server with icinga + logstash + cobbler + puppet
#
# @author:  Austin Matthews

# first call the 'example-base' set of packages for all server types
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/splash boolean false
d-i console-setup/ask_detect        boolean false
d-i console-setup/layoutcode        string us
d-i console-setup/variantcode       string
# known bug - being ignored here, handle at kopts level on profile or system
#d-i netcfg/choose_interface select eth0
d-i netcfg/get_nameservers  string
d-i netcfg/get_ipaddress    string
d-i netcfg/get_netmask      string 255.255.255.0
d-i netcfg/get_gateway      string
d-i netcfg/confirm_static   boolean false
d-i partman-lvm/device_remove_lvm boolean true

# setup RAID1 on sda-sdb
d-i partman-auto/method string raid
d-i partman-auto/disk string /dev/sda /dev/sdb
# set the physical partitions that will be used
d-i partman-auto/expert_recipe string                      \
      multiraid ::                                         \
              10000 5000 20000 raid                        \
                      $primary{ } method{ raid }           \
              .                                            \
              64 512 300% raid                             \
                      method{ raid }                       \
              .                                            \
              50000 10000 100000 raid                      \
                      method{ raid }                       \
              .                                            \
              5000 5000 10000 raid                         \
                      method{ raid }                       \
              .                                            \
              500 10000 1000000000 raid                    \
                      method{ raid }                       \
              .

# specify how the previously defined partitions will be used in the RAID setup
# Parameters are:
# <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \
#          <devices> <sparedevices>
d-i partman-auto-raid/recipe string \
    1 2 0 ext3 /boot                \
          /dev/sda1#/dev/sdb1       \
    .                               \
    1 2 0 swap -                    \
          /dev/sda5#/dev/sdb5       \
    .                               \
    1 2 0 ext3 /                    \
          /dev/sda6#/dev/sdb6       \
    .                               \
    1 2 0 ext3 /metadata            \
          /dev/sda3#/dev/sdb3       \
    .                               \
    1 2 0 ext3 /drdb                \
          /dev/sda4#/dev/sdb4       \
    .

# make partman automatically partition without confirmation.
d-i mdadm/boot_degraded boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-md/confirm boolean true
d-i partman-md/confirm_write_new_label boolean true
d-i partman-md/choose_partition select Finish partitioning and write changes to disk
# write the changes to the storage devices and configure RAID?
d-i	partman-md/confirm_nooverwrite	boolean	true
d-i partman-md/confirm boolean true
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select Finish partitioning and write changes to disk
d-i partman/confirm_nooverwrite boolean true
d-i partman/confirm boolean true
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server  string ntp.ubuntu.com
d-i base-installer/kernel/image string linux-server
d-i passwd/root-login   boolean true
d-i passwd/root-password-crypted password $6$scVWpdbl$3NsAXJKoFCUxxKijifZY5guNS8OsJZA/9gb8oFtXWs3ofwMJZ4s/
d-i passwd/make-user    boolean true
d-i passwd/user-fullname    string example
d-i passwd/username string example
d-i passwd/user-password password password
d-i passwd/user-password-again password password
d-i passwd/user-uid string
d-i user-setup/allow-password-weak  boolean true
d-i user-setup/encrypt-home boolean false
d-i passwd/user-default-groups  string sudo adm cdrom dialout lpadmin plugdev sambashare
d-i apt-setup/services-select   multiselect security
d-i apt-setup/security_host string security.ubuntu.com
d-i apt-setup/security_path string /ubuntu
d-i debian-installer/allow_unauthenticated  string false
d-i pkgsel/upgrade  select safe-upgrade
d-i pkgsel/language-packs   multiselect
d-i pkgsel/update-policy    select none
d-i pkgsel/updatedb boolean true
d-i pkgsel/include string openssh-server curl wget
d-i grub-installer/skip boolean false
d-i lilo-installer/skip boolean false
d-i grub-installer/only_debian  boolean true
d-i grub-installer/with_other_os    boolean true
d-i finish-install/keep-consoles    boolean false
d-i finish-install/reboot_in_progress   note
d-i cdrom-detect/eject  boolean true
d-i debian-installer/exit/halt  boolean false
d-i debian-installer/exit/poweroff  boolean false
# post install script for storage postinstall
d-i preseed/late_command string \
    chroot /target sh -c "/usr/bin/curl -o /tmp/postinstall-mgmt.sh http://example.com/install/postinstall-mgmt.sh && /bin/sh -x /tmp/postinstall-mgmt.sh" && wget "http://$http_server:$http_port/cblr/svc/op/nopxe/system/$system_name" -O /dev/null
