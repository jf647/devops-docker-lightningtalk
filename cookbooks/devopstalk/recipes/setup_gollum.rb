# install git
package "git"

# make an bare repo for a gollum wiki
directory "/srv/projectwiki"

bash "init bare repo for gollum" do
    cwd "/srv/projectwiki"
    code "git init"
end