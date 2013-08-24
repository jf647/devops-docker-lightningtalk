bash "cleanup before export" do
    code <<-eos
        apt-get -y autoremove
        apt-get -y clean all
        dd if=/dev/zero of=/EMPTY bs=1M
        rm -f /EMPTY
    eos
end