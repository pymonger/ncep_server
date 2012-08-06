#####################################################
# pip provider
#####################################################

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


#####################################################
# .inputrc provider
#####################################################

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
  

#####################################################
# require apt-get update before adding packages by
# adding this class to the "pre" stage (see bottom)
#####################################################

class apt {
  exec { "apt-update":
    command => "/usr/bin/apt-get update"
  }
}


#####################################################
# ncep_server class
#####################################################

class ncep_server {

  #####################################################
  # create groups and users
  #####################################################
  $user = 'ncep'
  $group = 'ncep'

  group { $group:
    ensure     => present,
    gid        => '1002',
  }

  user { $user:
    ensure     => present,
    uid        => '1002',
    gid        => '1002',
    shell      => '/bin/bash',
    home       => "/home/$user",
    managehome => true,
    require    => Group[$group],
  }


  #####################################################
  # add .inputrc to users' home
  #####################################################

  inputrc { 'root':
    home => '/root',
  }
  
  inputrc { $user:
    home    => "/home/$user",
    require => User[$user],
  }


  #####################################################
  # install packages
  #####################################################

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
    'libblas-dev': ensure => installed;
    'liblapack-dev': ensure => installed;
    'libxslt1-dev': ensure => installed;
    'subversion': ensure => installed;
    'augeas-tools': ensure => installed;
    'curl': ensure => installed;
  }


  #####################################################
  # refresh ld cache
  #####################################################

  exec { 'ldconfig': 
    command     => '/sbin/ldconfig',
    refreshonly => true, 
  } 
  

  #####################################################
  # install home baked packages for HDF5 and NetCDF4
  #####################################################

  package { 'zlib':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/zlib_1.2.7-1_${architecture}.deb",
    notify   => Exec['ldconfig'],
  }

  package { 'szip':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/szip_2.1-1_${architecture}.deb",
    notify   => Exec['ldconfig'],
  }

  package { 'hdf5':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5_1.8.9-1_${architecture}.deb",
    require  => [
                 Package['zlib'], Package['szip'], Package['libhdf4-dev'],
                ],
    notify   => Exec['ldconfig'],
  }

  package { 'netcdf':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/netcdf_4.2.1-1_${architecture}.deb",
    require  => Package['hdf5'],
    notify   => Exec['ldconfig'],
  }


  #####################################################
  # use pip to install NetCDF4 python module
  #####################################################

  pip { 'netcdf4':
    ensure  => installed,
    require => [Package['python-numpy'], Package['netcdf']],
  }
  

  #####################################################
  # install home baked packages and configuration for 
  # BES and OPeNDAP handlers
  #####################################################

  package { 'libdap':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/libdap_3.11.3-1_${architecture}.deb",
    require  => Package['netcdf'],
  }

  package { 'bes':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/bes_3.10.2-1_${architecture}.deb",
    require  => Package['libdap'],
  }

  package { 'dap-server':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/dap-server_4.1.2-1_${architecture}.deb",
    require  => Package['bes'],
  }

  package { 'netcdf-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/netcdf-handler_3.10.1-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'freeform-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/freeform-handler_3.8.4-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'hdf4-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf4-handler_3.9.4-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'hdf5-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/hdf5-handler_2.0.0-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'fileout_netcdf':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/fileout-netcdf_1.1.2-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'xml_data-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/xml-data-handler_1.0.2-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  package { 'csv-handler':
    provider => dpkg,
    ensure   => present,
    source   => "/etc/puppet/modules/ncep_server/files/csv-handler_1.0.2-1_${architecture}.deb",
    require  => Package['dap-server'],
  }

  #####################################################
  # create ld conf file for /usr/local/lib/bes  
  # and refresh cache
  #####################################################

  file { '/etc/ld.so.conf.d/bes.conf':
    ensure  => file,
    mode    => 0644,
    content => '/usr/local/lib/bes\n',
    require => [
                Package['netcdf-handler'],
                Package['freeform-handler'],
                Package['hdf4-handler'],
                Package['hdf5-handler'],
                Package['fileout_netcdf'],
                Package['gateway-module'],
                Package['xml_data-handler'],
                Package['csv-handler'],
               ],
    notify  => Exec['ldconfig'],
  }
    

  #####################################################
  # install BES startup script and custom configs
  #####################################################

  file { '/etc/init.d/besctl':
    ensure  => file,
    mode    => 0755,
    source  => 'puppet:///modules/ncep_server/besctl',
    require => [
                Package['bes'],
                File['/etc/ld.so.conf.d/bes.conf'],
               ]
  }

  file { '/usr/local/etc/bes/bes.conf':
    ensure  => file,
    mode    => 0644,
    source  => 'puppet:///modules/ncep_server/bes.conf',
    require => File['/etc/init.d/besctl'],
  }
    
  file { '/usr/local/etc/bes/modules/dap.conf':
    ensure  => file,
    mode    => 0644,
    source  => 'puppet:///modules/ncep_server/dap.conf',
    require => File['/usr/local/etc/bes/bes.conf'],
  }
    

  #####################################################
  # create directories need by BES with proper perms
  #####################################################

  file { ['/usr/local/var',
          '/usr/local/var/run',
          '/usr/local/var/run/bes']:
    ensure  => directory,
    owner   => 'root',
    group   => $group,
    mode    => 0775,
    require => File['/usr/local/etc/bes/modules/dap.conf'],
  }


  #####################################################
  # ensure BES service starts
  #####################################################

  service { 'besctl':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => File['/usr/local/var/run/bes'],
  }

  #####################################################
  # ensure directories exist for opendap WAR and 
  # install opendap WAR to tomcat's webapps
  #####################################################

  file { ['/var/lib/tomcat6/content',
          '/var/lib/tomcat6/content/opendap',
          '/var/lib/tomcat6/content/opendap/logs']:
    ensure => directory,
    require => Package['tomcat6'],
  }

  file { '/var/lib/tomcat6/webapps/opendap.war':
    ensure => present,
    source => 'puppet:///modules/ncep_server/opendap.war',
    require => [
                Package['tomcat6'],
                Service['besctl'],
                File['/var/lib/tomcat6/content/opendap/logs'],
               ],
  }


  #####################################################
  # ensure tomcat service starts
  #####################################################

  service { 'tomcat6':
    ensure => running,
    enable => true,
    hasrestart => true,
    hasstatus => true,
    require => File['/var/lib/tomcat6/webapps/opendap.war'],
  }


  #####################################################
  # ensure various hyrax configurations are soft-linked
  #####################################################

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

  #####################################################
  # use pip to install supervisor
  #####################################################

  pip { 'supervisor':
    ensure  => installed,
  }

  #####################################################
  # mount VM shared folders
  #####################################################

  file { ['/data1',
          '/data']:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
  }

  mount { '/data1':
    ensure  => mounted,
    device  => ".host:/data1",
    atboot  => true,
    fstype  => "vmhgfs",
    options => "defaults",
    require => File["/data1"],
  }

  mount { '/data':
    ensure  => mounted,
    device  => ".host:/data",
    atboot  => true,
    fstype  => "vmhgfs",
    options => "defaults",
    require => File["/data"],
  }

}


#####################################################
# set stages
#####################################################

node 'default' {
  # define stages
  stage {
    'pre' : ;
    'post': ;
  }

  # specify stage that each class belongs to;
  # if not specified, they belong to Stage[main]
  class {
    'apt':         stage => 'pre';
  }

  # stage order
  Stage['pre'] -> Stage[main] -> Stage['post']
}
