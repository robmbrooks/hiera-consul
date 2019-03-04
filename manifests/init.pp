class { 'hiera_consul':
    package { 'backports':
      ensure   => present,
      provider => puppetserver_gem,
    }

    package { 'diplomat':
      ensure   => present,
      provider => puppetserver_gem,
    }
}
