# @description:   puppet module for setting apt sources to example location
# @author:        Austin Matthews

$apt_mod = "/opt/example/puppet/modules/apt/files"

class { 'apt': }

class apt {
  notify { "OK - apt":
    name    => "Setting apt sources to example ...",
    require => Class["apt::config"],
    before  => Notify["OK - apt-get test update"],
  }

  include apt::config
  include apt::install

  Class['apt::config'] -> Class['apt::install']
}

class apt::config {
  $mod_home = "/opt/example/puppet/modules/apt/files"

  file { "/etc/apt/sources.list":
    ensure => present,
    source => "${apt_mod}/sources.list",
  }
}

class apt::install {
  package { "apt": ensure => present, }

  exec { "apt test":
    command => "/usr/bin/apt-get update",
    require => Class["apt::config"],
    onlyif  => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
  }

  notify { "OK - apt-get test update":
    name    => "Run an apt-get test update from example",
    require => Exec["apt test"],
  }
}
