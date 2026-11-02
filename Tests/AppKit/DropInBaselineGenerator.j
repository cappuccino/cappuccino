/*
 *  DropInBaselineGenerator.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "DropInSnapshot.j"

/*
    Saves the drop-in baseline. Run this only against a build of main, and only
    when a change to the drop-in contract is deliberate:

        objj Tests/AppKit/DropInBaselineGenerator.j
*/
var fs = require("fs"),
    path = require("path");

function main(args, namedArgs)
{
    [[CPApplication alloc] init];

    var skipped = [],
        snapshot = DropInCreateSnapshot(YES, skipped),
        baselinePath = path.join(process.cwd(), "Tests", "AppKit", "Resources", "DropInBaseline.json");

    fs.writeFileSync(baselinePath, JSON.stringify(snapshot, null, 1) + "\n");

    print("Wrote " + baselinePath);
    print(snapshot.publicClasses.length + " public classes, " +
          Object.keys(snapshot.themeAttributes).length + " themed classes, " +
          Object.keys(snapshot.construction).length + " constructed views, " +
          Object.keys(snapshot.windows).length + " window styles");
    skipped.forEach(function(aLine) { print("skipped " + aLine); });
}
