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

  package {
    'libfreetype6-dev': ensure => present;
    'libpng12-dev': ensure => present;
    'python': ensure => present;
    'python-dev': ensure => present;
    'python-virtualenv': ensure => present;
    'python-pip': ensure => present;
    'python-numpy': ensure => installed;
    'python-matplotlib': ensure => installed;
    'python-matplotlib-data': ensure => installed;
    'python-mpltoolkits.basemap': ensure => installed;
    'python-mpltoolkits.basemap-data': ensure => installed;
    'python-tables': ensure => installed;
    'python-numexpr': ensure => installed;
    'python-scipy': ensure => installed;
    'libreadline-dev': ensure => installed;
    'fort77': ensure => installed;
    'gfortran': ensure => installed;
    'bison': ensure => installed;
    'flex': ensure => installed;
  }

  exec { 'ldconfig': 
    command     => '/sbin/ldconfig',
    refreshonly => true, 
  } 
  
  package { 'zlib':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/zlib_1.2.7-1_amd64.deb",
    notify   => Exec['ldconfig'],
  }

  package { 'szip':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/szip_2.1-1_amd64.deb",
    notify   => Exec['ldconfig'],
  }

  package { 'hdf4':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf_4.2.7-1_amd64.deb",
    require  => [
                 Package['fort77'], Package['gfortran'], Package['bison'],
                 Package['flex'], Package['szip'],
                ],
    notify   => Exec['ldconfig'],
  }

  package { 'hdf5':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5_1.8.9-1_amd64.deb",
    require  => [
                 Package['zlib'], Package['szip'], Package['hdf4'],
                ],
    notify   => Exec['ldconfig'],
  }

  package { 'netcdf':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/netcdf_4.2.1-1_amd64.deb",
    require  => Package['hdf5'],
    notify   => Exec['ldconfig'],
  }

  pip { 'netcdf4':
    ensure  => installed,
    require => [Package['python-numpy'], Package['netcdf']],
  }
  
  package { 'libdap':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/libdap-3.11.3-1_amd64.deb",
    require  => Package['netcdf'],
    notify   => Exec['ldconfig'],
  }

  file { 'ld-bes.conf':
    path    => '/etc/ld.so.conf.d/bes.conf',
    ensure  => file,
    mode    => 0644,
    content => '/usr/local/lib/bes\n',
    notify   => Exec['ldconfig'],
  }
    
  package { 'bes':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/bes-3.10.2-1_amd64.deb",
    require  => Package['libdap'],
    notify   => File['ld-bes.conf'],
  }

  package { 'dap-server':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/dap-server_4.1.2-1_amd64.deb",
    require  => Package['bes'],
    notify   => Exec['ldconfig'],
  }

  package { 'netcdf-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/netcdf-handler_3.10.1-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
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

  inputrc { 'gdgps':
    home    => '/home/gdgps',
    require => User['gdgps'],
  }

  user { 'sflops':
    ensure     => present,
    uid        => '1000',
    gid        => '1000',
    shell      => '/bin/bash',
    home       => '/home/sflops',
    managehome => true,
  }

  user { 'gdgps':
    ensure     => present,
    uid        => '1001',
    gid        => '1001',
    shell      => '/bin/bash',
    home       => '/home/gdgps',
    managehome => true,
    require    => Group['gdgps'],
  }

  group { 'gdgps':
    ensure     => present,
    gid        => '1001',
  }

}
