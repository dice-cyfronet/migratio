# Migratio

This gem is used to perform virtual machine template migration between sites.

## Requirements

**This project is designed for Linux operating systems.**

- Linux (tested on Ubuntu)
- Ruby 2.0+
- Redis (can be installed on separate server)
- OpenStack (with `nova` commands available for user who runs `migratio`)
- Amazon EC2 CLI Tools (with `ec2-*` commands available for user who runs `migratio`, needs: Java Runtime Environment)
- AWS CLI Tools (with `aws` command, needs: python and pip)

## Packages / Dependencies

Update your system (as root):

    aptitude update
    aptitude upgrade

Install additional packages (as root):

    aptitude install g++ make autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

Install `ruby` and `bundler` (as root):

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

Set proper directory for `migratio/` and `migratio/log/`:

    nano /home/atmosphere/.init/migratio.conf
    nano /home/atmosphere/.init/migratio-worker-1.conf

Update profile files (eg. `.bash_profile`):

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

### Amazon EC2 CLI Tools

 - Download Amazon EC2 CLI Tools:

    wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip

- Unzip downloaded archive.
- Copy all executable files (unix scripts) from `bin/` to `/usr/bin`.
- Copy all libraries (jars) from `lib/` to `/usr/lib`.
- Add to `/etc/environment` following lines:

    EC2_HOME=/usr
    JAVA_HOME=/usr/lib/jvm/default-java

### AWS CLI Tools

 - Install `awscli` as `root`

    pip install awscli

 - Configure `awscli` for user who run `migratio`

    aws configure

## Configuration

Edit config file. Set proper `redis_url` and `name`:

    nano /home/atmosphere/migratio/config.yml

`name` must be identical with ComputeSite `site_id` property. Eg. for ComputeSite with `name` `Local` and `site_id` `local`, `name` used in configuration is `local`, not `Local`.

Create file `~/.creds` with credentials used in OpenStack and Amazon. Eg.

    export OS_TENANT_NAME=openstack_tenant
    export OS_USERNAME=openstack_username_for_tenant
    export OS_PASSWORD=openstack_password_for_tenant
    export OS_AUTH_URL="http://127.0.0.1:5000/v2.0/" # default value for OpenStack installation
    export IMAGES_DIR=/var/lib/glance/images # default value for OpenStack installation
    export SOURCE_CS=atmosphere_local_compute_site_site_id_property
    export AWS_ACCESS_KEY=aws_access_key
    export AWS_SECRET_KEY=aws_secret_key

User who runs `migratio` need to be assigned to `glance` group.

Create configuration files per Compute Site in directory `config/`. Configuration file name must be identical with ComputeSite `site_id` property. Use suffix `.conf`. See [config/](config/).

For OpenStack:

    export EXTERNAL_USER=external_username
    export EXTERNAL_HOST=external_ip_or_hostname

Create account `external_username` and allow login without password (using ssh authorized keys) for user which is running `migratio`. Allow `external_username` to use OpenStack on external compute site.

For Amazon:

    export AWS_REGION=eu-west-1 # or eu-central-1, us-east-1, us-west-1, etc.
    export EC2_URL=https://ec2.eu-west-1.amazonaws.com

## Usage

First time run (as non-root, inside `migratio/` directory):

    pushd /home/atmosphere/migratio
    bundle exec ./bin/migratio-run
    popd

Normal run (as non-root):

    start migratio

Stop (as non-root):

    stop migratio

## Contributing

1. Fork it!
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new *Pull Request*
