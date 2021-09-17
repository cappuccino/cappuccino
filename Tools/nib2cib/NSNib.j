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

var fs = require("fs");
var os = require("os");
var path = require("path");

@implementation CPCib (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    function getRandomIntInclusive(min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min + 1) + min);
    }

    function generateID(length) {
        var ret = "";
        var alphaNum = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        for (var i = 0; i < length; i++) {
            ret += alphaNum[getRandomIntInclusive(0, alphaNum.length-1)];
        }
        return ret;
    }
    
    self = [super init];

    var nibPath = path.join(os.tmpDir(), "nib2cib-" + generateID(40) + ".nib"),
        data = [aCoder decodeObjectForKey:@"NSNibFileData"];

    fs.writeFileSync(nibPath, new Uint8Array(data.bytes()), { encoding: "utf16le" });

    //FILE.write(nibPath, data.bytes(), { charset:"UTF-16" });

    var converter = [[Converter alloc] initWithInputPath:nibPath outputPath:nil];

    _data = [converter convert];

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
