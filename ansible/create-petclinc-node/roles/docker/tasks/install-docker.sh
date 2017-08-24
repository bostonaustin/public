#!/bin/sh
set -e
export DEBIAN_FRONTEND=noninteractive
docker_version='docker-engine_1.9.1'
url='https://get.docker.com/'
kern_extras="linux-image-extra-$(uname -r) linux-image-extra-virtual"

user="$(id -un 2>/dev/null || true)"

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

sh_c='sh -c'
if [ "$user" != 'root' ]; then
	if command_exists sudo; then
		sh_c='sudo -E sh -c'
	elif command_exists su; then
		sh_c='su -c'
	else
		cat >&2 <<-'EOF'
		Error: this installer needs the ability to run commands as root.
		We are unable to find either "sudo" or "su" available to make this happen.
		EOF
		exit 1
	fi
fi

if command_exists docker; then
		cat >&2 <<-'EOF'
			Warning: the "docker" command appears to already exist on this system.

			If you already have Docker installed, this script can cause trouble, which is
			why we're displaying this warning and provide the opportunity to cancel the
			installation.

			If you installed the current Docker package using this script and are using it
			again to update Docker, you can safely ignore this message.

			You may press Ctrl+C now to abort this script.
		EOF
		( set -x; sleep 20 )
	fi

apt-get install -y -q $kern_extras

# aufs is preferred over devicemapper; try to ensure the driver is available.
if ! grep -q aufs /proc/filesystems && ! $sh_c 'modprobe aufs'; then
	if uname -r | grep -q -- '-generic' && dpkg -l 'linux-image-*-generic' | grep -q '^ii' 2>/dev/null; then
		kern_extras="linux-image-extra-$(uname -r) linux-image-extra-virtual"

		apt_get_update
		( set -x; $sh_c 'sleep 3; apt-get install -y -q '"$kern_extras" ) || true

		if ! grep -q aufs /proc/filesystems && ! $sh_c 'modprobe aufs'; then
			echo >&2 'Warning: tried to install '"$kern_extras"' (for AUFS)'
			echo >&2 ' but we still have no AUFS.  Docker may not work. Proceeding anyways!'
			( set -x; sleep 10 )
		fi
	else
		echo >&2 'Warning: current kernel is not supported by the linux-image-extra-virtual'
		echo >&2 ' package.  We have no AUFS support.  Consider installing the packages'
		echo >&2 ' linux-image-virtual kernel and linux-image-extra-virtual for AUFS support.'
		( set -x; sleep 10 )
	fi
fi

# install apparmor utils if they're missing and apparmor is enabled in the kernel
# otherwise Docker will fail to start
if [ "$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null)" = 'Y' ]; then
	if command -v apparmor_parser >/dev/null 2>&1; then
		echo 'apparmor is enabled in the kernel and apparmor utils were already installed'
	else
		echo 'apparmor is enabled in the kernel, but apparmor_parser missing'
		apt_get_update
		( set -x; $sh_c 'sleep 3; apt-get install -y -q apparmor' )
	fi
fi

wget -O docker.deb https://apt.dockerproject.org/repo/pool/main/d/docker-engine/${docker_version}-0~trusty_amd64.deb
dpkg -i docker.deb
rm *.deb
docker -v
