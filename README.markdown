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

# Puppet Dashboard Face

The Puppet Dashboard Face requires that the cloud provisioner version 1.0.0 is installed
and in Ruby's loadpath (which can be set with the RUBYLIB environment variable)

To use the Puppet Dashboard Face:


* Ensure that you have Puppet 2.7.7 or greater installed.  This face MAY work on version 2.7.2 or later, but it's not been tested.
* Download or clone puppetlabs-dashboard to your Puppet modulepath (i.e. ~/.puppet/modules or /etc/puppet/modules)
* Download or clone [puppetlabs-cloud-provisioner](https://github.com/puppetlabs/puppetlabs-cloud-provisioner) (version 1.0.0 or later) to your Puppet modulepath
* Ensure that the guid and fog gems are installed

        gem install fog -v 1.0.0 --no-rdoc --no-ri && gem install guid --no-rdoc --no-ri
* Export your RUBYLIB environment variable to point to the lib directory in puppetlabs-cloud-provisioner and the site\_lib directory in puppetlabs-dashboard

        export RUBYLIB=/etc/puppet/modules/cloud-provisioner/lib:/etc/puppet/modules/puppetlabs-dashboard/site\_lib:$RUBYLIB
* Test the face and learn more about its usage

        puppet help dashboard

The ability to set parameters is only supported if
the Face is used programmatically:

  Puppet::Face[:dashboard, :current].create_node(:name => 'name', :parameters => {'param1' => value'})

# Feature Requests

* Sqlite support.
* Integration with Puppet module to set puppet.conf settings.
* Remove the need to set the MySQL root password (needs fixed in the mysql module)
