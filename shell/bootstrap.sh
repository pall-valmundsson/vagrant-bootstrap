#!/bin/sh
# Source: https://github.com/mindreframer/vagrant-puppet-librarian/blob/master/shell/bootstrap.sh

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR='/etc/puppet'

# NB: librarian-puppet might need git installed. If it is not already installed
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

# Link the Puppetfile into $PUPPET_DIR
# this keeps your Vagrant working directory clean of external modules
ln -sf /vagrant/puppet/Puppetfile $PUPPET_DIR/Puppetfile

if [ `gem query --local | grep r10k | wc -l` -eq 0 ]; then
  gem install r10k --no-ri --no-rdoc
  PUPPETFILE=$PUPPET_DIR/Puppetfile PUPPETFILE_DIR=$PUPPET_DIR/modules r10k puppetfile install
else
  PUPPETFILE=$PUPPET_DIR/Puppetfile PUPPETFILE_DIR=$PUPPET_DIR/modules r10k puppetfile install
fi

# now we run puppet
puppet apply -vt --modulepath=$PUPPET_DIR/modules:/vagrant/puppet/local_modules $PUPPET_DIR/manifests/main.pp
