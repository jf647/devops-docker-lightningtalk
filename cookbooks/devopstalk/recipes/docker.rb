
# based on http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring

# bflad has a great chef-docker cookbook, but it hasn't still uses the 0.5.x PPA source
# rather than the dotcloud repo used for 0.6.0

# we need to install the newer guest additions; the ones that come with Ubuntu don't work with the raring kernel
%w(virtualbox-guest-utils virtualbox-guest-dkms virtualbox-guest-x11).each do |pkg|
    package pkg do
        action :purge
    end
end
remote_file "#{Chef::Config[:file_cache_path]}/VBoxGuestAdditions_4.2.16.iso" do
    source "http://download.virtualbox.org/virtualbox/4.2.16/VBoxGuestAdditions_4.2.16.iso"
    notifies :run, "bash[install vbox guest additions]", :immediately
end
bash "install vbox guest additions" do
    action :nothing
    code <<-eos
        mount -o loop #{Chef::Config[:file_cache_path]}/VBoxGuestAdditions_4.2.16.iso /mnt
        yes | /mnt/VBoxLinuxAdditions.run
        umount /mnt
    eos
end

# install the 13.04 kernel
package "linux-image-generic-lts-raring"
package "linux-headers-generic-lts-raring"

# pull in the DotCloud software repo and key
apt_repository "dotcloud-docker" do
    distribution "docker"
    uri "https://get.docker.io/ubuntu"
    components [ "main" ]
    key "http://get.docker.io/gpg"
end

# put vagrant in the docker group
group "docker" do
    members [ "vagrant" ]
end

# install Docker and start it
package "lxc-docker"
service "docker" do
    action [ :start, :enable ]
    provider Chef::Provider::Service::Upstart
end

# pull the basic ubuntu images in from dotcloud
bash "pull ubuntu images" do
    not_if "docker run ubuntu:12.04 date"
    code <<-eos
        docker pull ubuntu
    eos
end

# swap in Ruby 1.9 and install foreman
%w(ruby ruby1.8 rubygems).each do |pkg|
    package pkg do
        action :purge
    end
end
%w(ruby1.9.3 rubygems1.9.1).each do |pkg|
    package pkg
end
gem_package "foreman"

# clean up the disks (reduces size of packaged box)
include_recipe 'devopstalk::cleanup'
