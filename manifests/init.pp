# Class: puppet::dashboard
#
# This class installs and configures parameters for Puppet Dashboard
#
# Parameters:
#   [*dashboard_ensure*]    - The value of the ensure parameter for the 
#                               puppet-dashboard package.
#   [*dashboard_user*]      - Name of the puppet-dashboard database and 
#                               system user.
#   [*dashboard_group*]     - Name of the puppet-dashboard group.
#   [*dashbaord_password*]  - Password for the puppet-dashboard database user.
#   [*dashboard_db*]        - The puppet-dashboard database name.
#   [*dashboard_charset*]   - Character set for the puppet-dashboard database.
#   [*mysql_root_pw*]       - Password for root on MySQL
#
# Actions:
#   Install mysql, ruby-mysql, and mysql-server
#   Install puppet-dashboard packages
#   Write the database.yml
#   Setup a puppet-dashboard database
#   Start puppet-dashboard
#
#
# Requires:
# Class['mysql']
# Class['mysql::ruby']
# Class['mysql::server']
#
#
# Sample Usage:
#   class {'dashboard':
#     dashboard_ensure          => 'present',
#     dashboard_user            => 'dashboard',
#     dashboard_password        => 'changeme',
#     dashboard_db              => 'dashboard_db',
#     dashboard_charset         => 'utf8',
#   }
#
class dashboard (
  $dashboard_ensure         = $dashboard::params::dashboard_ensure,
  $dashboard_user           = $dashboard::params::dashboard_user,
  $dashboard_group          = $dashboard::params::dashboard_group,
  $dashboard_password       = $dashboard::params::dashboard_password,
  $dashboard_db             = $dashboard::params::dashboard_db,
  $dashboard_charset        = $dashboard::params::dashboard_charset,
  $mysql_root_pw            = $dashboard::params::mysql_root_pw

) inherits dashboard::params {

  $v_alphanum = '^[._0-9a-zA-Z:-]+$'
  $v_bool = [ '^true$', '^false$' ]
  validate_re($dashboard_ensure, $v_alphanum)
  validate_re($dashboard_user, $v_alphanum)
  validate_re($dashboard_group, $v_alphanum)
  validate_re($dashboard_password, $v_alphanum)
  validate_re($dashboard_db, $v_alphanum)
  validate_re($dashboard_charset, $v_alphanum)
  validate_re($mysql_root_pw, $v_alphanum)

  $dashboard_ensure_real   = $dashboard_ensure
  $dashboard_user_real     = $dashboard_user
  $dashboard_group_real    = $dashboard_group
  $dashboard_password_real = $dashboard_password
  $dashboard_db_real       = $dashboard_db
  $dashboard_charset_real  = $dashboard_charset
  $mysql_root_pw_real      = $mysql_root_pw

  class { 'mysql': }
  class { 'mysql::server': root_password => $mysql_root_pw_real }
  class { 'mysql::ruby':
    package_provider => $dashboard::params::mysql_package_provider,
    package_name     => $dashboard::params::ruby_mysql_package,
  }

  if $passenger {
    Class['mysql']
    -> Class['mysql::ruby']
    -> Class['mysql::server']
    -> Package[$dashboard_package]
    -> Mysql::DB["${dashboard_db}"]
    -> File["${dashboard::params::dashboard_root}/config/database.yml"]
    -> Exec['db-migrate']
    -> Class['dashboard::passenger']

    class { 'dashboard::passenger':
      dashboard_site => $dashboard_site,
      dashboard_port => $dashboard_port,
    }

  } else {
    Class['mysql']
    -> Class['mysql::ruby']
    -> Class['mysql::server']
    -> Package[$dashboard_package]
    -> Mysql::DB["${dashboard_db}"]
    -> File["${dashboard::params::dashboard_root}/config/database.yml"]
    -> Exec['db-migrate']
    -> Service[$dashboard_service]

    case $operatingsystem {
      'centos','redhat','oel': {
        file { '/etc/sysconfig/puppet-dashboard':
          ensure  => present,
          content => template('dashboard/puppet-dashboard-sysconfig'),
          owner   => '0',
          group   => '0',
          mode    => '0644',
          require => [ Package[$dashboard_package], User[$dashboard_user] ],
          before  => Service[$dashboard_service],
        }
      }
      'debian','ubuntu': {
        file { '/etc/default/puppet-dashboard':
          ensure  => present,
          content => template('dashboard/puppet-dashboard.default.erb'),
          owner   => '0',
          group   => '0',
          mode    => '0644',
          require => [ Package[$dashboard_package], User[$dashboard_user] ],
          before  => Service[$dashboard_service],
        }
      }
    }

    service { $dashboard_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      subscribe  => File['/etc/puppet-dashboard/database.yml'],
      require    => Exec['db-migrate']
    }
  }

  package { $dashboard_package:
    ensure => $dashboard_version_real,
  }

  file {'/etc/puppet-dashboard/database.yml':
    ensure  => present,
    content => template('dashboard/database.yml.erb'),
    mode    => '0755',
    owner   => $dashboard_user_real,
    group   => $dashboard_group_real,
  }

  file { "${dashboard::params::dashboard_root}/config/database.yml":
    ensure => 'link',
    target => '/etc/puppet-dashboard/database.yml',
    mode   => '0755',
    owner  => $dashboard_user_real,
    group  => $dashboard_group_real,
  }

  file { [ "${dashboard::params::dashboard_root}/public", "${dashboard::params::dashboard_root}/public/stylesheets", "${dashboard::params::dashboard_root}/public/javascript", "${dashboard::params::dashboard_root}/tmp", "${dashboard::params::dashboard_root}/log", '/etc/puppet-dashboard' ]:
    ensure       => directory,
    mode         => '0755',
    owner        => $dashboard_user_real,
    group        => $dashboard_group_real,
    recurse      => true,
    recurselimit => '1',
    require      => Package[$dashboard_package],
    before       => Service['puppet-dashboard'],
  }

  file { "${dashboard::params::dashboard_root}/log/production.log":
    ensure => file,
    mode   => '0644',
    owner  => $dashboard_user_real,
    group  => $dashboard_group_real,
  }
  
  file { '/etc/logrotate.d/puppet-dashboard':
    ensure  => present,
    content => template('puppet/puppet-dashboard.logrotate.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  exec { 'db-migrate':
    command => "rake RAILS_ENV=production db:migrate",
    cwd     => "${dashboard::params::dashboard_root}",
    path    => "/usr/bin/:/usr/local/bin/",
    creates => "/var/lib/mysql/${dashboard_db_real}/nodes.frm",
  }

  mysql::db { "${dashboard_db_real}":
    user     => $dashboard_user_real,
    password => $dashboard_password_real,
    charset  => $dashboard_charset_real,
  }
  
  # The Debian package did not include users. I ensure them here without
  #  specifying a UID or GID.
  user { $dashboard_user_real:
      comment    => 'Puppet Dashboard',
      gid        => "${dashboard_group_real}",
      ensure     => 'present',
      shell      => '/sbin/nologin',
      managehome => true,
      home       => "/home/${dashboard_user_real}",
  }

  group { $dashboard_group_real:
      ensure => 'present',
  }

}

