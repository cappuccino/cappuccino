#!/usr/bin/env bash
#
# Remove the generated README.html once the build has finished.
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino documentation directory
#

rm "$1"/README.html
