node 'centos65' {
	Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
	group { 'puppet':   ensure => present }
	group { 'www-data': ensure => present }
	group { 'www-user': ensure => present }

	# user { $::ssh_username:
	#   shell   => '/bin/bash',
	#   home    => "/home/${::ssh_username}",
	#   ensure  => present,
	#   groups  => ['www-data', 'www-user'],
	#   require => [Group['www-data'], Group['www-user']]
	# }

	# user { ['apache', 'nginx', 'httpd', 'www-data']:
	#   shell  => '/bin/bash',
	#   ensure => present,
	#   groups => 'www-data',
	#   require => Group['www-data']
	# }

	if $php_values == undef {
	  $php_values = hiera('php', false)
	} if $apache_values == undef {
	  $apache_values = hiera('apache', false)
	} if $nginx_values == undef {
	  $nginx_values = hiera('nginx', false)
	}

	#enable php
	class { 'yum': extrarepo => ['epel'] }
    class { 'yum::repo::rpmforge': }
    class { 'yum::repo::repoforgeextras': }
	class { 'yum::repo::remi': }
    class { 'yum::repo::remi_php55': } #this is needed for php 5.5

	class { 'php': 
		#make sure to get version 5.5 from remi repo
		version => '5.5.12-1.el6.remi',
		service => 'httpd',
	}

	php::module { "imagick": 
		#redhat module prefix
		module_prefix => 'php-pecl-'
	}


	#enable apache
	 class { 'apache':
      # default_mods        => false,
      mpm_module => 'prefork',
      # default_confd_files => false,
    }

    # apache::mod { 'prefork': }
    apache::mod { 'php': 
    	lib => 'libphp5.so',
    }
    apache::mod { 'ssl': }
    # apache::mod { 'rewrite': }
    # apache::mod { 'vhost_alias': }
    


	apache::vhost { 'first.example.com':
	 	port    => '80',
		docroot => '/var/www/first',
	}
}