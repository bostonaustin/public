#! /bin/bash

# perfect example of over-encapsulation

# generates a botable ubuntu 12.04 ISO image 

# requires:  standard ubuntu 12.04.1 image in local /opt/downloads

basedir="/opt/iso_images/"
downloads="/opt/downloads"
tmpdir="${TMPDIR:-/tmp}"
builddir="$tmpdir/build.$$"
mntdir="$tmpdir/mnt.$$"
release_name="precise"
release_version="12.04.1"
release_variant="server"
release_architecture="amd64"
release_base_url="http://releases.ubuntu.com"
release_base_name="ubuntu-$release_version-$release_variant-$release_architecture"
release_image_file="$release_base_name.iso"
release_url="$release_base_url/$release_name/$release_image_file"
target_base_name="${release_base_name}-auto"
target_directory="$basedir"
target_image_file="$target_base_name.iso"

progress() {
  echo "$*" >&2
}

error() {
  code="$1"; shift
  echo "ERROR: $*" >&2
  exit $code
}

create_directory() {
  path="$1"
  if [ ! -d "$path" ]; then
    progress "Creating directory $path..."
    mkdir -p "$path" || error 2 "Failed to create directory $path"
  fi
}

extract_iso() {
  archive="$1"
  if [ ! -r "$archive" ]; then
    error 1 "Cannot read ISO image $archive."
  fi
    directory="$2"
  if [ ! -d "$directory" ]; then
    mkdir "$directory" || exit 2 "Cannot extract CD to $directory"
  fi
  progress "Mounting image $archive (you may be asked for your password to authorize)..."
  create_directory "$mntdir"
  sudo mount -r -o loop "$archive" "$mntdir" || error 2 "Failed to mount image $archive"
  progress "Copying image contents..."
  cp -rT "$mntdir" "$directory" || error 2 "Failed to copy content of image $archive to $directory"
  chmod -R u+w "$directory"
  progress "Unmounting image $archive from $mntdir..."
  sudo umount "$mntdir"
  rmdir "$mntdir"
}

preset_language() {
  progress "Presetting language to 'en'..."
  echo "en" >"isolinux/lang" || error 2 "Failed to write $(pwd)/isolinux/lang"
}

create_kscfg() {
  if [ ! -f "ks.cfg" ]; then
    progress "Create ks.cfg file..."
    cat >"ks.cfg" <<EOF
#Generated by Kickstart Configurator
platform=AMD64
#System language
lang en_US
#Language modules to install
langsupport en_US
#System keyboard
keyboard us
#System mouse
mouse
#System timezone
timezone --utc America/New_York
#Reboot after installation
reboot
#Use text mode install
text
#Install OS instead of upgrade
install
#Use CDROM installation media
cdrom
#System bootloader configuration
#bootloader --location=mbr
#Clear the Master Boot Record
zerombr yes
#Partition clearing information
clearpart --all --initlabel
#Disk partitioning information
part / --fstype ext4 --size 1 --grow
part swap --recommended
#System authorization infomation
auth  --useshadow  --enablemd5
#Network information
network --bootproto=dhcp --device=eth0
#Firewall configuration
firewall --disabled
#Do not configure the X Window System
skipx
%packages
@ ubuntu-server
openssh-server
%post --nochroot
echo done
EOF
  fi
}

create_kspreseed() {
    if [ ! -f "ks.preseed" ]; then
    progress "Create ks.preseed file..."
    cat >"ks.preseed" <<EOF
# install server
d-i     debian-installer/locale string en_US.UTF-8
d-i     debian-installer/splash boolean false
d-i     console-setup/ask_detect        boolean false
d-i     console-setup/layoutcode        string us
d-i     console-setup/variantcode       string
d-i     netcfg/choose_interface select eth0
d-i     netcfg/get_nameservers  string
d-i     netcfg/get_ipaddress    string
d-i     netcfg/get_netmask      string 255.255.255.0
d-i     netcfg/get_gateway      string
d-i     netcfg/confirm_static   boolean false
# basic 500gb raid1 on sda-sdb /
d-i     partman-lvm/device_remove_lvm boolean true
d-i     partman-auto/method string raid
d-i     partman-auto/disk string /dev/sda /dev/sdb
# specify the physical partitions that will be used.
d-i     partman-auto/expert_recipe string          \
        multiraid ::                               \
        1000 1000 1000 raid                        \
              $primary{ } method{ raid }           \
        .                                          \
        64 512 32000 raid                          \
              method{ raid }                       \
        .                                          \
        500 10000 32000 raid                       \
              method{ raid }                       \
        .                                          \
        500 10000 100000000 raid                   \
              method{ raid }                       \
        .
d-i     partman-auto-raid/recipe string            \
        1 2 0 ext4 /boot                           \
          /dev/sda1#/dev/sdb1                      \
        .                                          \
        1 2 0 swap -                               \
          /dev/sda5#/dev/sdb5                      \
        .                                          \
        1 2 0 ext4 /tmp                            \
          /dev/sda7#/dev/sdb7                      \
        .                                          \
        1 2 0 ext4 /                               \
          /dev/sda6#/dev/sdb6                      \
        .

# make partman automatically partition without confirmation.
d-i     mdadm/boot_degraded boolean true
d-i     partman-md/device_remove_md boolean true
d-i     partman-md/confirm boolean true
d-i     partman-md/confirm_write_new_label boolean true
d-i     partman-md/choose_partition select Finish partitioning and write changes to disk
# Write the changes to the storage devices and configure RAID?
d-i     partman-md/confirm_nooverwrite	boolean	true
d-i     partman-md/confirm boolean true
d-i     partman/confirm_write_new_label boolean true
d-i     partman/choose_partition select Finish partitioning and write changes to disk
d-i     partman/confirm_nooverwrite boolean true
d-i     partman/confirm boolean true
d-i     clock-setup/utc boolean true
d-i     clock-setup/ntp boolean true
d-i     clock-setup/ntp-server  string ntp.ubuntu.com
d-i     base-installer/kernel/image     string standard
d-i     passwd/root-login       boolean false
d-i     passwd/make-user        boolean true
d-i     passwd/user-fullname    string example
d-i     passwd/username string example
d-i     passwd/user-password password ST0r!ant
d-i     passwd/user-password-again password ST0r!ant
d-i     passwd/user-uid string
d-i     user-setup/allow-password-weak  boolean true
d-i     user-setup/encrypt-home boolean false
d-i     passwd/user-default-groups      string sudo adm cdrom dialout lpadmin plugdev sambashare
d-i     apt-setup/services-select       multiselect security
d-i     apt-setup/security_host string security.ubuntu.com
d-i     apt-setup/security_path string /ubuntu
d-i     debian-installer/allow_unauthenticated  string false
d-i     pkgsel/upgrade  select safe-upgrade
d-i     pkgsel/language-packs   multiselect
d-i     pkgsel/update-policy    select none
d-i     pkgsel/updatedb boolean true
d-i     pkgsel/include string openssh-server wget curl
d-i     grub-installer/skip     boolean false
d-i     lilo-installer/skip     boolean false
d-i     grub-installer/only_debian      boolean true
d-i     grub-installer/with_other_os    boolean true
d-i     finish-install/keep-consoles    boolean false
d-i     finish-install/reboot_in_progress       note
d-i     cdrom-detect/eject      boolean true
d-i     debian-installer/exit/halt      boolean false
d-i     debian-installer/exit/poweroff  boolean false
d-i preseed/late_command string \
    chroot /target sh -c "/usr/bin/curl -o /tmp/postinstall.sh http://ftp.example.com/1.5.0/postinstall.sh && /bin/chmod 777 /tmp/postinstall.sh && /bin/sh -x /tmp/postinstall.sh"
EOF
    fi
}

patch_txtcfg() {
    (cd "isolinux";
    patch -p0 <<EOF
*** txt.cfg.orig    2013-05-14 10:06:19.000000000 +0200
--- txt.cfg 2013-05-14 10:07:54.000000000 +0200
***************
*** 2,8 ****
  label install
    menu label ^Install example Server v1.5.0
    kernel /install/vmlinuz
!   append  file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/initrd.gz quiet --
  label cloud
    menu label ^Multiple server install with MAAS
    kernel /install/vmlinuz
--- 2,8 ----
  label install
    menu label ^Install example Server v1.5.0
    kernel /install/vmlinuz
!   append  file=/cdrom/preseed/ubuntu-server.seed initrd=/install/initrd.gz ks=cdrom:/ks.cfg preseed/file=/cdrom/ks.preseed --
  label cloud
    menu label ^Install example Server v1.5.0
    kernel /install/vmlinuz
EOF
    )
}

patch_isolinuxcfg() {
    (cd "isolinux";
    patch -p0 <<EOF
*** isolinux.cfg.orig   2013-05-14 10:20:37.000000000 +0200
--- isolinux.cfg    2013-05-14 10:20:50.000000000 +0200
***************
*** 2,6 ****
  include menu.cfg
  default vesamenu.c32
  prompt 0
! timeout 0
  ui gfxboot bootlogo
--- 2,6 ----
  include menu.cfg
  default vesamenu.c32
  prompt 0
! timeout 5
  ui gfxboot bootlogo
EOF
    )
}

modify_release() {
  preset_language && \
  create_kscfg && \
  create_kspreseed && \
  patch_txtcfg && \
  patch_isolinuxcfg
}

create_image() {
  if [ ! -f "$target_directory/$target_image_file" ]; then
    if [ ! -f "$downloads/$release_image_file" ]; then
      progress "Downloading Ubuntu $release_name $release_variant..."
      curl "$release_url" -o "$downloads/$release_image_file"
    fi
    create_directory "$builddir"
    extract_iso "$downloads/$release_image_file" "$builddir"
    (cd "$builddir" && modify_release) || error 2 "Failed to modify image"

    create_directory "$target_directory"
    progress "Creating ISO image $target_image_file..."
    mkisofs -D -r -V "EXAMPLE_INSTALL" -cache-inodes -J -l \
      -b isolinux/isolinux.bin \
      -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
      -boot-info-table \
      -o "$target_directory/$target_image_file" \
      "$builddir" || error 2 "Failed to create image $target_image_file"
    if [ "x$builddir" != x -a "x$builddir" != "x/" ]; then
      rm -rf "$builddir"
    fi
  fi
}

create_image