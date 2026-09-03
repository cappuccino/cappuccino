#!/usr/bin/env python3
#
# Copyright (C) 2026 David Richardson
# Created 2026-09-03
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
Recursively locates and converts modern Interface Builder documents (.xib) 
into compiled Interface Builder documents (.cib) for test applications.

This script must be executed from the repository root to correctly resolve
the path to the local nib2cib tool and execute it within the specific
context of each test application's root directory.

Although a single-run script for use against ./Tests/Manual/…
it is preserved as a template for user code.
"""

import subprocess
import sys
from pathlib import Path

def main():
    repo_root = Path.cwd().resolve()
    nib2cib_path = repo_root / 'dist' / 'cappuccino' / 'bin' / 'nib2cib'
    tests_root = repo_root / 'Tests' / 'Manual'

    if not nib2cib_path.is_file():
        sys.exit(f"Executable not found: {nib2cib_path}")

    # Recursively locate all .xib files within a Resources directory
    for xib_path in tests_root.rglob('Resources/*.xib'):
        app_root = xib_path.parent.parent
        
        # Target must be relative to app_root (e.g., Resources/MainMenu.xib)
        target_arg = xib_path.relative_to(app_root)

        print(f"Processing: {target_arg} (in {app_root.relative_to(repo_root)})")

        try:
            subprocess.run(
                [str(nib2cib_path), str(target_arg)],
                cwd=str(app_root),
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Failed converting {xib_path.name}: {e}", file=sys.stderr)

if __name__ == '__main__':
    main()
