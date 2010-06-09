#!/bin/sh

PACKAGE_BRANCH="nightly" jake push-packages
code=$?
if [ $code -ne 0 ]; then
    echo "NIGHTLY BUILD PUSH FAILED ($code)"
    exit $code
else
    echo "NIGHTLY BUILD PUSH SUCCEEDED"
fi
