#!/usr/bin/env bash
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino documentation directory

# Do this if you want to use the utility functions
source "$1"/support/processor_setup.sh

markdown=`which markdown`

if [ -n "$markdown" ]; then
    processor_msg "Markdown main page..."
    "$markdown" README.markdown > "$1"/README.html
else
    processor_msg "markdown binary is not installed, documentation cannot be generated." "red"
    echo "On Mac OS X, install brew with the following command line:"
    echo '  ruby -e "$(curl -fsSL https://gist.github.com/raw/323731/install_homebrew.rb)"'
    echo "Then use 'brew install markdown' from the command line to install markdown."
    exit 1
fi
