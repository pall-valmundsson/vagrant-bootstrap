#!/bin/sh

echo "ENVPUPPET=${ENVPUPPET}"
echo "DIST_DIR=${DIST_DIR}"

# Source: http://stackoverflow.com/a/21189044
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Enable envpuppet?
if [ "${ENVPUPPET}" == "true" ]; then
    # Enable in bash profiles
    ln -sf /vagrant/shell/envpuppet.sh /etc/profile.d/envpuppet.sh
    # ... and for the current shell
    source /etc/profile.d/envpuppet.sh
fi

# Puppet component versions
echo "Puppet agent version: $(puppet agent --version)"
echo "Hiera version: $(hiera --version)"
echo "Facter version: $(facter --version)"

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

    # Find the hiera datadir for yaml
    eval $(parse_yaml /vagrant/puppet/hiera.yaml)
    echo "YAML datadir: ${yaml__datadir}"
    ln -sf /vagrant/puppet/vagranthost.local.yaml ${yaml__datadir}/vagranthost.local.yaml
fi

# Install r10k
echo "Installing r10k..."
if [ `gem query --local | grep r10k | wc -l` -eq 0 ]; then
  if [ "$(ruby -e 'print RUBY_VERSION')" == '1.8.7' ]; then
    gem install r10k --version '~>1.5' --no-ri --no-rdoc
  else
    gem install r10k --no-ri --no-rdoc
  fi
fi

# Make r10k install all the modules
echo "Running r10k..."
PATH=$PATH:/usr/local/bin PUPPETFILE=$PUPPET_DIR/Puppetfile PUPPETFILE_DIR=$PUPPET_DIR/modules r10k puppetfile install -v

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

# Load facter overrides
if [ -f "/vagrant/facter.override" ]; then
    echo "Loading facter.override..."
    source /vagrant/facter.override
fi

env

# And now we run puppet
puppet apply -vt --modulepath=$PUPPET_DIR/modules:/vagrant/puppet/local_modules:/vagrant/puppet/r10kmodules/$DIST_DIR $PUPPET_DIR/manifests/main.pp
