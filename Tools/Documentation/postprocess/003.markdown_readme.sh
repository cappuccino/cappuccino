#!/usr/bin/env bash
#
# Moves the generated README.html to be the main index page of the documentation.
# CWD is the main temporary build directory.
#
# ARGUMENTS:
#   $1 - The absolute path to the project root.
#   $2 - The absolute path to the generated 'html' directory within the temp dir.

# Corrected path to the support script
source "$1/Tools/Documentation/support/processor_setup.sh"

processor_msg "Installing custom main documentation page..."

# The README.html was generated in the root of our CWD (the temp dir)
if [ -f "README.html" ]; then
    # The main doxygen page is index.html. We replace it with our README.
    mv "README.html" "$2/index.html"
else
    processor_msg "Warning: README.html not found, cannot create main page." "yellow"
fi
