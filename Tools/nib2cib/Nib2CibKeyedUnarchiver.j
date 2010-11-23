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

var FILE = require("file");


@implementation Nib2CibKeyedUnarchiver : CPKeyedUnarchiver
{
    CPString    resourcesPath @accessors(readonly);
}

- (id)initForReadingWithData:(CPData)data resourcesPath:(CPString)aResourcesPath
{
    self = [super initForReadingWithData:data];

    if (self)
        resourcesPath = aResourcesPath;

    return self;
}

- (CPArray)allObjects
{
    return _objects;
}

- (CPString)resourcePathForName:(CPString)aName
{
    if (!resourcesPath)
        return NULL;

    var pathGroups = [FILE.listPaths(resourcesPath)];

    while (pathGroups.length > 0)
    {
        var paths = pathGroups.shift(),
            index = 0,
            count = paths.length;

        for (; index < count; ++index)
        {
            var path = paths[index];

            if (FILE.basename(path) === aName)
                return path;

            else if (FILE.isDirectory(path))
                pathGroups.push(FILE.listPaths(path));

            else if (!FILE.extension(aName) && FILE.basename(path).replace(/\.[^.]*$/, "") === aName)
                return path;
        }
    }

    return NULL;
}

@end

FILE.listPaths = function(aPath)
{
    var paths = FILE.list(aPath),
        count = paths.length;

    while (count--)
        paths[count] = FILE.join(aPath, paths[count]);

    return paths;
}
