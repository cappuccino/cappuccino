#!/usr/bin/env bash
#
# Creates temporary documentation source directories in the CWD (a temp dir).
#
# ARGUMENTS:
#   $1 - The absolute path to the project root.

# Do this if you want to use the utility functions. Note the path change.
source "$1/Tools/Documentation/support/processor_setup.sh"

# A function to collect sources. CWD is the temp dir.
# ARGS: $1=Project Root, $2=Framework Name, $3=Output Doc Dir Name
collect_sources() {
    local project_root="$1"
    local framework_name="$2"
    local doc_dir_name="$3"
    local tar_file="temp.tar" # Temp tar file in the CWD

    processor_msg "--------------------------------------------------"
    processor_msg "Processing framework: $framework_name"

    # Find sources relative to the project root
    find "$project_root/$framework_name" -name "*.j" | bsdtar -s "|^$project_root/$framework_name/|$doc_dir_name/|" -cnf "$tar_file" -T -

    if [ -f "$tar_file" ]; then
        processor_msg "Extracting archive to CWD..."
        bsdtar xf "$tar_file"
        rm "$tar_file"
    else
        processor_msg "ERROR: Failed to create tar archive for $framework_name." "red"
        exit 1
    fi
}

# --- Run Collection ---
collect_sources "$1" "AppKit" "AppKit.doc"
collect_sources "$1" "Foundation" "Foundation.doc"

# --- Post-Process Files ---
processor_msg "--------------------------------------------------"
processor_msg "Removing @import and @class from source files..."
# These directories now exist in our CWD (the temp dir)
find AppKit.doc -name *.j -exec sed -e '/@import.*/ d' -e '/@class.*/ d' -i '' {} \;
find Foundation.doc -name *.j -exec sed -e '/@import.*/ d' -e '/@class.*/ d' -i '' {} \;
