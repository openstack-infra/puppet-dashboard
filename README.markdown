# Puppet Dashboard Module

Gary Larizza <gary@puppetlabs.com>

This module manages and installs the Puppet Dashboard.

# Quick Start

To install the Puppet Dashboard and configure it with sane defaults, include the following in your site.pp file:

    node default {
			   class {'dashboard':
			     dashboard_ensure          => 'present',
			     dashboard_user            => 'puppet-dbuser',
			     dashboard_group           => 'puppet-dbgroup',
			     dashboard_password        => 'changeme',
			     dashboard_db              => 'dashboard_prod',
			     dashboard_charset         => 'utf8',
			     dashboard_site            => $fqdn,
			     dashboard_port            => '8080',
			     mysql_root_pw             => 'changemetoo',
			     passenger                 => true,
			     mysql_package_provider    => 'yum',
		       ruby_mysql_package        => 'ruby-mysql',
			   }
		}

None of these parameters are required - if you neglect any of them their values will default back to those set in the dashboard::params subclass.

# Feature Requests

* Sqlite support.
* Integration with Puppet module to set puppet.conf settings.
* Remove the need to set the MySQL root password (needs fixed in the mysql module)
