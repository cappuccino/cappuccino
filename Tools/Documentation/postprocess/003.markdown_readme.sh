#!/usr/bin/env bash
#
# Moves the generated README.html to be the main index page of the documentation.
# NOTE: This step is being skipped to allow the Doxygen-generated index to be the default main page.
#
# ARGUMENTS:
#   $1 - The absolute path to the project root.
#   $2 - The absolute path to the generated 'html' directory within the temp dir.

# Corrected path to the support script
source "$1/Tools/Documentation/support/processor_setup.sh"

processor_msg "Installing custom main documentation page... (SKIPPED)"

# The original build process used the project README as the main index.
# The 'mv' command below is commented out to prevent this from happening.
#
# if [ -f "README.html" ]; then
#     mv "README.html" "$2/index.html"
# else
#     processor_msg "Warning: README.html not found, cannot create main page." "yellow"
# fi
