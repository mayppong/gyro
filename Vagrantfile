# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
cd /home/vagrant
wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -

sudo apt-get update
sudo apt-get install -y git elixir esl-erlang nodejs postgresql inotify-tools

mix local.hex --force
mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
SCRIPT

# postgress password can be setup using the command below:
# sudo -u postgres psql postgres
# << EOF
# \password postgres;
# ALTER ROLE postgres LOGIN;
# ALTER ROLE postgres CREATEDB;
# EOF

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/wily64"
  config.vm.hostname = "gyro"
  config.vm.network "private_network", ip: "192.168.100.100"
  config.vm.provision "shell", inline: $script

end
