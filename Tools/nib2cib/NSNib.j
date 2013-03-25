/*
 * NSNib.j
 * nib2cib
 *
 * Created by cacaodev.
 * Copyright 2013, Cappuccino Foundation.
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

@import <AppKit/CPCib.j>

@class Converter

var FILE = require("file"),
    OS = require("os"),
    UUID = require("uuid");

@implementation CPCib (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    var nibPath = @"/tmp/" + UUID.uuid() + ".nib",
        data = [aCoder decodeObjectForKey:@"NSNibFileData"],
        sharedConverter = [Converter sharedConverter];

    FILE.write(nibPath, data.bytes(), { charset:"UTF-16" });

    var converter = [[Converter alloc] initWithInputPath:@""
                                                  format:[sharedConverter format]
                                                  themes:[sharedConverter themes]];
    [converter setCompileNib:NO];
    [converter setResourcesPath:[sharedConverter resourcesPath]];
    [converter setUserNSClasses:[sharedConverter userNSClasses]];

    CPLog.info("Converting sub nib to plist...");

    var nibData = [converter CPCompliantNibDataAtFilePath:nibPath];
    _data = [converter convertedDataFromMacData:nibData resourcesPath:[sharedConverter resourcesPath]];

    return self;
}

@end

@implementation NSNib : CPCib
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCib class];
}

@end
