#!/usr/bin/env bash
#
# Copyright (C) 2026 David Richarson
# Created 2026-09-03 by David Richardson
#
# This script is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
# Description:
# Recursively locates and upgrades legacy XIB documents to the modern DOM structure
# utilizing the Xcode ibtool utility. Executable in place.
#
# Use with Xcode 26 version of ibtool.
# 
# Although a single-run script for use against ./Tests/Manual/…
# it is preserved as a template for user code.
#

set -euo pipefail

if ! command -v ibtool >/dev/null 2>&1; then
    echo "Error: ibtool is required but not found in PATH." >&2
    exit 1
fi

find . -type f -name "*.xib" -print0 | while IFS= read -r -d '' file; do
    echo "Upgrading: ${file}"
    ibtool --upgrade "${file}" --write "${file}"
done
