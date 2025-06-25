#!/usr/bin/env bash
#
# Creates README.html from the main README.markdown in the project root.
# CWD is a temporary build directory.
#
# ARGUMENTS:
#   $1 - The absolute path to the project root.

# Do this if you want to use the utility functions. Note the path change.
source "$1/Tools/Documentation/support/processor_setup.sh"

markdown=`which markdown`

if [ -n "$markdown" ]; then
    processor_msg "Markdown main page..."
    # Read from project root, write to current (temp) directory
    "$markdown" "$1/README.markdown" > "README.html"
else
    processor_msg "markdown binary is not installed, documentation cannot be generated." "red"
    echo "On Mac OS X, install brew with the following command line:"
    echo '  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"'
    echo "Then use 'brew install markdown' from the command line to install markdown."
    exit 1
fi
