# pull the docker registry container
bash "pull registry image" do
    not_if "docker images | samalba/docker-registry"
    code <<-eos
        docker pull samalba/docker-registry
    eos
end

# create a persistent directory for the registry container to use
directory "/srv/registry"

# arrange for the registry to start on boot
template "#{Chef::Config[:file_cache_path]}/Procfile" do
    source "Procfile.registry.erb"
    notifies :run, "bash[export registry upstart config]", :immediately
end

bash "export registry upstart config" do
    action :nothing
    cwd Chef::Config[:file_cache_path]
    code <<-eos
        sudo foreman export upstart /etc/init -a docker-registry -u root -d / -f #{Chef::Config[:file_cache_path]}/Procfile
    eos
end

include_recipe 'devopstalk::cleanup'
