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
    'libxml2-dev': ensure => installed;
    'uuid-dev': ensure => installed;
    'libhdf4-dev': ensure => installed;
    'libcurl4-openssl-dev': ensure => installed;
    'tomcat6': ensure => installed;
    'tomcat6-common': ensure => installed;
    'tomcat6-admin': ensure => installed;
    'tomcat6-docs': ensure => installed;
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

  package { 'hdf5':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5_1.8.9-1_amd64.deb",
    require  => [
                 Package['zlib'], Package['szip'], Package['libhdf4-dev'],
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
    source   => "/etc/puppet/modules/ncep_server/files/libdap_3.11.3-1_amd64.deb",
    require  => Package['netcdf'],
    notify   => Exec['ldconfig'],
  }

  file { '/etc/ld.so.conf.d/bes.conf':
    ensure  => file,
    mode    => 0644,
    content => '/usr/local/lib/bes\n',
    notify   => Exec['ldconfig'],
  }
    
  package { 'bes':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/bes_3.10.2-1_amd64.deb",
    require  => Package['libdap'],
    notify   => File['/etc/ld.so.conf.d/bes.conf'],
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

  package { 'freeform-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/freeform-handler_3.8.4-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  package { 'hdf4-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf4-handler_3.9.4-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  package { 'hdf5-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5-handler_2.0.0-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  package { 'fileout_netcdf':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/fileout-netcdf_1.1.2-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  package { 'gateway-module':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/gateway-module_1.1.0-1_amd64.deb",
    require  => [Package['dap-server'], Package['libcurl4-openssl-dev']],
    notify   => Exec['ldconfig'],
  }

  package { 'xml_data-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/xml-data-handler_1.0.2-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  package { 'csv-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/csv-handler_1.0.2-1_amd64.deb",
    require  => Package['dap-server'],
    notify   => Exec['ldconfig'],
  }

  file { '/etc/init.d/besctl':
    ensure  => file,
    mode    => 0755,
    source  => 'puppet:///modules/ncep_server/besctl',
    require => Package['bes'],
  }

  file { '/usr/local/etc/bes/bes.conf':
    ensure  => file,
    mode    => 0644,
    source  => 'puppet:///modules/ncep_server/bes.conf',
    require => Package['bes'],
  }
    
  file { '/usr/local/etc/bes/modules/dap.conf':
    ensure  => file,
    mode    => 0644,
    source  => 'puppet:///modules/ncep_server/dap.conf',
    require => Package['bes'],
  }
    
  file { ['/usr/local/var',
          '/usr/local/var/run',
          '/usr/local/var/run/bes']:
    ensure => directory,
    owner  => 'root',
    group  => 'gdgps',
    mode   => 0775,
  }

  service { 'besctl':
    ensure => running,
    enable => true,
    hasrestart => true,
    hasstatus => true,
    require => [
                Package['bes'], 
                File['/etc/init.d/besctl'], 
                File['/usr/local/etc/bes/bes.conf'],
                File['/usr/local/etc/bes/modules/dap.conf'],
                File['/usr/local/var/run/bes'],
               ],
  }

  file { 'opendap':
    path => '/var/lib/tomcat6/webapps/opendap.war',
    ensure => present,
    source => 'puppet:///modules/ncep_server/opendap.war',
    require => Package['tomcat6'],
  }

  file { ['/var/lib/tomcat6/content',
          '/var/lib/tomcat6/content/opendap',
          '/var/lib/tomcat6/content/opendap/logs']:
    ensure => directory,
    require => Package['tomcat6'],
  }

  service { 'tomcat6':
    ensure => running,
    enable => true,
    hasrestart => true,
    hasstatus => true,
    require => [
                File['opendap'],
                File['/var/lib/tomcat6/content/opendap/logs'],
               ],
  }

  file { '/var/lib/tomcat6/content/opendap/olfs.xml':
    ensure => link,
    target => '/var/lib/tomcat6/webapps/opendap/initialContent/olfs.xml',  
    require => Service['tomcat6'],
  }

  file { '/var/lib/tomcat6/content/opendap/catalog.xml':
    ensure => link,
    target => '/var/lib/tomcat6/webapps/opendap/initialContent/catalog.xml',  
    require => Service['tomcat6'],
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
