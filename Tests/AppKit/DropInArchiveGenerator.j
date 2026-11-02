/*
 *  DropInArchiveGenerator.j
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

@import "DropInArchiveFixtures.j"

/*
    Saves the archive test data. Run this only against a build of main:

        objj Tests/AppKit/DropInArchiveGenerator.j

    It saves a description of what each reference cib produces. It then saves an
    archive of each view fixture, with the fixture's description before archiving.
    An archive is saved only if it restores that description, so a failure stops
    the generator and no archive data is written.
*/
var fs = require("fs"),
    path = require("path");

function main(args, namedArgs)
{
    [[CPApplication alloc] init];

    var resources = path.join(process.cwd(), "Tests", "AppKit", "Resources"),
        cibFolder = path.join(resources, "DropInCibs"),
        archives = {},
        cibs = {},
        failures = [];

    fs.readdirSync(cibFolder).sort().forEach(function(aName)
    {
        cibs[aName] = DropInCibTree(aName, fs.readFileSync(path.join(cibFolder, aName), {encoding: 'utf-8'}));
        print(aName + ": " + cibs[aName].length + " top level objects");
    });

    fs.writeFileSync(path.join(resources, "DropInCibs.json"), JSON.stringify(cibs, null, 1) + "\n");

    DropInSortedClasses().forEach(function(aClass)
    {
        var name = aClass.name;

        if (!DropInIsPublicName(name) || !DropInClassIsView(aClass))
            return;

        if (DropInArchiveExclusion(name))
            return print("excluded " + name + ": " + DropInArchiveExclusion(name));

        try
        {
            var result = DropInArchiveRoundTrip(aClass),
                differences = DropInTreeDifferences(result.original, result.decoded, name, []);

            if (differences.length)
                failures = failures.concat(differences);
            else
                archives[name] = { @"archive": result.archive, @"state": result.original };
        }
        catch (anException)
        {
            failures.push(name + ": " + String(anException));
        }
    });

    if (failures.length)
    {
        failures.forEach(function(aLine) { print("failed " + aLine); });
        print(failures.length + " failures, no archive data written");
        process.exit(1);
    }

    fs.writeFileSync(path.join(resources, "DropInArchives.json"), JSON.stringify(archives, null, 1) + "\n");

    print(Object.keys(archives).length + " archived view classes");
}
