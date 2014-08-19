class vagrantbootstrap {
    class{'vagrantbootstrap::repos': } ->
    class{'vagrantbootstrap::devenv': } ->
    class{'vagrantbootstrap::helpers': } ->
    Class['vagrantbootstrap']
}

class vagrantbootstrap::repos {
    class { 'epel': }
    #exec { 'yum -y update && touch /tmp/yum-updated':
    #    timeout => 0,
    #    unless => 'test -e /tmp/yum-updated',
    #}
}

class vagrantbootstrap::devenv {
    $rpmbuildrpms = [ 'mock', 'rpm-build', 'git' ]

    package { $rpmbuildrpms:
        ensure => present,
    }
}

class vagrantbootstrap::helpers {
    $puppet_dir = '/etc/puppet'
    $vagrant_puppet_dir = '/vagrant/puppet'

    file { '/usr/local/bin/runpuppet':
        content => "sudo puppet apply -vt --modulepath=${puppet_dir}/modules:${vagrant_puppet_dir}/local_modules:/vagrant/puppet/sitemodules ${vagrant_puppet_dir}/manifests/init.pp\n",
        mode => '0755',
    }

    file { '/usr/local/bin/runr10k':
        content => "PUPPETFILE=${puppet_dir}/Puppetfile PUPPETFILE_DIR=${puppet_dir}/modules r10k puppetfile install",
        mode => '0755',
    }
}
