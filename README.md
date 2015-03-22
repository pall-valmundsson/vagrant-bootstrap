# vagrant-puppet-r10k-bootstrap
A vagrant puppet setup that supports module development using
[r10k](https://github.com/puppetlabs/r10k), hiera,
[envpuppet](https://puppetlabs.com/blog/use-envpuppet-test-multiple-puppet-versions),
facter overrides (via custom environment variables) and more.

####Table of Contents
1. [Use case](#use-case)
2. [Features](#features)
    * [r10k](#r10k)
    * [Local module override](#local-module-override)
    * [Hiera](#hiera)
    * [envpuppet](#envpuppet)
    * [Facter overrides](#facter-overrides)
3. [Usage](#usage)
4. [Configuration](#configuration)
5. [Copyright](#copyright)
6. [Credits](#credits)

## Use case
You need to be able to locally hack on roles, profiles or component
modules in an environment that closely resembles your deployed
environment. You might for example be working on a profile for a web
app and need access to your current apache or nginx profiles.

Assumptions:
* you have a r10k Puppetfile "control" repository
* you might also have some modules inside the "control" repository
* you might be using hiera
* you might be using envpuppet
* you might depend on environment specific facts

## Features

### r10k
Point your configuration to your local clone of the repository that contains
your Puppetfile and your currently checked out version will be installed into
the Vagrant VM.

If you have a subdirectory inside the r10k repo that contains extra modules
you need to configure that as well so puppet runs inside the VM will include
those modules as well.

If your Puppetfile includes git repositories that require SSH keys to clone
there is an option to mount `~/.ssh` into `/root/.ssh` in the VM so your
local users' keys are available to the provisioning user inside the VM.

### Local module override
If you're working on a module that's also deployed in your current environment
you can explicitly "override" them. It works by mounting the local clone of
the module into the VM and overwriting the module deployed by r10k. 

### Hiera
A generic `hiera.yaml` is included in the `puppet/` directory. Edit as needed
to match your environment. For most use cases this will not be required as
you will probably only need the `%{clientcert}` element of the hierarcy.

Currently `puppet/vagranthost.local.yaml` is linked into the hiera datadir.
Any hiera config needed should go that file.

### envpuppet
Envpuppet is a script supplied by PuppetLabs to make it easy to go back and
forth between versions of the base puppet components; puppet, hiera and facter.

Point your configuration to the root directory containing your local clones
of the components and they'll be used in the VM.

### Facter overrides
If you need some site specific facts that are not easily reproduced inside a
local Vagrant VM then edit `facter.override` and add them using the pattern
`export FACTER_<factname>=<factvalue>`.

The file is basically sourced in bash before puppet runs.

## Usage

1. Clone the vagrant-puppet-r10k-bootstrap repository.
2. Change `r10k-repo-path` in `config.yaml` to point to your clone with
your Puppetfile. Adjust `dist-module-directory` if needed.
3. Disable envpuppet support if you're not using it.
4. Edit `puppet/manifests/main.pp` to your liking.
5. Run `vagrant up`
6. Hack on modules
7. Run `vagrant provision` to rerun puppet on the VM


## Configuration
Edit `config.yaml`, `facter.override` and `puppet/vagranthost.local.yaml` to
your needs. There are comments inside the files and more info above.

####Copyright
Copyright 2014-2015, Pall Valmundsson

####Credits
Based heavily on [vagrant-puppet-librarian](https://github.com/mindreframer/vagrant-puppet-librarian).
