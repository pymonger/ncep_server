ncep_server
===========

Puppet module to install Hyrax (OPeNDAP) server on Ubuntu 12.04.
It includes HDF4, HDF5, NetCDF4, numpy, matplotlib, basemap,
scipy, and various other scientific packages.

Installation
------------
Copy ncep_server to /etc/puppet/modules then run:

puppet apply -e "include ncep_server"
