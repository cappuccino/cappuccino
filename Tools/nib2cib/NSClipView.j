/*
 * NSClipView.j
 * nib2cib
 *
 * Created by Thomas Robinson.
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

@import <AppKit/CPClipView.j>


var NSClipViewDrawBackgroundFlag = 0x04;


@implementation CPClipView (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _documentView = [aCoder decodeObjectForKey:@"NSDocView"];

        var flags = [aCoder decodeIntForKey:@"NScvFlags"];

        if ((flags & NSClipViewDrawBackgroundFlag) && [aCoder containsValueForKey:@"NSBGColor"])
            [self setBackgroundColor:[aCoder decodeObjectForKey:@"NSBGColor"]];
    }

    return self;
}

- (BOOL)NS_isFlipped
{
    return YES;
}

@end

@implementation NSClipView : CPClipView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPClipView class];
}

@end
