# Class: dashboard::passenger
#
# This class configures parameters for the puppet-dashboard module.
#
# Parameters:
#   [*dashboard_site*]  - The ServerName setting for Apache
#   [*dashboard_port*]  - The port on which puppet-dashboard should run
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class dashboard::passenger (
  $dashboard_site,
  $dashboard_port,
  $dashboard_config = $dashboard::params::dashboard_config
) inherits dashboard {

  Class ['::passenger']
  -> Apache::Vhost[$dashboard_site]

  class { '::passenger':
    port    => $dashboard_port,
  }

  file { '/etc/init.d/puppet-dashboard':
    ensure => absent,
  }

  file { 'dashboard_config':
    ensure => absent,
    path   => $dashboard_config,
  }

  apache::vhost { $dashboard_site:
    port     => '8080',
    priority => '50',
    docroot  => '/usr/share/puppet-dashboard/public',
    template => 'dashboard/puppet-dashboard-passenger-vhost.erb',
  }

}
