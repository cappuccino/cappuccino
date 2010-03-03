#!/bin/bash

project_home="$(dirname "$PWD")"

export PATH="$HOME/narwhal/bin:$PATH"
export CAPP_AUTO_UPGRADE="yes"

export CAPP_BUILD=$project_home/build_incremental
time jake test
code=$?
if [ $code -ne 0 ]; then
    echo "INCREMENTAL BUILD FAILED ($code)"
    exit $code
else
    echo "INCREMENTAL BUILD SUCCEEDED"
fi

export CAPP_BUILD=$project_home/build_clean
rm -rf $CAPP_BUILD

time jake CommonJS test
code=$?
if [ $code -ne 0 ]; then
    echo "CLEAN BUILD FAILED ($code)"
    exit $code
else
    echo "CLEAN BUILD SUCCEEDED"
fi

PACKAGE_BRANCH="nightly" jake push-packages
code=$?
if [ $code -ne 0 ]; then
    echo "NIGHTLY BUILD PUSH FAILED ($code)"
    exit $code
else
    echo "NIGHTLY BUILD PUSH SUCCEEDED"
fi

exit 0