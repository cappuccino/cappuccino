#!/bin/bash
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino Tools/Documentation directory
# $2 Generated documentation directory

# Do this if you want to use the utility functions
source "$1"/processor_setup.sh

# The following transforms are performed:
# - Strip useless "[implementation]" littering the docs
# - Change "Static Public Member Functions" to "Class Methods"
# - Change "Public Member Functions" to "Instance Methods"

if [ ! -d "$2" ]; then
    exit 0
fi

processor_msg 'Massaging text...'

sed -i '' -E \
-e 's/<code> \[implementation\]<\/code>/\&emsp;/g'     \
-e 's/Static Public Member Functions/Class Methods/g'  \
-e 's/Public Member Functions/Instance Methods/g'      \
-e 's/Member Function Documentation/Method Documentation/g'      \
-e 's/(AppKit|Foundation)\.doc/\1/g'               \
"$2"/*.html
