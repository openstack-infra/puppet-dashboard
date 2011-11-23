# Class: dashboard::params
#
# This class configures parameters for the puppet-dashboard module.
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

  $dashboard_ensure      = 'present'
  $dashboard_user        = "puppet-dashboard"
  $dashboard_group       = "puppet-dashboard"
  $dashboard_password    = "changeme"
  $dashboard_db          = 'dashboard_production'
  $dashboard_charset     = 'utf8'
  $dashboard_environment = 'production'
  $dashboard_site        = "${fqdn}"
  $dashboard_port        = '8080'
  $passenger             = 'false'
  $mysql_root_pw         = 'changemetoo'
  $rails_base_uri        = '/'

 case $operatingsystem {
    'centos', 'redhat', 'fedora': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $mysql_package_provider = 'yum'
      $ruby_mysql_package     = 'ruby-mysql'
    }
    'ubuntu', 'debian': {
      $dashboard_service      = 'puppet-dashboard'
      $dashboard_package      = 'puppet-dashboard'
      $dashboard_root         = '/usr/share/puppet-dashboard'
      $mysql_package_provider = 'aptitude'
      $ruby_mysql_package     = 'libmysql-ruby1.8'
    }
 }

}
