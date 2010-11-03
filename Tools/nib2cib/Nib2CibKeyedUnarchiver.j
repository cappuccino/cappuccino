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

var File = require("file");


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

    var pathGroups = [File.listPaths(resourcesPath)];

    while (pathGroups.length > 0)
    {
        var paths = pathGroups.shift(),
            index = 0,
            count = paths.length;

        for (; index < count; ++index)
        {
            var path = paths[index];

            if (File.basename(path) === aName)
                return path;

            else if (File.isDirectory(path))
                pathGroups.push(File.listPaths(path));

            else if (!File.extension(aName))
            {
                var extensions = ["png", "gif", "jpg", "jpeg", "cib"],
                    extensionCount = extensions.length,
                    extension;

                while(extensionCount--)
                {
                    if (File.basename(path) === aName+"."+extensions[extensionCount])
                        return path;
                }
            }
        }
    }

    return NULL;
}

@end

File.listPaths = function(aPath)
{
    var paths = File.list(aPath),
        count = paths.length;

    while (count--)
        paths[count] = File.join(aPath, paths[count]);

    return paths;
}
