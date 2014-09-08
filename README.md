# Migration::Worker

This gem is used to perform virtual machine template migration between sites.

## Installation

Update your system (as root):

    aptitude update
    aptitude upgrade

Install additional packages (as root):

    aptitude install g++ make autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

Install ruby and bundler (as root):

    mkdir /tmp/ruby
    pushd /tmp/ruby
    curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar xz
    pushd /tmp/ruby/ruby-2.1.2
    ./configure --disable-install-rdoc
    make
    make install
    gem install bundler --no-ri --no-rdoc
    popd
    popd

Install this software (as non-root):

    git clone https://github.com/paoolo/migration-worker.git /home/atmosphere/migration-worker
    cd /home/atmosphere/migration-worker
    cp /home/atmosphere/migration-worker/config.yml.example /home/atmosphere/migration-worker/config.yml
    nano /home/atmosphere/migration-worker/config.yml
    # set proper redis_url and name first row in queues with proper, unique name
    pushd /home/atmosphere/migration-worker
    bundle install --path vendor/bundle
    popd

Enable upstart for non-root user (as root):

    # modify /etc/dbus-1/system.d/Upstart.conf
    nano /etc/dbus-1/system.d/Upstart.conf

It should looks like this:

    <?xml version="1.0" encoding="UTF-8" ?>
    <!DOCTYPE busconfig PUBLIC
      "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
    
    <busconfig>
      <!-- Only the root user can own the Upstart name -->
      <policy user="root">
        <allow own="com.ubuntu.Upstart" />
      </policy>
    
      <!-- Allow any user to invoke all of the methods on Upstart, its jobs
           or their instances, and to get and set properties - since Upstart
           isolates commands by user. -->
      <policy context="default">
        <allow send_destination="com.ubuntu.Upstart"
           send_interface="org.freedesktop.DBus.Introspectable" />
        <allow send_destination="com.ubuntu.Upstart"
           send_interface="org.freedesktop.DBus.Properties" />
        <allow send_destination="com.ubuntu.Upstart"
           send_interface="com.ubuntu.Upstart0_6" />
        <allow send_destination="com.ubuntu.Upstart"
           send_interface="com.ubuntu.Upstart0_6.Job" />
        <allow send_destination="com.ubuntu.Upstart"
           send_interface="com.ubuntu.Upstart0_6.Instance" />
      </policy>
    </busconfig>

Install upstart scripts (as non-root, inside migration-worker directory):

    mkdir -p /home/atmosphere/.init
    cp -i /home/atmosphere/migration-worker/init/*.conf /home/atmosphere/.init/
    nano /home/atmosphere/.init/migration.conf
    # set proper directory for migration-worker/log
    nano /home/atmosphere/.init/migration-worker-1.conf
    # set proper directory for migration-worker/ and migration-worker/log/
    cat >> /home/atmosphere/.bash_profile <<EOL
    if [ ! -f /var/run/user/\$(id -u)/upstart/sessions/*.session ]
    then
        /sbin/init --user --confdir \${HOME}/.init &
    fi
    
    if [ -f /var/run/user/\$(id -u)/upstart/sessions/*.session ]
    then
       export \$(cat /var/run/user/\$(id -u)/upstart/sessions/*.session)
    fi
    EOL
    # you need to re-login to apply changes in /home/atmosphere/.bash_profile

## Usage

First time run (as non-root, inside migration-worker directory):

    pushd /home/atmosphere/migration-worker
    bundle exec ./bin/run
    popd

Normal run (as non-root):

    start migration

Stop (as non-root):

    stop migration

## Contributing

1. Fork it!
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new *Pull Request*
