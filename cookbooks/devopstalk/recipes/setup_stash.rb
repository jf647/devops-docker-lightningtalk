group "stash" do
    gid 998
end

user "stash" do
    uid 998
    gid 998
    home "/srv/stash"
    comment "Stash data pseudo-user"
end

# make an directory for stash to store runtime data
directory "/srv/stash" do
    owner "stash"
    group "stash"
    mode 0700
end
