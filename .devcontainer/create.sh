#!/bin/bash

git submodule init
git submodule update
git submodule foreach git fetch
git submodule foreach git checkout master
git submodule foreach git rebase origin/master

cd extensions
rm -rf tsar-test && git clone https://github.com/dvm-system/tsar-test

cd ..
rm -rf build && mkdir build && cd build
cmake .. -C ../CMakeCache.in -DPTS_EXECUTABLE=/repo/pts/bin/pts.pl
