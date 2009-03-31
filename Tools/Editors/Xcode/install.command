#~/bin/bash
echo Creating destination directory..
mkdir -pv ~/Library/Application\ Support/Developer/Shared/Xcode/Specifications
echo Copying files...
cp -v ${0%/*}/ObjectiveJ.* ~/Library/Application\ Support/Developer/Shared/Xcode/Specifications
