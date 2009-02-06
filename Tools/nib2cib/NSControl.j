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


@implementation CPControl (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        [self sendActionOn:CPLeftMouseUpMask];
        
        // Shoudl we stub this out?
        
        var theme = nil,
            theClass = [self class];
        
        _alignment = CPThemedValueMake(CPLeftTextAlignment, "alignment", theme, theClass);
        _verticalAlignment = CPThemedValueMake(CPTopVerticalTextAlignment, "vertical-alignment", theme, theClass);
        
        _lineBreakMode = CPThemedValueMake(CPLineBreakByClipping, "line-break-mode", theme, theClass);
        _textColor = CPThemedValueMake([CPColor blackColor], "text-color", theme, theClass);
        _font = CPThemedValueMake([CPFont systemFontOfSize:12.0], "font", theme, theClass);
        
        _textShadowColor = CPThemedValueMake(nil, @"text-shadow-color", theme, theClass);
        _textShadowOffset = CPThemedValueMake(CGSizeMake(0.0, 0.0), "text-shadow-offset", theme, theClass);
        
        _imagePosition = CPThemedValueMake(CPImageLeft, @"image-position", theme, theClass);
        _imageScaling = CPThemedValueMake(CPScaleToFit, "image-scaling", theme, theClass);
        
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        
        [self setObjectValue:[cell objectValue]];
        
        [self setFont:[cell font]];
        [self setAlignment:[cell alignment]];
        
        [self setEnabled:[aCoder decodeObjectForKey:@"NSEnabled"]];
        [self setContinuous:[cell isContinuous]];
    }
    
    return self;
}

@end

@implementation NSControl : CPControl
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPControl class];
}

@end
