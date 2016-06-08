#!/usr/bin/perl
#@description:      nagios service check run on the remote server to verify the zpool status
#@example:          cmd zfs_pool_name verbosity <1-3>
#                    user@lab1:~$ sudo /usr/lib/nagios/plugins/check_zfs.pl tank 3
#                     OK ZPOOL tank : ONLINE {Size:21.8T Used:920K Avail:21.7T Cap:0% Dedup:1.00x}

# Libs etc {{{
use strict;
use warnings;
use Sys::Hostname;
# }}}

# Globals {{{
my %ERRORS = (
  'OK' => 0,
  'WARNING' => 1,
  'CRITICAL' => 2,
  'UNKNOWN' => 3,
  'DEPENDENT' => 4,
);

my $state="UNKNOWN";
my $msg="FAILURE";

my %supported_OSes = (
  'solaris' => 1,
  'freebsd' => 1,
  'darwin' => 1,
  'linux' => 1,
);

my %beta_OSes = (
  'darwin' => 1,
);

my $OS = ucfirst($^O);

  # sys_vol_tray {{{
  my %sys_vol_tray = (
    # dmz-backup {{{
      'dmz-backup' => {
                'systemdescription' => "Main backup storage for NILU DMZ",
                'rpool' => {
                        'inside' => {
                                'c6d0s0' => 0,
                                'c7d0s0' => 0,
                        },
                },
                'pbpool' => {
                        'internal' => {
                                'c8t0d0' => 0,
                                'c8t1d0' => 1,
                                'c8t2d0' => 2,
                                'c8t3d0' => 3,
                                'c8t4d0' => 4,
                                'c8t5d0' => 5,
                                'c8t6d0' => 6,
                                'c8t7d0' => 7,
                                'c8t8d0' => 8,
                                'c8t9d0' => 9,
                                'c8t10d0' => 10,
                                'c8t11d0' => 11,
                                'c8t12d0' => 12,
                                'c8t13d0' => 13,
                                'c8t14d0' => 14,
                                'c8t15d0' => 15,
                                'c8t16d0' => 16,
                                'c8t17d0' => 17,
                                'c8t18d0' => 18,
                                'c8t19d0' => 19,
                                'c8t20d0' => 20,
                                'c8t21d0' => 21,
                                'c8t22d0' => 22,
                                'c8t23d0' => 23,
                                'c8t24d0' => 24,
                                'c8t25d0' => 25,
                                'c8t26d0' => 26,
                                'c8t27d0' => 27,
                                'c8t28d0' => 28,
                                'c8t29d0' => 29,
                                'c8t30d0' => 30,
                                'c8t31d0' => 31,
                                'c8t32d0' => 32,
                                'c8t33d0' => 33,
                                'c8t34d0' => 34,
                                'c8t35d0' => 35,
                        },
                        'jbod-1' => {
                                'c4t0d0' => 0,
                                'c4t1d0' => 1,
                                'c4t2d0' => 2,
                                'c4t3d0' => 3,
                                'c4t4d0' => 4,
                                'c4t5d0' => 5,
                                'c4t6d0' => 6,
                                'c4t7d0' => 7,
                                'c4t8d0' => 8,
                                'c4t9d0' => 9,
                                'c4t10d0' => 10,
                                'c4t11d0' => 11,
                                'c4t12d0' => 12,
                                'c4t13d0' => 13,
                                'c4t14d0' => 14,
                                'c4t15d0' => 15,
                                'c4t16d0' => 16,
                                'c4t17d0' => 17,
                                'c4t18d0' => 18,
                                'c4t19d0' => 19,
                                'c4t20d0' => 20,
                                'c4t21d0' => 21,
                                'c4t22d0' => 22,
                                'c4t23d0' => 23,
                                'c4t24d0' => 24,
                                'c4t25d0' => 25,
                                'c4t26d0' => 26,
                                'c4t27d0' => 27,
                                'c4t28d0' => 28,
                                'c4t29d0' => 29,
                                'c4t30d0' => 30,
                                'c4t31d0' => 31,
                                'c4t32d0' => 32,
                                'c4t33d0' => 33,
                                'c4t34d0' => 34,
                                'c4t35d0' => 35,
                                'c4t36d0' => 36,
                                'c4t37d0' => 37,
                                'c4t38d0' => 38,
                                'c4t39d0' => 39,
                                'c4t40d0' => 40,
                                'c4t41d0' => 41,
                                'c4t42d0' => 42,
                                'c4t43d0' => 43,
                                'c4t44d0' => 44,
                        },
                        'inside' => {
                                'c6d1' => 0,
                                'c7d1' => 1,
                        },
                },
        },
    # }}}
    # mime-oi {{{
      'mime-oi' => {
                'systemdescription' => "Test server on OpenIndiana 148",
                'mimedata' => {
                        'internal' => {
                                'c4t1d0' => 1,
                                'c4t2d0' => 2,
                                'c4t3d0' => 3,
                                'c4t4d0' => 4,
                                'c4t5d0' => 5,
                                'c4t6d0' => 6,
                                'c4t7d0' => 7,
                        },
                },
        },
    # }}}
    # prv-backup {{{
      'prv-backup' => {
                'systemdescription' => "Main backup storage for NILU private",
                'rpool' => {
                        'inside' => {
                                'c6d0s0' => 0,
                                'c7d0s0' => 0,
                        },
                },
                'pbpool' => {
                        'inside' => {
                                'c8t0d0' => 0,
                                'c8t1d0' => 1,
                                'c8t2d0' => 2,
                                'c8t3d0' => 3,
                                'c8t4d0' => 4,
                                'c8t5d0' => 5,
                                'c8t6d0' => 6,
                                'c8t7d0' => 7,
                                'c8t8d0' => 8,
                                'c8t9d0' => 9,
                                'c8t10d0' => 10,
                                'c8t11d0' => 11,
                                'c8t12d0' => 12,
                                'c8t13d0' => 13,
                                'c8t14d0' => 14,
                                'c8t15d0' => 15,
                                'c8t16d0' => 16,
                                'c8t17d0' => 17,
                                'c8t18d0' => 18,
                                'c8t19d0' => 19,
                                'c8t20d0' => 20,
                                'c8t21d0' => 21,
                                'c8t22d0' => 22,
                                'c8t23d0' => 23,
                                'c8t24d0' => 24,
                                'c8t25d0' => 25,
                                'c8t26d0' => 26,
                                'c8t27d0' => 27,
                                'c8t28d0' => 28,
                                'c8t29d0' => 29,
                                'c8t30d0' => 30,
                                'c8t31d0' => 31,
                                'c8t32d0' => 32,
                                'c8t33d0' => 33,
                                'c8t34d0' => 34,
                                'c8t35d0' => 35,
                        },
                        'jbod-1' => {
                                'c4t0d0' => 0,
                                'c4t1d0' => 1,
                                'c4t2d0' => 2,
                                'c4t3d0' => 3,
                                'c4t4d0' => 4,
                                'c4t5d0' => 5,
                                'c4t6d0' => 6,
                                'c4t7d0' => 7,
                                'c4t8d0' => 8,
                                'c4t9d0' => 9,
                                'c4t10d0' => 10,
                                'c4t11d0' => 11,
                                'c4t12d0' => 12,
                                'c4t13d0' => 13,
                                'c4t14d0' => 14,
                                'c4t15d0' => 15,
                                'c4t16d0' => 16,
                                'c4t17d0' => 17,
                                'c4t18d0' => 18,
                                'c4t19d0' => 19,
                                'c4t20d0' => 20,
                                'c4t21d0' => 21,
                                'c4t22d0' => 22,
                                'c4t23d0' => 23,
                                'c4t24d0' => 24,
                                'c4t25d0' => 25,
                                'c4t26d0' => 26,
                                'c4t27d0' => 27,
                                'c4t28d0' => 28,
                                'c4t29d0' => 29,
                                'c4t30d0' => 30,
                                'c4t31d0' => 31,
                                'c4t32d0' => 32,
                                'c4t33d0' => 33,
                                'c4t34d0' => 34,
                                'c4t35d0' => 35,
                                'c4t36d0' => 36,
                                'c4t37d0' => 37,
                                'c4t38d0' => 38,
                                'c4t39d0' => 39,
                                'c4t40d0' => 40,
                                'c4t41d0' => 41,
                                'c4t42d0' => 42,
                                'c4t43d0' => 43,
                                'c4t44d0' => 44,
                        },
                        'inside' => {
                                'c6d1' => 0,
                                'c7d1' => 1,
                        },
                },
        },
    # }}}
    # urd {{{
      'urd' => {
                'dpool' => {
                        'internal' => {
                                'c7t0d0s0' => 0,
                                'c7t1d0s0' => 1,
                                'c7t2d0' => 2,
                                'c7t3d0' => 3,
                                'c7t4d0' => 4,
                                'c7t5d0' => 5,
                                'c7t6d0' => 6,
                                'c7t7d0' => 7,
                                'c8t0d0' => 8,
                                'c8t1d0' => 9,
                                'c8t2d0' => 10,
                                'c8t3d0' => 11,
                                'c8t4d0' => 12,
                                'c8t5d0' => 13,
                                'c8t6d0' => 14,
                                'c8t7d0' => 15,
                                'c9t0d0' => 16,
                                'c9t1d0' => 17,
                                'c9t2d0' => 18,
                                'c9t3d0' => 19,
                                'c9t4d0' => 20,
                                'c9t5d0' => 21,
                                'c9t6d0' => 22,
                                'c9t7d0' => 23,
                        },
                        'disk-jbod' => {
                                'c14t9d0' => 0,
                                'c14t10d0' => 1,
                                'c14t11d0' => 2,
                                'c14t12d0' => 3,
                                'c14t13d0' => 4,
                                'c14t14d0' => 5,
                                'c14t15d0' => 6,
                                'c14t16d0' => 7,
                                'c14t17d0' => 8,
                                'c14t18d0' => 9,
                                'c14t19d0' => 10,
                                'c14t20d0' => 11,
                        },
                        'cache-jbod' => {
                                'c14t21d0' => 0,
                                'c14t22d0' => 1,
                                'c14t23d0' => 2,
                                'c14t24d0' => 3,
                                'c14t25d0' => 4,
                                'c14t26d0' => 5,
                                'c14t27d0' => 6,
                                'c14t28d0' => 7,
                                'c14t29d0' => 8,
                                'c14t30d0' => 9,
                                'c14t31d0' => 10,
                                'c14t32d0' => 11,
                        },
                },
        },
    # }}}
    # urd-backup {{{
      'urd-backup' => {
                'rpool' => {
                        'inside' => {
                                'c7d0s0' => 0,
                                'c8d0s0' => 1,
                        },
                },
                'urd-backup' => {
                        'jbod-1' => {
                                'c5t0d0' => 0,
                                'c5t1d0' => 1,
                                'c5t2d0' => 2,
                                'c5t3d0' => 3,
                                'c5t4d0' => 4,
                                'c5t5d0' => 5,
                                'c5t6d0' => 6,
                                'c5t7d0' => 7,
                                'c5t8d0' => 8,
                                'c5t9d0' => 9,
                                'c5t10d0' => 10,
                                'c5t11d0' => 11,
                        },
                        'jbod-2' => {
                                'c5t12d0' => 0,
                                'c5t13d0' => 1,
                                'c5t14d0' => 2,
                                'c5t15d0' => 3,
                                'c5t16d0' => 4,
                                'c5t17d0' => 5,
                                'c5t18d0' => 6,
                                'c5t19d0' => 7,
                                'c5t20d0' => 8,
                                'c5t21d0' => 9,
                                'c5t22d0' => 10,
                                'c5t23d0' => 11,
                                'c5t24d0' => 12,
                                'c5t25d0' => 13,
                                'c5t26d0' => 14,
                                'c5t27d0' => 15,
                                'c5t28d0' => 16,
                                'c5t29d0' => 17,
                                'c5t30d0' => 18,
                                'c5t31d0' => 19,
                                'c5t32d0' => 20,
                                'c5t33d0' => 21,
                                'c5t34d0' => 22,
                                'c5t35d0' => 23,
                        },
                },
        },
    # }}}
    # verdande {{{
      'verdande' => {
                'rpool' => {
                        'internal' => {
                                'c2t0d0s0' => 0,
                                'c2t1d0s0' => 1,
                        },
                },
                'tos-data' => {
                        'internal' => {
                                'c2t2d0' => 2,
                                'c2t3d0' => 3,
                                'c2t4d0' => 4,
                                'c2t5d0' => 5,
                                'c2t6d0' => 6,
                                'c2t7d0' => 7,
                                'c2t8d0' => 8,
                                'c2t9d0' => 9,
                                'c2t10d0' => 10,
                                'c2t11d0' => 11,
                                'c2t12d0' => 12,
                                'c2t13d0' => 13,
                                'c2t14d0' => 14,
                                'c2t15d0' => 15,
                                'c2t16d0' => 16,
                                'c2t17d0' => 17,
                                'c2t18d0' => 18,
                                'c2t19d0' => 19,
                                'c2t20d0' => 20,
                                'c2t21d0' => 21,
                                'c2t22d0' => 22,
                                'c2t23d0' => 23,
                        },
                },
        },
    # }}}
  );
  # sys_vol_tray end }}}
# Globals end }}}

# Init {{{
if ($beta_OSes{$^O})
{
  print STDERR "NOTICE: This plugin is flagged as a beta plugin under $OS.\n";
}
elsif (!$supported_OSes{$^O})
{
  print STDERR "UNKNOWN: This plugin is not yet ported to your operating system, $OS.\n";
  exit $ERRORS{$state};
}

if ($#ARGV != 1)
{
  print "Usage: $0 <zpool name> <verbosity level 1-3>\n";
  exit $ERRORS{$state};
}

my $pool=$ARGV[0];
my $verbosity=$ARGV[1];
my $zpoolcmd = '/usr/sbin/zpool';
my $size="";
my $used="";
my $deduprat="";
my $avail="";
my $cap="";
my $health="";
my $dmge="";
my $dedup=0;
if ($verbosity < 1 || $verbosity > 3)
{
  print "Verbose levels range from 1-3\n";
  exit $ERRORS{$state};
}
my $hostname = hostname;
# }}}

# main {{{
my $statcommand="$zpoolcmd list $pool";
if (!open STAT, "$statcommand|")
{
  print ("$state '$statcommand' command returns no result! NOTE: This plugin needs OS support for ZFS, and execution with root privileges.\n");
  exit $ERRORS{$state};
}

while (<STAT>)
{
  my $dummy;
  chomp;
  if (/^NAME\s+SIZE\s+USED\s+AVAIL\s+CAP\s+HEALTH\s+ALTROOT/)
  {
    print "whoo\n";
    next;
  }

  elsif (/^NAME\s+SIZE\s+ALLOC\s+FREE\s+CAP\s+DEDUP\s+HEALTH\s+ALTROOT/)
  {
    $dedup = 1;
    next;
  }
  if (/^${pool}\s+/)
  {
    if ($dedup)
    {
      ($dummy, $size, $used, $avail, $cap, $deduprat, $health) = split(/\s+/);
    }
    else
    {
      ($dummy, $size, $used, $avail, $cap, $health) = split(/\s+/);
    }
  }
}

close(STAT);
# check for valid zpool list response from zpool
if (! $health )
{
  $state = "CRITICAL";
  $msg = sprintf "ZPOOL {%s} does not exist and/or is not responding!\n", $pool;
  print $state, " ", $msg;
  exit ($ERRORS{$state});
}

# determine health of zpool and subsequent error status
if ($health eq "ONLINE" )
{
  $state = "OK";
}
else
{
  if ($health eq "DEGRADED")
  {
    $state = "WARNING";
  }
  else
  {
    $state = "CRITICAL";
  }
}

my $poolfind = 0;
$statcommand="$zpoolcmd status $pool";
if (! open STAT, "$statcommand|")
{
  $state = 'CRITICAL';
  print ("$state '$statcommand' command returns no result! NOTE: This plugin needs OS support for ZFS, and execution with root privileges.\n");
  exit $ERRORS{$state};
}

# go through zfs status output to find zpool fses and devices
while(<STAT>)
{
  chomp;
  if (/^\s${pool}/ && $poolfind == 1)
  {
    $poolfind = 2;
    next;
  }
  elsif ( $poolfind == 1 )
  {
    $poolfind = 0;
  }

  if (/NAME\s+STATE\s+READ\s+WRITE\s+CKSUM/)
  {
    $poolfind = 1;
  }

  if ( /^$/ )
  {
    $poolfind = 0;
  }

  if ($poolfind == 2)
  {
    ## special cases pertaining to full verbosity
    if (/^\sspares/)
    {
      next unless $verbosity == 3;
      $dmge=$dmge . "[SPARES]:- ";
      next;
    }
    if (/^\s{5}spare\s/)
    {
      next unless $verbosity == 3;
      my ($sta) = /spare\s+(\S+)/;
      $dmge=$dmge . "[SPARE:${sta}]:- ";
      next;
    }
    if (/^\s{5}replacing\s/)
    {
      next unless $verbosity == 3;
      my $perc;
      my ($sta) = /^\s+\S+\s+(\S+)/;
      if (/%/)
      {
        ($perc) = /([0-9]+%)/;
      }
      else
      {
        $perc = "working";
      }
      $dmge=$dmge . "[REPLACING:${sta} (${perc})]:- ";
      next;
    }

    ## other cases
    my ($dev, $sta) = /^\s+(\S+)\s+(\S+)/;
    next unless (defined($dev) and defined($sta));

    for my $chassis (values %{$sys_vol_tray{$hostname}{$pool}} )
    {
      if (exists $chassis->{$dev})
      {
        my $s = $chassis->{$dev};
        $dev .= "/tray $s";
      }
    }

    ## pool online, not degraded thanks to dead/corrupted disk
    if ($state eq "OK" && $sta eq "UNAVAIL")
    {
      $state="WARNING";
      ## switching to verbosity level 2 to explain weirdness
      if ($verbosity == 1)
      {
        $verbosity = 2;
      }
    }

    ## no display for verbosity level 1
    next if ($verbosity == 1);
    ## don't display working devices for verbosity level 2
    next if ($verbosity == 2 && $state eq "OK");
    next if ($verbosity == 2 && ($sta eq "ONLINE" || $sta eq "AVAIL" || $sta eq "INUSE"));

    ## show everything else
    if (/^\s{3}(\S+)/)
    {
      $dmge .= "<" . $dev . ":" . $sta . "> ";
    }
    elsif (/^\s{7}(\S+)/)
    {
      $dmge .= "(" . $dev . ":" . $sta . ") ";
    }
    else
    {
      $dmge .= $dev . ":" . $sta . " ";
    }
  }
}

# print results
if ($dedup)
{
  $msg = sprintf "%s: %s | Size=%s; Used=%s; Avail=%s; Cap=%s; Dedup=%s; %s\n", $pool, $health, $size, $used, $avail, $cap, $deduprat, $dmge;
}
else
{
  $msg = sprintf "%s: %s | Size=%s; Used=%s; Avail=%s; Cap=%s; %s\n", $pool, $health, $size, $used, $avail, $cap, $dmge;
}
print "ZPOOL ", $state, " - ", $msg;
exit ($ERRORS{$state});
# main end }}}