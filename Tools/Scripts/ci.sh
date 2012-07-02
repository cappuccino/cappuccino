#!/usr/bin/env bash

project_home="$(dirname "$PWD")"
extras="$project_home/ci-extra.sh"

export PATH="$HOME/narwhal/bin:$PATH"
export CAPP_AUTO_UPGRADE="yes"

export CAPP_BUILD="$project_home/build_incremental"
time jake CommonJS test-only
code=$?
if [ $code -ne 0 ]; then
    echo "INCREMENTAL BUILD FAILED ($code)"
    exit $code
else
    echo "INCREMENTAL BUILD SUCCEEDED"
fi

export CAPP_BUILD="$project_home/build_clean"
rm -rf "$CAPP_BUILD"

time jake CommonJS test-only
code=$?
if [ $code -ne 0 ]; then
    echo "CLEAN BUILD FAILED ($code)"
    exit $code
else
    echo "CLEAN BUILD SUCCEEDED"
fi

# run any additional ci commands not common to all branches (like nightly builds)
if [ -f "$extras" ]; then
	source "$extras"
fi

exit 0
