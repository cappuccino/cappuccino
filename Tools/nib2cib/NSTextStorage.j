/*
 * NSTextStorage.j
 * nib2cib
 *
 * Created by Alexendre Wilhelm.
 * Copyright 2014 The Cappuccino Foundation.
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

@import <AppKit/CPTextStorage.j>

@class Nib2Cib

@global CPForegroundColorAttributeName

@implementation CPTextStorage (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var xibAttributes = [aCoder decodeObjectForKey:@"NSAttributes"],
        cibAttributes = @{};

    if ([xibAttributes containsKey:@"NSColor"])
        [cibAttributes setObject:[xibAttributes valueForKey:@"NSColor"] forKey:CPForegroundColorAttributeName];

    if ([xibAttributes containsKey:@"NSFont"])
        [cibAttributes setObject:[xibAttributes valueForKey:@"NSFont"] forKey:CPFontAttributeName];

    if ([xibAttributes containsKey:@"NSParagraphStyle"])
        [cibAttributes setObject:[xibAttributes valueForKey:@"NSParagraphStyle"] forKey:CPParagraphStyleAttributeName];

    self = [super initWithString:[aCoder decodeObjectForKey:@"NSString"] attributes:cibAttributes];

    return self;
}

@end

@implementation NSTextStorage : CPTextStorage
{

}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {

    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPTextStorage class];
}

@end
