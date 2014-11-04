#
# Puppet class to manage the ip aliases on cpanel servers.
#
# In hiera node declaration add :
# classes: ['cpanel::ipaliases']
# cpanel::ipaliases::networks:
#   - '123.123.123.0/24'
#

class cpanel::ipaliases (
    $networks = hiera_array('cpanel::ipaliases::networks',[]),
){
  file { "/etc/ips":
    content => template('cpanel/ips.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    notify  => Service["ipaliases"],
  }

# The ipaliases cpanel script doesn't act as a service so I may use an
# exec calling ''service ipaliases start'' on refreshonly because with
# that service declaration ipaliases is started each time puppet runs.
  service { "ipaliases": 
    ensure  => "running",
    enable  => "true",
  }
}
