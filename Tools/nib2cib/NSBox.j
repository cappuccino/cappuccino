/*
 * NSBox.j
 * nib2cib
 *
 * Created by Aparajita Fishman.
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

@import <AppKit/CPBox.j>


@implementation CPBox (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _boxType       = [aCoder decodeIntForKey:@"NSBoxType"];
        _borderType    = [aCoder decodeIntForKey:@"NSBorderType"];

        _borderColor   = [aCoder decodeObjectForKey:@"NSBorderColor2"] || [CPColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.42];
        _fillColor     = [aCoder decodeObjectForKey:@"NSFillColor2"] || [CPColor clearColor];

        _cornerRadius  = [aCoder decodeFloatForKey:@"NSCornerRadius2"];
        _borderWidth   = [aCoder decodeFloatForKey:@"NSBorderWidth2"] || 1.0;

        _contentMargin = [aCoder decodeSizeForKey:@"NSOffsets"];

        _title         = [[aCoder decodeObjectForKey:@"NSTitleCell"] objectValue] || @"";
        _titlePosition = [aCoder decodeObjectForKey:@"NSTitlePosition"];

        if (_titlePosition === undefined)
            _titlePosition = CPAtTop;
    }

    return self;
}

@end

@implementation NSBox : CPBox
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPBox class];
}

@end
