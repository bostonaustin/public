#!/bin/sh

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

if [ ! -d == /opt/spring-petclinic ]; then
  cd /opt
  git clone https://github.com/spring-projects/spring-petclinic.git
  docker pull anthonydahanne/spring-petclinic
else
  cd /opt/spring-petclinic
  #mvn tomcat7:run
  #./mvnw spring-boot:run &
  mvn spring-boot:run &
fi
