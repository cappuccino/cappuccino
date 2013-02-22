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


@implementation CPBox (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _boxType       = [aCoder decodeIntForKey:@"NSBoxType"];
        _borderType    = [aCoder decodeIntForKey:@"NSBorderType"];

        var borderColor = [aCoder decodeObjectForKey:@"NSBorderColor2"],
            fillColor = [aCoder decodeObjectForKey:@"NSFillColor2"],
            cornerRadius = [aCoder decodeFloatForKey:@"NSCornerRadius2"],
            borderWidth = [aCoder decodeFloatForKey:@"NSBorderWidth2"],
            contentMargin = [aCoder decodeSizeForKey:@"NSOffsets"];

        // small hack to position the box pixel perfect
        var frame = [self frame];

        // The primary and secondary boxes have a well-like look both in Cocoa and Cappuccino, but there
        // are some sizing differences. Regular custom boxes have no size differences.
        if (_boxType !== CPBoxSeparator && (_boxType === CPBoxPrimary || _boxType === CPBoxSecondary))
        {
            frame.origin.y += 4;
            frame.origin.x += 4;
            frame.size.width -= 8;
            frame.size.height -= 6;
        }

        [self setFrame:frame];

        if (_boxType !== CPBoxPrimary && _boxType !== CPBoxSecondary)
        {
            // Primary and secondary boxes have a fixed look that can't be customised, but for a CPBoxCustom
            // all of these parameters can be changed.
            if (borderColor)
                [self setBorderColor:borderColor];

            if (fillColor)
                [self setFillColor:fillColor];

            [self setCornerRadius:cornerRadius];
            [self setBorderWidth:borderWidth];
            [self setContentViewMargins:contentMargin];
        }

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
