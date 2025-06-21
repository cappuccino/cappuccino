#!/usr/bin/env bash
#
# Creates temporary documentation source directories inside the main documentation directory.
#
# ARGUMENTS:
#   $1 - The absolute path to the main documentation directory (e.g., /path/to/cappuccino/Tools/Documentation)

# Do this if you want to use the utility functions
source "$1"/support/processor_setup.sh

# --- Main Execution ---
MAIN_DOC_DIR="$1"

processor_msg "Starting source collection script..."
processor_msg "Current working directory: $(pwd)"
processor_msg "Target documentation directory: $MAIN_DOC_DIR"

# A function to robustly collect sources using find and bsdtar
# ARGS: $1=Framework Name, $2=Output Doc Dir Name
collect_sources() {
    local framework_name="$1"
    local doc_dir_name="$2"

    # Construct full, absolute paths for all our work
    local full_doc_dir_path="$MAIN_DOC_DIR/$doc_dir_name"
    local full_tar_path="$MAIN_DOC_DIR/$doc_dir_name.tar"

    processor_msg "--------------------------------------------------"
    processor_msg "Processing framework: $framework_name"
    processor_msg "Output will be in: $full_doc_dir_path"

    if [ ! -d "$framework_name" ]; then
        processor_msg "ERROR: Source directory '$framework_name' does not exist in $(pwd)." "red"
        exit 1
    fi

    # Create the tar archive *inside* the documentation directory
    find "$framework_name" -name "*.j" | bsdtar -s "|^$framework_name/|$doc_dir_name/|" -cnf "$full_tar_path" -T -

    if [ -f "$full_tar_path" ]; then
        processor_msg "Extracting archive into '$MAIN_DOC_DIR'..."
        # Extract the archive *from within* the documentation directory
        bsdtar xf "$full_tar_path" -C "$MAIN_DOC_DIR"
        rm "$full_tar_path"
    else
        processor_msg "ERROR: Failed to create tar archive for $framework_name." "red"
        exit 1
    fi
}


# --- Run Collection ---
collect_sources "AppKit" "AppKit.doc"
collect_sources "Foundation" "Foundation.doc"


# --- Post-Process Files ---
processor_msg "--------------------------------------------------"
processor_msg "Removing @import and @class from source files..."

# Look for the .doc directories inside the main documentation directory
if [ -d "$MAIN_DOC_DIR/AppKit.doc" ]; then
    find "$MAIN_DOC_DIR/AppKit.doc" -name *.j -exec sed -e '/@import.*/ d' -e '/@class.*/ d' -i '' {} \;
fi
if [ -d "$MAIN_DOC_DIR/Foundation.doc" ]; then
    find "$MAIN_DOC_DIR/Foundation.doc" -name *.j -exec sed -e '/@import.*/ d' -e '/@class.*/ d' -i '' {} \;
fi

processor_msg "Source collection script finished."
