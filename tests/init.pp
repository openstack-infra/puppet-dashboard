node default {

  class {'dashboard':
    dashboard_ensure          => 'present',
    dashboard_user            => 'puppet-dashboard',
    dashboard_password        => 'changeme',
    dashboard_db              => 'dashboard_production',
    dashboard_charset         => 'utf8'
  }

}

