# Puppet Dashboard Module

Gary Larizza <gary@puppetlabs.com>

This module manages and installs the Puppet Dashboard.

# Quick Start

To install the Puppet Dashboard and configure it with sane defaults, include the following in your site.pp file:

    node default {

		  class {'dashboard':
		    dashboard_ensure          => 'present',
		    dashboard_user            => 'puppet-dashboard',
		    dashboard_group 					=> 'puppet-dashboard',
		    dashboard_password        => 'changeme',
		    dashboard_db              => 'dashboard_production',
		    dashboard_charset         => 'utf8',
		    mysql_root_pw							=> 'REALLY_change_me',
		  }

		}

# Feature Requests

* Include the ability to run Puppet Dashboard under Passenger.
* Sqlite support.
* Integration with Puppet module to set puppet.conf settings.
* Remove the need to set the MySQL root password (needs fixed in the mysql module)
