# Migration::Worker

This gem is used to perform virtual machine template migration between sites.

## Installation

Update your system (as root):

    aptitude update
    aptitude upgrade

Install additional packages (as root):

    aptitude install g++ make autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

Install ruby and bundler (as root):

    mkdir /tmp/ruby && cd /tmp/ruby
    curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar xz
    cd ruby-2.1.2
    ./configure --disable-install-rdoc
    make
    make install
    gem install bundler --no-ri --no-rdoc

Install this software (as non-root):

    git clone https://github.com/paoolo/migration-worker.git
    cd migration-worker
    rake gem
    rake configure

## Usage

First time run (as non-root, inside migration-worker directory):

    rake rundevel

Normal run (as non-root, inside migration-worker directory):

    rake run

Stop, clean iptables rules, purge database and settings (as non-root, inside migration-worker directory):

    rake stop
    rake clean
    rake purge

## Contributing

1. Fork it!
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new *Pull Request*
