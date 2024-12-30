/*
 * NSKeyedArchiver.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <Foundation/CPKeyedUnarchiver.j>

@import "Nib2CibException.j"

@class Nib2Cib

//var FILE = require("file");

var fs = require("fs");
var node_path = require("path");

@implementation Nib2CibKeyedUnarchiver : CPKeyedUnarchiver
{
}

- (CPArray)allObjects
{
    return _objects;
}

- (JSObject)resourceInfoForName:(CPString)aName inFramework:(CPString)framework
{
    var nib2cib = [Nib2Cib sharedNib2Cib],
        frameworks = [nib2cib frameworks];

    if (framework)
    {
        var info = [frameworks valueForKey:framework];

        if (!info)
            [CPException raise:Nib2CibException format:@"The framework “%@” specified by the image “%@@%@” cannot be found.", framework, aName, framework];
        else if (!info.resourceDirectory)
            [CPException raise:Nib2CibException format:@"The framework “%@” specified by the image “%@@%@” has no Resources directory.", framework, aName, framework];

        var path = [self _resourcePathForName:aName inDirectory:info.resourceDirectory];

        if (path)
            return { path:path, framework:framework };
    }
    else
    {
        // Try the app's resource directory first
        var resourcesDirectory = [nib2cib appResourceDirectory],
            path = [self _resourcePathForName:aName inDirectory:resourcesDirectory];

        if (path)
            return { path:path, framework:framework };

        var enumerator = [frameworks keyEnumerator];

        while ((framework = [enumerator nextObject]))
        {
            var info = [frameworks valueForKey:framework];

            if (!info || !info.resourceDirectory)
                continue;

            path = [self _resourcePathForName:aName inDirectory:info.resourceDirectory];

            if (path)
                return { path:path, framework:framework };
        }
    }

    [CPException raise:Nib2CibException format:@"The image “%@” cannot be found.", aName];
}

- (CPString)_resourcePathForName:(CPString)aName inDirectory:(CPString)directory
{
    var pathGroups = [listPaths(directory)];

    while (pathGroups.length > 0)
    {
        var paths = pathGroups.shift(),
            index = 0,
            count = paths.length;

        for (; index < count; ++index)
        {
            var path = paths[index];

            if (node_path.basename(path) === aName)
                return path;
            else if (fs.lstatSync(path).isDirectory())
                pathGroups.push(listPaths(path));
            else if (!node_path.extname(aName) && node_path.basename(path).replace(/\.[^.]*$/, "") === aName)
                return path;
        }
    }

    return nil;
}

@end

listPaths = function(aPath)
{
    var paths = fs.readdirSync(aPath),
        count = paths.length;

    while (count--)
        paths[count] = node_path.join(aPath, paths[count]);

    return paths;
};
