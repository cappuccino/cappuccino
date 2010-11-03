/*
 * NSCustomResource.j
 * nib2cib
 *
 * Portions based on NSCustomResource.m (01/08/2009) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
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

@import <AppKit/_CPCibCustomResource.j>

var FILE = require("file");

@implementation _CPCibCustomResource (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _className = CP_NSMapClassName([aCoder decodeObjectForKey:@"NSClassName"]);
        _resourceName = [aCoder decodeObjectForKey:@"NSResourceName"];

        var size = CGSizeMakeZero();

        if (![[aCoder resourcesPath] length])
            CPLog.warn("*** WARNING: Resources found in nib, but no resources path specified with -R option.");
        else
        {
            var resourcePath = [aCoder resourcePathForName:_resourceName];

            if (!resourcePath)
                CPLog.warn("*** WARNING: Resource named " + _resourceName + " not found in supplied resources path.");
            else
                size = imageSize(FILE.join(FILE.cwd(), resourcePath));

            // Account for the fact that an extension may have been inferred.
            if (resourcePath && FILE.extension(resourcePath) !== FILE.extension(_resourceName))
                _resourceName += FILE.extension(resourcePath);
        }

        _properties = [CPDictionary dictionaryWithObject:size forKey:@"size"];
    }

    return self;
}

@end

var ImageUtility = require("cappuccino/image-utility"),
    imageSize = ImageUtility.sizeOfImageAtPath;

@implementation NSCustomResource : _CPCibCustomResource
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibCustomResource class];
}

@end
