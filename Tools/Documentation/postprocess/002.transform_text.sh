#!/usr/bin/env bash
#
# A hook for transforming text in the generated HTML files.
# CWD is the main temporary build directory.
#
# ARGUMENTS:
#   $1 - The absolute path to the project root.
#   $2 - The absolute path to the generated 'html' directory within the temp dir.

# Corrected path to the support script
source "$1/Tools/Documentation/support/processor_setup.sh"

# This is a placeholder. If the original script did something specific,
# its logic would go here, operating on files inside the "$2" directory.
# For now, we'll just log that it ran.
processor_msg "Running text transformations..."
