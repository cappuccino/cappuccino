#!/bin/sh
#
# NOTE: The working directory should be the main capp directory when this script is run

markdown_binary=$*

$markdown_binary README.markdown >README.html
