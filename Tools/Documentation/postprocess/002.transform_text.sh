#!/usr/bin/env bash
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino Tools/Documentation directory
# $2 Generated documentation directory

# Do this if you want to use the utility functions
source "$1"/support/processor_setup.sh

if [ ! -d "$2" ]; then
    exit 0
fi

processor_msg 'Massaging text...'

exec "$1"/support/massage_text.py "$2"
