# Class: puppet::params
#
# This class installs and configures parameters for Puppet
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class dashboard::params {

  $dashboard_ensure           = 'present'
  $dashboard_user             = "puppet-dashboard"
  $dashboard_group            = "puppet-dashboard"
  $dashboard_password         = "changeme"
  $dashboard_db               = 'dashboard_production'
  $dashboard_charset          = 'utf8'

 case $operatingsystem {
    'centos', 'redhat', 'fedora': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $web_user               = 'apache'
      $web_group              = 'apache'
    }
    'ubuntu', 'debian': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $web_user               = 'www'
      $web_group              = 'www'
    }
    'freebsd': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $web_user               = 'www'
      $web_group              = 'www'
    }
    'darwin': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $web_user               = 'www'
      $web_group              = 'www'
    }
 }

}
