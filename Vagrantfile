# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.network "forwarded_port", guest: 9200, host: 9200
  config.vm.network "forwarded_port", guest: 9292, host: 9292

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    # Repositories
    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get upgrade -y

    # Java
    echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
    sudo apt-get install -y oracle-java8-installer

    # Elasticsearch
    sudo apt-get install -y elasticsearch
    sudo service elasticsearch stop
    echo "ES_HEAP_SIZE=1g" | sudo tee -a /etc/default/elasticsearch

    # Dependencies / Utilities
    sudo apt-get install -y screen curl git build-essential

    # Ruby
    if [ ! -f /home/vagrant/.rvm/scripts/rvm ]
    then
        gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
        \\curl -sSL https://get.rvm.io | bash
    fi
    source /home/vagrant/.rvm/scripts/rvm

    # Gems
    cd /vagrant
    rvm use $(cat .ruby-version) --install
    gem install bundler --no-rdoc --no-ri
    bundle install

    # Services
    sudo service elasticsearch start
  SHELL
end
