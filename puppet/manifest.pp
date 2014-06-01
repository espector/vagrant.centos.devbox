define print() {
   notice("The value is: '${name}'")
}

if $server_values == undef {
  $server_values = hiera('server', false)
} if $vm_values == undef {
  $vm_values = hiera($::vm_target_key, false)
}

$vagrant_local = hiera('vagrantfile-local',  false)
$ssh_user = $vagrant_local['ssh']['username']

node default {
	Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
	group { 'puppet':   ensure => present }
	group { 'www-data': ensure => present }
	group { 'www-user': ensure => present }

	user { $ssh_user:
	  shell   => '/bin/bash',
	  home    => "/home/${ssh_user}",
	  ensure  => present,
	  groups  => ['www-data', 'www-user'],
	  require => [Group['www-data'], Group['www-user']]
	}

	# user { ['apache', 'nginx', 'httpd', 'www-data']:
	#   shell  => '/bin/bash',
	#   ensure => present,
	#   groups => 'www-data',
	#   require => Group['www-data']
	# }

	# copy dot files to ssh user's home directory
	exec { 'dotfiles':
	  cwd     => "/home/$ssh_user",
	  command => "cp -r /vagrant/files/dot/.[a-zA-Z0-9]* /home/$ssh_user/ \
	              && chown -R ${::ssh_username} /home/${::ssh_username}/.[a-zA-Z0-9]* \
	              && cp -r /vagrant/files/dot/.[a-zA-Z0-9]* /root/",
	  onlyif  => 'test -d /vagrant/files/dot',
	  returns => [0, 1],
	  require => User[$ssh_user]
	}

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
    # class { 'yum::repo::remi_php55': } #this is needed for php 5.5


	# php::module { "imagick": 
	# 	#redhat module prefix
	# 	module_prefix => 'php-pecl-'
	# }

    ##setup php
	class { 'php': 
		package => 'php54-php',
		service => 'httpd',
	}

	#install php cli
	package { [
        "php54-php-cli",
        ]:
    	ensure => latest,
	}

	file { '/usr/bin/php':
	   ensure => 'link',
	   target => '/opt/rh/php54/root/usr/bin/php',
	}

	#setup apache php5 conf for apache
	file { '/etc/httpd/conf.d/php5.conf':
	  ensure  => file,
	  content => "AddHandler php5-script .php\nAddType text/html .php\nDirectoryIndex index.php",
	}

	#setup composer
	class { 'composer':
		target_dir      => '/usr/local/bin',
		composer_file   => 'composer',
		download_method => 'curl',
		logoutput       => false,
		tmp_path        => '/tmp',
		php_package     => "php54-php",
		curl_package    => 'curl',
		suhosin_enabled => false,
    }

	#setup drush from source
	class {'drush::git::drush':
		git_branch => '8.x-6.x',
		git_repo => 'http://git.drupal.org/project/drush.git',
		update     => true,
	}

    #enable apache
	class { 'apache':
		mpm_module => 'prefork',
    }

    apache::mod { 'php': 
    	id => 'php5_module',
    	lib => 'libphp54-php5.so',
    }
    # apache::mod { 'ssl': }
    # apache::mod { 'rewrite': }
    # apache::mod { 'vhost_alias': }

	apache::vhost { 'first.example.com':
	 	port    => '80',
		docroot => '/var/www/first',
		# options => ['Indexes','FollowSymLinks','MultiViews'],
		# directories => [ 
  #       { path        => '/var/www/first',
  #         addhandlers => [{ handler => 'php5-script', extensions => ['.php']},
  #         		{ handler => 'text/html', extensions => ['.php']}
  #         	],
  #       	}, 
  #     	],
      	# custom_fragment => "AddHandler php5-script .php\AddType text/html .php"
	}
}