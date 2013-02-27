/*
 * NSColorWell.j
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

@import <AppKit/CPColorWell.j>

@import "NSCell.j"
@import "NSControl.j"


@implementation CPColorWell (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        // NSColorWell keeps its own enabled state, there is no cell enabled state
        [self setEnabled:[aCoder decodeBoolForKey:@"NSEnabled"]];
        [self setBordered:[aCoder decodeBoolForKey:@"NSIsBordered"]];
        [self setColor:[aCoder decodeObjectForKey:@"NSColor"]];

        if ([self isBordered])
        {
            var frameSize = [self frameSize];
            CPLog.debug("NSColorWell: adjusting height from %d to %d", frameSize.height, 24.0);
            frameSize.height = 24.0;
            [self setFrameSize:frameSize];
        }
    }

    return self;
}

@end

@implementation NSColorWell : CPColorWell
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPColorWell class];
}

@end
