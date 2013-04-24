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

@global CP_NSMapClassName

var FILE = require("file"),
    imageSize = require("cappuccino/imagesize").imagesize;

@implementation _CPCibCustomResource (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _className = CP_NSMapClassName([aCoder decodeObjectForKey:@"NSClassName"]);
        _resourceName = [aCoder decodeObjectForKey:@"NSResourceName"];

        var size = CGSizeMakeZero(),
            framework = @"",
            bundleIdentifier = @"";

        if (_resourceName == "NSSwitch")
            return nil;
        else if (_resourceName == "NSAddTemplate" || _resourceName == "NSRemoveTemplate")
        {
            // Defer resolving this path until runtime.
            _resourceName = _resourceName.replace("NS", "CP");
        }
        else
        {
            var match = /^(.+)@(.+)$/.exec(_resourceName);

            if (match)
            {
                _resourceName = match[1];
                framework = match[2];
            }

            var resourceInfo = [aCoder resourceInfoForName:_resourceName inFramework:framework];

            if (!resourceInfo)
                CPLog.warn("Resource \"" + _resourceName + "\" not found in the Resources directories");
            else
            {
                size = imageSize(FILE.canonical(resourceInfo.path)) || CGSizeMakeZero();
                framework = resourceInfo.framework;
            }

            // Account for the fact that an extension may have been inferred.
            if (resourceInfo &&
                resourceInfo.path &&
                FILE.extension(resourceInfo.path) !== FILE.extension(_resourceName))
            {
                _resourceName += FILE.extension(resourceInfo.path);
            }
        }

        if (resourceInfo && resourceInfo.path && resourceInfo.framework)
        {
            var frameworkPath = FILE.dirname(FILE.dirname(resourceInfo.path)),
                bundle = [CPBundle bundleWithPath:frameworkPath];

            [bundle loadWithDelegate:nil];
            bundleIdentifier = [bundle bundleIdentifier] || @"";
        }

        _properties = @{ @"size":size, @"bundleIdentifier":bundleIdentifier, @"framework":framework };

        CPLog.debug("    Resource: %s\n   Framework: %s%s\n        Path: %s\n        Size: %d x %d",
                    _resourceName,
                    framework ? framework : "<none>",
                    bundleIdentifier ? " (" + bundleIdentifier + ")" :
                                        framework ? " (<no bundle identifier>)" : "",
                    resourceInfo ? FILE.canonical(resourceInfo.path) : "",
                    size.width,
                    size.height);
   }

    return self;
}

@end


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
