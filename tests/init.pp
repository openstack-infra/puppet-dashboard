node default {

  class {'dashboard':
    dashboard_ensure          => 'present',
    dashboard_user            => 'dashboard',
    dashboard_password        => 'changeme',
    dashboard_db              => 'dashboard_db',
    dashboard_charset         => 'utf8',
  }

}

