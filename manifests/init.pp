define pip($ensure = installed) {
  case $ensure {
    installed: {
      exec { "pip install $name":
        path => "/usr/local/bin:/usr/bin:/bin",
      }
    }
    latest: {
      exec { "pip install --upgrade $name":
        path => "/usr/local/bin:/usr/bin:/bin",
      }
    }
    default: {
      exec { "pip install $name==$ensure":
        path => "/usr/local/bin:/usr/bin:/bin",
      }
    }
  }
}

class ncep_server {

  package { 'libfreetype6-dev':
    ensure => present,
  }

  package { 'libpng12-dev':
    ensure => present,
  }

  package { 'python': 
    ensure => present,
  }

  package { 'python-dev': 
    ensure => present,
  }

  package { 'python-virtualenv': 
    ensure => present,
  }

  package { 'python-pip': 
    ensure => present,
  }

  package { 'python-numpy':
    ensure => installed,
  }

  package { 'python-matplotlib':
    ensure => installed,
  }

  package { 'python-matplotlib-data':
    ensure => installed,
  }

  package { 'python-mpltoolkits.basemap':
    ensure => installed,
  }

  package { 'python-mpltoolkits.basemap-data':
    ensure => installed,
  }

  package { 'python-tables':
    ensure => installed,
  }

  package { 'python-numexpr':
    ensure => installed,
  }

  package { 'python-scipy':
    ensure => installed,
  }

  package { 'zlib':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/zlib_1.2.7-1_amd64.deb",
  }

  package { 'hdf5':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5_1.8.9-1_amd64.deb",
    require  => Package['zlib'],
  }

  package { 'netcdf':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/netcdf_4.1.3-1_amd64.deb",
    require  => Package['hdf5'],
  }

  pip { 'netcdf4':
    ensure  => installed,
    require => [Package['python-numpy'], Package['netcdf']],
  }
  
  exec { '/sbin/ldconfig': 
    refreshonly => true, 
    alias       => 'ldconfig', 
    subscribe   => Package['netcdf'],
  } 
  
  define inputrc ($user = $title, $home) {
    file { "$home/.inputrc":
      ensure  => file,
      mode    => 0644,
      owner   => $user,
      content => '#"\e[5~": history-search-backward #for "page up" key
  #"\e[6~": history-search-forward  #for "page down" key
  "\e[A": history-search-backward
  "\e[B": history-search-forward
  ',
    }
  }
  
  inputrc { 'root':
    home => '/root',
  }
  
  inputrc { 'sflops':
    home    => '/home/sflops',
    require => User['sflops'],
  }

  user { 'sflops':
    ensure     => present,
    uid        => '1000',
    gid        => '1000',
    shell      => '/bin/bash',
    home       => '/home/sflops',
    managehome => true,
  }

}
