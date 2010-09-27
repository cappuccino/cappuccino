#!/bin/sh
#
# NOTE: The working directory should be the main capp directory when this script is run

if [ -d AppKit.doc ]; then
    rm -rf AppKit.doc
fi

if [ -d Foundation.doc ]; then
    rm -rf Foundation.doc
fi

echo "Copying source files..."
cp -r AppKit AppKit.doc
cp -r Foundation Foundation.doc

echo "Processing source files..."
find AppKit.doc -name *.j -exec sed -e '/@import.*/ d' -i '' {} \;
find Foundation.doc -name *.j -exec sed -e '/@import.*/ d' -i '' {} \;

exec Tools/Documentation/make_headers
