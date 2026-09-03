#!/usr/bin/env python3
#
# Copyright (C) 2026 David Richardson
#
# This library is free software; you can redistribute it and/or
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

"""
Locates MainMenu.xib files and replaces the generic 'NewApplication' 
strings with the correct product name extracted from the Jakefile and Info.plist.
"""

import re
import sys
import plistlib
import xml.etree.ElementTree as ET
from pathlib import Path

def main():
    repo_root = Path.cwd().resolve()
    
    for xib_path in repo_root.rglob('Resources/MainMenu.xib'):
        app_root = xib_path.parent.parent
        jakefile_path = app_root / 'Jakefile'
        plist_path = app_root / 'Info.plist'

        if not (jakefile_path.is_file() and plist_path.is_file()):
            continue

        try:
            jake_content = jakefile_path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            print(f"Encoding error reading {jakefile_path}", file=sys.stderr)
            continue

        match = re.search(r'task\.setProductName\(\s*["\']([^"\']+)["\']\s*\)', jake_content)
        if not match:
            continue
        
        jake_name = match.group(1)

        try:
            with plist_path.open('rb') as f:
                plist_data = plistlib.load(f)
                plist_name = plist_data.get('CPBundleName')
        except Exception as e:
            print(f"Error parsing {plist_path}: {e}", file=sys.stderr)
            continue

        if not plist_name:
            continue

        if jake_name != plist_name:
            print(f"Mismatch in {app_root.relative_to(repo_root)}: Jakefile='{jake_name}', Info.plist='{plist_name}'. Skipping.", file=sys.stderr)
            continue

        product_name = jake_name
        mutated = False

        try:
            tree = ET.parse(xib_path)
            root = tree.getroot()

            for elem in root.iter():
                if 'title' in elem.attrib:
                    title = elem.attrib['title']
                    if 'NewApplication' in title:
                        elem.attrib['title'] = title.replace('NewApplication', product_name)
                        mutated = True

            if mutated:
                tree.write(xib_path, encoding='UTF-8', xml_declaration=True)
                print(f"Updated {xib_path.relative_to(repo_root)} with product name '{product_name}'")

        except ET.ParseError as e:
            print(f"XML parsing error in {xib_path}: {e}", file=sys.stderr)
        except Exception as e:
            print(f"Unexpected error processing {xib_path}: {e}", file=sys.stderr)

if __name__ == '__main__':
    main()
