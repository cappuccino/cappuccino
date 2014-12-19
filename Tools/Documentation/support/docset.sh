#!/usr/bin/env bash

source "$1"/support/processor_setup.sh

processor_msg "Generating Docset"

MAKEFILE="Build/Documentation/html/Makefile"
DOCSDIR="Build/Documentation/html"

processor_msg "Massaging Makefile"
sed -i '.bak' 's/docsetutil index \$(DOCSET_NAME)/docsetutil index -skip-text \$(DOCSET_NAME)/g' $MAKEFILE

pushd $DOCSDIR
processor_msg "Running Make"
make

processor_msg "Finishing up"
mv "org.cappuccino-project.cappuccino.docset" "Cappuccino.docset"
cp "$1"/Info.plist "Cappuccino.docset/Contents"
popd

processor_msg "Moving docset to Build/Documentation"
mv "$DOCSDIR"/Cappuccino.docset "Build/Documentation"

processor_msg "Done"
