# ssh_username=$(echo "$1")
puppet apply /vagrant/puppet/manifest.pp --modulepath=/vagrant/puppet/modules/ --hiera_config=/vagrant/puppet/hiera.yaml