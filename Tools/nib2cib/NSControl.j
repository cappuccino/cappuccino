/*
 * NSControl.j
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

@import <AppKit/CPControl.j>

@import "NSCell.j"
@import "NSView.j"


@class Nib2Cib


@implementation CPControl (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        // Enabled state is derived from the NSEnabled flag or the control's cell.
        // For example NSTableView uses the NSEnabled flag, but NSButton uses it's cell isEnabled state.
        // We use the NSEnabled flag here and override the behavior in controls using different logic (NSButton).
        [self setEnabled:[aCoder decodeBoolForKey:@"NSEnabled"]];

        [self sendActionOn:CPLeftMouseUpMask];
        [self setTarget:[aCoder decodeObjectForKey:@"NSTarget"]];
        [self setAction:[aCoder decodeObjectForKey:@"NSAction"]];

        // In IB, both cells and controls can have tags.
        // If the control has a tag, that takes precedence.
        if ([aCoder containsValueForKey:@"NSTag"])
            [self setTag:[aCoder decodeIntForKey:@"NSTag"]];
    }

    return self;
}

- (void)NS_initWithCell:(NSCell)cell
{
    [self setSendsActionOnEndEditing:[cell sendsActionOnEndEditing]];
    [self setObjectValue:[cell objectValue]];
    [self setFont:[cell font]];
    [self setAlignment:[cell alignment]];
    [self setContinuous:[cell isContinuous]];
    [self setLineBreakMode:[cell lineBreakMode]];
    [self setFormatter:[cell formatter]];
    [self setControlSize:[cell controlSize]];
}

- (CGRect)_nib2CibAdjustment
{
    // Theme has not been loaded yet.
    // Get attribute value directly from the theme or from the default value of the object otherwise.
    var theme = [Nib2Cib defaultTheme];

    return [theme valueForAttributeWithName:@"nib2cib-adjustment-frame" inState:[self themeState] forClass:[self class]] || [self currentValueForThemeAttribute:@"nib2cib-adjustment-frame"];
}

- (void)_adjustNib2CibSize
{
    var frame = [self frame],
        frameAdjustment = [self _nib2CibAdjustment];

    if (frameAdjustment)
    {
        var finalFrame = CGRectMake(frame.origin.x + frameAdjustment.origin.x, frame.origin.y - frameAdjustment.origin.y, frame.size.width + frameAdjustment.size.width, frame.size.height + frameAdjustment.size.height);
        [self setFrame:finalFrame];
    }
}

@end

@implementation NSControl : CPControl

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
    return [CPControl class];
}

@end
