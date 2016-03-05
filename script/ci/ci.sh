#!/bin/bash

export PATH="$PWD/narwhal/bin:$PATH"
export PATH="$PWD/travis-phantomjs/phantomjs-2.1.1-linux-x86_64/bin:$PATH"
export CAPP_BUILD="$PWD/Build"
export NARWHAL_ENGINE=rhino
export BROWSER=phantomjs

mkdir $PWD/travis-phantomjs
wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 -O $PWD/travis-phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar -xvf $PWD/travis-phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C $PWD/travis-phantomjs

./bootstrap.sh --noprompt --directory ./narwhal

git clone https://github.com/cappuccino/cucapp.git
cd cucapp; jake install; cd ..

git clone https://github.com/cappuccino/OJTest.git
cd OJTest; jake install; cd ..

jake test

jake cucumber-test