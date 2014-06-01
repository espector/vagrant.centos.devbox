#!/bin/bash
VAGRANT_CORE_FOLDER=$(echo "$1")
ssh_username=$(echo "$2")

OS=$(/bin/bash "${VAGRANT_CORE_FOLDER}/provision/os-detect.sh" ID)
CODENAME=$(/bin/bash "${VAGRANT_CORE_FOLDER}/provision/os-detect.sh" CODENAME)

cat "${VAGRANT_CORE_FOLDER}/provision/linux.txt"

if [[ ! -d '/.puphpet-stuff' ]]; then
    mkdir '/.puphpet-stuff'
    echo 'Created directory /.puphpet-stuff'
fi

touch '/.puphpet-stuff/vagrant-core-folder.txt'
echo "${VAGRANT_CORE_FOLDER}" > '/.puphpet-stuff/vagrant-core-folder.txt'

if [[ ! -f '/.puphpet-stuff/initial-setup-base-packages' ]]; then
	if [[ "${OS}" == 'centos' ]]; then
        echo 'Running initial-setup yum update'
        perl -p -i -e 's@enabled=1@enabled=0@gi' /etc/yum/pluginconf.d/fastestmirror.conf 
        perl -p -i -e 's@#baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/@baseurl=http://mirror.rackspace.com/CentOS//\$releasever/os/\$basearch/\nenabled=1@gi' /etc/yum.repos.d/CentOS-Base.repo
        perl -p -i -e 's@#baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/@baseurl=http://mirror.rackspace.com/CentOS//\$releasever/updates/\$basearch/\nenabled=1@gi' /etc/yum.repos.d/CentOS-Base.repo
        perl -p -i -e 's@#baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/@baseurl=http://mirror.rackspace.com/CentOS//\$releasever/extras/\$basearch/\nenabled=1@gi' /etc/yum.repos.d/CentOS-Base.repo

        yum -y --nogpgcheck install 'http://www.elrepo.org/elrepo-release-6-6.el6.elrepo.noarch.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm' >/dev/null
        yum -y install centos-release-SCL >/dev/null
        yum clean all >/dev/null
        yum -y check-update >/dev/null
        echo 'Finished running initial-setup yum update'

        echo 'Installing wget'
		yum install wget -y >/dev/null

        echo 'Installing git'
        yum -y install git >/dev/null
        echo 'Finished installing git'

        echo 'Updating to Ruby 2.1.2'
        yum remove ruby 2>&1

		#article - https://www.digitalocean.com/community/articles/how-to-install-ruby-2-1-0-on-centos-6-5-using-rvm
		curl -L get.rvm.io | bash -s stable 2>&1
		source /etc/profile.d/rvm.sh 2>&1
		rvm reload 2>&1
		rvm install 2.1.2 2>&1
		rvm use 2.1.2 --default 2>&1
		gem update --system 2>&1
        gem install haml 2>&1

        #installing ruby puppet dependencies
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/products/x86_64/hiera-1.3.2-1.el6.noarch.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/products/x86_64/facter-1.7.5-1.el6.x86_64.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/dependencies/x86_64/rubygem-json-1.5.5-1.el6.x86_64.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/dependencies/x86_64/ruby-json-1.5.5-1.el6.x86_64.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/dependencies/x86_64/ruby-shadow-2.2.0-2.el6.x86_64.rpm' >/dev/null
        yum -y --nogpgcheck install 'https://yum.puppetlabs.com/el/6/dependencies/x86_64/ruby-augeas-0.4.1-3.el6.x86_64.rpm' >/dev/null
        echo 'Finished updating to Ruby 2.1.2'

        echo 'Installing basic development tools (CentOS)'
        yum -y groupinstall 'Development Tools' >/dev/null
        echo 'Finished installing basic development tools (CentOS)'

        echo 'Installing mlocate'
        yum -y install mlocate >/dev/null
        updatedb 2>&1
        echo 'Finished installing mlocate'

        echo 'Installing Puppet'
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm >/dev/null
        yum -y --nogpgcheck install puppet >/dev/null
        yum versionlock puppet >/dev/null
        PUPPET_VERSION=$(puppet help | grep 'Puppet v')
        echo "Finished installing/updating puppet to version: ${PUPPET_VERSION}"

        # echo 'Running Puppet'
        # puppet apply /vagrant/puppet/manifest.pp --modulepath=/vagrant/puppet/modules/ --hiera_config=/vagrant/puppet/hiera.yaml 
        # echo 'Finished running Puppet'

        # echo 'Installing r10k'
        # gem install r10k >/dev/null 2>&1
        # echo 'Finished installing r10k'

        touch '/.puphpet-stuff/initial-setup-base-packages'
    fi
fi