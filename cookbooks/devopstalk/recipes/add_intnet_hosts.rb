bash "add intnet host vagrant" do
    not_if "grep 192.168.50.10 /etc/hosts"
    code <<-eos
        echo "192.168.50.10 docker.vagrant docker" >> /etc/hosts
    eos
end

bash "add intnet host registry" do
    not_if "grep 192.168.50.20 /etc/hosts"
    code <<-eos
        echo "192.168.50.20 registry.vagrant registry" >> /etc/hosts
    eos
end
