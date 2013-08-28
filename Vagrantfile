Vagrant.configure("2") do |config|

    config.ssh.forward_agent = true

    config.vm.define :build_docker do |v|
        v.vm.box = 'precise-server-cloudimg-vagrant-amd64-disk1'
        v.vm.box_url = 'http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-vagrant-amd64-disk1.box'
        v.vm.provision :shell, :inline => <<-eos
            curl -L http://www.opscode.com/chef/install.sh | sudo bash
        eos
        v.vm.provision :chef_solo do |chef|
            chef.add_recipe 'apt'
            chef.add_recipe 'devopstalk::setup_stash'
            chef.add_recipe 'devopstalk::setup_gollum'
            chef.add_recipe 'devopstalk::add_intnet_hosts'
            chef.add_recipe 'devopstalk::docker'
        end
    end

    config.vm.define :build_registry do |v|
        v.vm.box = 'docker'
        v.vm.provision :chef_solo do |chef|
            chef.add_recipe 'devopstalk::registry'
        end
    end

    config.vm.define :docker do |v|
        v.vm.box = 'docker'
        v.vm.hostname = 'docker.vagrant'
        v.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "4096"]
        end
        v.vm.network :private_network, ip: "192.168.50.10"
        # expose some ports into Virtualbox (which are in turn exposed into Docker containers)
        %w(7990 7999 10001 11001 12001).map{ |e| e.to_i }.each do |port|
            v.vm.network :forwarded_port, guest: port, host: port
        end
    end

    config.vm.define :registry do |v|
        v.vm.box = 'docker-registry'
        v.vm.hostname = 'registry.vagrant'
        v.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048"]
        end
        v.vm.network :private_network, ip: "192.168.50.20"
    end

end
