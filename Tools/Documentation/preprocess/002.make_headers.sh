#!/usr/bin/env bash
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino documentation directory

# Do this if you want to use the utility functions
source "$1"/support/processor_setup.sh

if [ -d AppKit.doc ]; then
    rm -rf AppKit.doc
fi

if [ -d Foundation.doc ]; then
    rm -rf Foundation.doc
fi

# Tar all of the AppKit/*.j files, excluding any files that begin with "_", and replace
# "AppKit" with "AppKit.doc" in the files path within the archive. Then unarchive the result.
# This turns out to  be the quickest way I could find to get the correct files and rename them.
processor_msg "Collecting source files..."
bsdtar cf AppKit.doc.tar --exclude='_*' -s /^AppKit/AppKit.doc/ AppKit/*.j AppKit/**/*.j
bsdtar xf AppKit.doc.tar
rm AppKit.doc.tar

# Now do the same thing with Foundation files.
bsdtar cf Foundation.doc.tar --exclude='_*' -s /^Foundation/Foundation.doc/ Foundation/*.j Foundation/**/*.j
bsdtar xf Foundation.doc.tar
rm Foundation.doc.tar

# Remove @import from the source files, doxygen doesn't know what to do with them
processor_msg "Removing @import from source files..."
find AppKit.doc -name *.j -exec sed -e '/@import.*/ d' -i '' {} \;
find Foundation.doc -name *.j -exec sed -e '/@import.*/ d' -i '' {} \;
