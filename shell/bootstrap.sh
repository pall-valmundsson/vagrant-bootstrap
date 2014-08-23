#!/bin/sh
# Source: https://github.com/mindreframer/vagrant-puppet-librarian/blob/master/shell/bootstrap.sh

# Directory in which r10k should manage its modules directory
PUPPET_DIR='/etc/puppet'

# NB: r10k might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum
GIT=/usr/bin/git
APT_GET=/usr/bin/apt-get
YUM=/usr/bin/yum
if [ ! -x $GIT ]; then
    if [ -x $YUM ]; then
        yum -q -y install git
    elif [ -x $APT_GET ]; then
        apt-get -q -y install git
    else
        echo "No package installer available. You may need to install git manually."
    fi
fi

# Link the sitemodule Puppetfile into $PUPPET_DIR
ln -sf /vagrant/puppet/r10kmodules/Puppetfile $PUPPET_DIR/Puppetfile

# If hiera is enabled, link hiera.yaml
if [ -d "/vagrant/puppet/hiera" ]; then
    echo "Synchronizing hiera data..."
    ln -sf /vagrant/puppet/hiera.yaml $PUPPET_DIR/hiera.yaml
    ln -sf /vagrant/puppet/hiera.yaml /etc/hiera.yaml
    rm -rf /etc/puppet/hiera
    rsync -a /vagrant/puppet/hiera /etc/puppet/
    ln -sf /vagrant/puppet/vagranthost.local.yaml /etc/puppet/hiera/vagranthost.local.yaml
fi

# Install r10k
echo "Installing r10k..."
if [ `gem query --local | grep r10k | wc -l` -eq 0 ]; then
  gem install r10k --no-ri --no-rdoc
fi

# Make r10k install all the modules
echo "Running r10k..."
PUPPETFILE=$PUPPET_DIR/Puppetfile PUPPETFILE_DIR=$PUPPET_DIR/modules r10k puppetfile install

# Remove the local-modules from the Puppetfile deployed modulepath, if they're managed by that
for module in /vagrant/puppet/local_modules/*
do
    module_name=$(basename ${module})
    module_path="${PUPPET_DIR}/modules/${module_name}"
    if [ -d "${module_path}" ]; then
        echo "   Removing ${module} from Puppetfile deployed modules..."
        rm -rf "${module_path}"
    fi
done

# And now we run puppet
puppet apply -vt --modulepath=$PUPPET_DIR/modules:/vagrant/puppet/local_modules:/vagrant/puppet/sitemodules/$DIST_DIR $PUPPET_DIR/manifests/main.pp
