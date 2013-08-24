#!/bin/sh

foreman export upstart /etc/init -a $1 -d / -u root -f $1/Procfile
