# Seattle DevOps Docker Lightning Talk

This repo contains the files used in my lightning talk to Seattle DevOps on Docker.

You will need to have [Virtualbox](http://www.virtualbox.org) and [Vagrant](http://www.vagrantup.com) installed before using this repo.

## Vagrant Images

The Vagrantfile references four boxes:

* build_docker, which takes the nightly Ubuntu 12.04 Vagrant Image, adds Chef, then uses Chef to turn the box into a Docker server
* build_registry, which iterates upon build_docker to run a private Docker registry container
* docker, which is the output of build_docker
* registry, which is the output of build_registry

You could take the Ubuntu image and manually tweak it in Virtualbox to your liking, then export it as a Vagrant box, but I wanted to showcase using devops techniques to rebuild the images at will.

## Bulding the Vagrant Boxes

From a cloned version of this repo, run

    vagrant up build_docker

When complete, export the build to a box and add it to your local Vagrant repository:

    vagrant package build_docker --out ubuntu-docker.box
    vagrant box add ubuntu-docker ubuntu-docker.box
    rm ubuntu-docker.box
    vagrant destroy build_docker

Next, iterate the docker box to build the registry box:

    vagrant up build_registry
    vagrant package build_registry --out ubuntu-docker-registry.box
    vagrant box add ubuntu-docker-registry ubuntu-docker-registry.box
    rm ubuntu-docker-registry.box
    vagrant destroy build_registry

Then run the vagrant host and the registry host by running:

    vagrant up registry
    vagrant up docker

And get a login shell on the docker machine by running:

    vagrant ssh docker

Several example docker builds have been provided; find them in /vagrant/docker.

## Building Docker Images

The magic of Docker comes from building up container images as layers upon themselves.

While you can build a docker image manually, a Dockerfile makes the process easier and repeatable.  To build an image from a Dockerfile, cd to the directory containing it and run

    docker build .

When complete, a build is assigned a UUID.  The first few characters can be used to identify it unambiguously, much like a git commit.

If you plan on building another image from this one, you should tag it so that it's easier to identify in subsequent Dockerfiles.

    docker tag UUID repository [tag]

Repository is a bit of a misnomer - it's a namespace.  Don't use slashes in the repository, otherwise it will think that you want to push the image to your "homedir" on the public docker repo.  I tend to use dashes to separate words (e.g. 'my-ubuntu' rather than 'my/ubuntu')

The tag is optional, and if not specified will be replaced by 'latest'.  When referencing images, put the tag after a colon (e.g. 'my-ubuntu:20130827').

When starting a container from an image, if you leave off the tag then Docker will look for the tag 'latest'.

You can also apply a tag automatically when a build completes successfully:

    docker build -t tag .

### Builds included in this repo

The docker subdirectory (/vagrant/docker when inside the VM) contains a number of builds.  There are both [B]ase images, which are meant to be derived from to produce [L]eaf images, which are containerized applications that you would develop, test and deploy.  _These are notional terms only - the don't appear in the output of 'docker images' for example_

Here's how they relate to each other:

#### ubuntu:12.04 [B]

This is a dotcloud-provided starting point for all my containers.  It is pulled into the docker host by the devopstalk::docker recipe.

#### my-ubuntu < ubuntu:12.04 [B]

This enables the full set of software repos for Ubuntu and installs python-software-properties, which makes adding PPA archives for software not managed by Ubuntu.  I also install supervisord so that I can start multiple processes inside a container.

#### buildessential < my-ubuntu [B]

Installs curl and build-essential

#### nginx < buildessential [B]

Installs the latest stable nginx from a PPA and sets up a basic configuration file that we can hook into with derivative images

#### java < my-ubuntu [B]

Installs openjdk 7.  Note that we have to use --no-install-recommends, otherwise this pulls in nearly 150 dependencies, including things like FUSE.  As a general rule, trying to do things like compile kernel externsions inside a docker container will give you trouble.

#### stash < java [L]

Installs Atlassian Stash and configures it to start on boot via supervisord.

Because Docker images are ephemeral, in order to persist the Stash repositories, you have to bind mount a filesystem when starting this image.  Stash also requires that it be able to resolve its hostname, so we pass a fixed hostname using -h:

    /usr/bin/docker run -h stash -v /srv/stash:/opt/stash-home:rw stash:2.7.0

#### chef-client < my-ubuntu [B]

This installs chef-client, which you could then iterate on to use cookbooks instead of multiple RUN commands to provision boxes.  I haven't expanded upon this example because native integration with the major devops provisioning system is a key goal to get Docker to 1.0, so expect this to be easier in the future

#### ruby < nginx [B]

Installs ruby1.9.3 and rubygems1.9.1

#### gollum < ruby [B]

Installs the gollum gem, which is the engine behind Github Wikis

#### projectwiki < gollum [L]

Starts a gollum instance for a specific project that is tied to a git repo on the host machine.

Exposes the website on port 10001

#### zenweb < ruby [L]

Installs the zenweb gem and builds the example site, then configures nginx to serve it.

Exposes the website on port 11001

#### rails < ruby [L]

Installs rails and creates a basic site scaffold, then serves it using unicorn.

Exposes the website on port 12001

## Visualizing Docker Images

Every command in a Dockerfile creates a new AUFS layer.  Sometimes it can be hard to visualize the relationship between them.  Luckily, docker can output a graphviz plot of them:

    docker images -viz | dot -Tpng > /vagrant/docker-images.png

## Starting Docker containers on boot

Creating a docker image doesn't make it start like a system service.  For that, you need to start it manually, or use a process manager of some sort.  To reduce dependencies, I use Upstart and export config files using foreman.  You can just as easily use runit, supervisord, init.d scripts or whatever you prefer.

It is easier if you use a process manager that expects the things it launches to remain in the foreground, because then stopping the system service should pass the signal through 'docker run' and into the container, shutting everything down cleanly.  If you use 'docker run -d' to detach the container, you will have to write some magic to stop containers using something like

    docker ps | grep description | awk '{print $1}' | docker stop

In each of the leaf docker builds, I have a Procfile (foreman uses the same format as Heroku).  In the root of the docker builds, there is a script that exports the application by using 'foreman export':

    ./export_upstart.sh zenweb

## Hosting Docker Images inside the Firewall

Anyone can push a Docker image to the public registry server at https://index.docker.io/, but enterprises will want to run their own private registry server, much as they would run their own Git repo or Software host.

### Pushing Images to the Private Registry

Tag a build with a name that includes a remote host, then push it:

    docker tag 192.168.50.20:5000/gollum gollum
    docker push 192.168.50.20:5000/gollum

The registry server built above has a private network at 192.168.50.20 (the docker host is on .10)

The registry stores layers, just like Docker does.  It knows how to skip layers it already has when you push a derived image:

    vagrant@docker:/vagrant/docker/buildessential$ docker push 192.168.50.20:5000/buildessential
    The push refers to a repository [192.168.50.20:5000/buildessential] (len: 1)
    Sending image list
    Pushing repository 192.168.50.20:5000/buildessential (1 tags)
    Image 8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c already pushed, skipping
    Image 7225e4b92fb6e469a1b62e5a2c016a94ebd46dee9dd12da0597a1e59982e9cea already pushed, skipping
    Image 94f8ae3137d6753db7a10fc2602b7c9ce32b94bfa88412bcd372d5633606e8cb already pushed, skipping
    Image 9d3311cb92daee44206286b78baf559a2dd68bdbef772cc1487178a4f0416232 already pushed, skipping
    Image f568806104326bc2228fe109d1141b84c3c15a2c0adc2507825ba1be3cce5901 already pushed, skipping
    Pushing 0ab2a24490960a1cafb0a5c7a3b4a98fd21a347260cf0457dccaa3988f662fe2
    Pushing tags for rev [0ab2a24490960a1cafb0a5c7a3b4a98fd21a347260cf0457dccaa3988f662fe2] on {http://192.168.50.20:5000/v1/repositories/buildessential/tags/latest}
    vagrant@docker:/vagrant/docker/buildessential$

### Pulling Images from the Private Registry

    docker pull 192.168.50.20:5000/gollum

## Further Reading

* [Docker Website](http://www.docker.io)
