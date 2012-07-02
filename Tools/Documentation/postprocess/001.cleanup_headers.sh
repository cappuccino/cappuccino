#!/usr/bin/env bash
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino Tools/Documentation directory
# $2 Generated documentation directory

# Do this if you want to use the utility functions
source "$1"/support/processor_setup.sh

# Cleanup the files we generated to feed to doxygen
processor_msg "Cleaning up generated header files..."

if [ -d AppKit.doc ]; then
    rm -rf AppKit.doc
fi

if [ -d Foundation.doc ]; then
    rm -rf Foundation.doc
fi
