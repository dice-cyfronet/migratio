# Migratio

This gem is used to perform virtual machine template migration between sites.

## Requirements

**This project is designed for Linux operating systems.**

- Linux (tested on Ubuntu)
- Ruby 2.0+
- Redis (can be installed on separate server)

## Packages / Dependencies

Update your system (as root):

    aptitude update
    aptitude upgrade

Install additional packages (as root):

    aptitude install g++ make autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

Install ``ruby`` and ``bundler`` (as root):

    mkdir /tmp/ruby
    pushd /tmp/ruby
    curl --progress http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz | tar xz
    pushd /tmp/ruby/ruby-2.1.2
    ./configure --disable-install-rdoc
    make
    make install
    gem install bundler --no-ri --no-rdoc
    popd
    popd

Install this software (as non-root):

    git clone https://github.com/dice-cyfronet/migratio.git /home/atmosphere/migratio
    cd /home/atmosphere/migratio
    cp /home/atmosphere/migratio/config.yml.example /home/atmosphere/migratio/config.yml

Edit config file, set proper ``redis_url`` and name first row in queues with proper, unique name:

    nano /home/atmosphere/migratio/config.yml

Install gems:

    pushd /home/atmosphere/migratio
    bundle install --path vendor/bundle
    popd

Enable upstart for non-root user (as root):

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

Install upstart scripts (as non-root, inside migratio directory):

    mkdir -p /home/atmosphere/.init
    cp -i /home/atmosphere/migratio/support/upstart/*.conf /home/atmosphere/.init/

Set proper directory for ``migratio/`` and ``migratio/log/``:

    nano /home/atmosphere/.init/migration.conf
    nano /home/atmosphere/.init/migratio-1.conf

Update profile files (eg. ``.bash_profile``):

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

First time run (as non-root, inside ``migratio/`` directory):

    pushd /home/atmosphere/migratio
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
