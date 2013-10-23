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
    $puppet_dir = '/vagrant/puppet'

    file { '/usr/local/bin/runpuppet':
        content => "sudo puppet apply -vv  --modulepath=${puppet_dir}/modules/ $puppet_dir/manifests/init.pp\n",
        mode => '0755',
    }

    file { '/usr/local/bin/runlibrarian':
        content => "cd ${puppet_dir} &&  sudo librarian-puppet update \n",
        mode => '0755',
    }
}
