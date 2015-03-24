# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

Vagrant.configure("2") do |config|
  config.vm.box = "puppetlabs/centos-6.5-64-puppet"

  # Uncomment to enable bridged interface
  #config.vm.network :public_network

  config.vm.hostname = "vagranthost.local"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder "puppet/manifests", "/etc/puppet/manifests"

  yaml_config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))

  if yaml_config['local-modules']
    yaml_config['local-modules'].each do |localmod|
      config.vm.synced_folder localmod['local-path'], "/vagrant/puppet/local_modules/#{localmod['module-name']}"
    end
  end
  if yaml_config['hiera']['enabled']
    config.vm.synced_folder yaml_config['hiera']['repo-path'], "/vagrant/puppet/hiera"
  end
  if yaml_config['envpuppet']['enabled']
    config.vm.synced_folder yaml_config['envpuppet']['repos-base-path'], "/puppetlabs"
  end
  config.vm.synced_folder yaml_config['r10k-repo-path'], "/vagrant/puppet/r10kmodules"

  if yaml_config['sync-ssh-config']
    config.vm.synced_folder "~/.ssh", "/root/.ssh", :owner => "root", :group => "root", :mount_options => ["ro"]
  end

  # Shell provisioning to bootstrap r10k and puppet
  # bootstrap.sh uses the DISTDIR variable to append the modules
  # from the r10k repo to the modulepath of the puppet run
  config.vm.provision :shell, :inline => <<-EOS
    DIST_DIR=#{yaml_config['dist-module-directory']} ENVPUPPET=#{yaml_config['envpuppet']['enabled']} /vagrant/shell/bootstrap.sh
  EOS

end
