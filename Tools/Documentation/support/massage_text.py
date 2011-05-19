#!/usr/bin/env python
#
# $1 Generated documentation directory

# The following transforms are performed:
# - Strip useless "[implementation]" littering the docs
# - Change "Static Public Member Functions" to "Class Methods"
# - Change "Public Member Functions" to "Instance Methods"
# - Change "Member Function Documentation" to "Method Documentation"
# - Remove empty line left at the end of multi-parameter method prototypes

import glob
import os.path
import re
import sys

transforms = [
    re.compile(r"<code> \[implementation\]</code>"), "&emsp;",
    re.compile(r"Static Public Member Functions"), "Class Methods",
    re.compile(r"Public Member Functions"), "Instance Methods",
    re.compile(r"Protected Attributes"), "Instance Variables",
    re.compile(r"Member Function Documentation"), "Method Documentation",
    re.compile(r"Member Data Documentation"), "Instance Variable Documentation",
    re.compile(r"(AppKit|Foundation)\.doc"), r"\1",
    re.compile(r"\s*<tr>\n(\s*<td></td>\n){2}\s*(<td></td>){2}<td>&emsp;</td>\n\s*</tr>"), ""
]

html = glob.glob(os.path.join(sys.argv[1], "*.html"))

for count, filename in enumerate(html):
    f = open(filename, "r+")
    text = f.read()
    i = 0

    while i < len(transforms):
        text = transforms[i].sub(transforms[i + 1], text)
        i += 2

    f.seek(0)
    f.truncate()
    f.write(text)
    f.close()
