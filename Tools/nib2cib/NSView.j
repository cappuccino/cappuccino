/*
 * NSView.j
 * nib2cib
 *
 * Portions based on NSView.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
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

@import <AppKit/CPView.j>


var NSViewAutoresizingMask = 0x3F,
    NSViewAutoresizesSubviewsMask = 1 << 8,
    NSViewHiddenMask = 1 << 31;

@implementation CPView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    _frame = CGRectMakeZero();

    if ([aCoder containsValueForKey:@"NSFrame"])
        _frame = [aCoder decodeRectForKey:@"NSFrame"];
    else if ([aCoder containsValueForKey:@"NSFrameSize"])
        _frame.size = [aCoder decodeSizeForKey:@"NSFrameSize"];

    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _tag = [aCoder decodeIntForKey:@"NSTag"];

        _bounds = CGRectMake(0.0, 0.0, CGRectGetWidth(_frame), CGRectGetHeight(_frame));

        _window = [aCoder decodeObjectForKey:@"NSWindow"];
        _superview = [aCoder decodeObjectForKey:@"NSSuperview"];
        _subviews = [aCoder decodeObjectForKey:@"NSSubviews"];

        if (!_subviews)
            _subviews = [];

        var vFlags = [aCoder decodeIntForKey:@"NSvFlags"];

        _autoresizingMask = vFlags & NSViewAutoresizingMask;
        _autoresizesSubviews = vFlags & NSViewAutoresizesSubviewsMask;

        _hitTests = YES;
        _isHidden = vFlags & NSViewHiddenMask;
        _opacity = 1.0;//[aCoder decodeIntForKey:CPViewOpacityKey];

        _themeClass = [self themeClass];
        _themeAttributes = {};
        _themeState = CPThemeStateNormal;
        [self _loadThemeAttributes];
        
        if ([aCoder containsValueForKey:@"NSReuseIdentifierKey"])
            _identifier = [aCoder decodeObjectForKey:@"NSReuseIdentifierKey"];
    }

    return self;
}

- (BOOL)NS_isFlipped
{
    return NO;
}

- (void)awakeFromNib
{
    var superview = [self superview];

    if (!superview || [superview NS_isFlipped])
        return;

    var superviewHeight = CGRectGetHeight([superview bounds]),
        frame = [self frame];

    [self setFrameOrigin:CGPointMake(CGRectGetMinX(frame), superviewHeight - CGRectGetMaxY(frame))];

    var NS_autoresizingMask = [self autoresizingMask],
        autoresizingMask = NS_autoresizingMask & ~(CPViewMaxYMargin | CPViewMinYMargin);

    if (!(NS_autoresizingMask & (CPViewMaxYMargin | CPViewMinYMargin | CPViewHeightSizable)))
        autoresizingMask |= CPViewMinYMargin;
    else
    {
        if (NS_autoresizingMask & CPViewMaxYMargin)
            autoresizingMask |= CPViewMinYMargin;
        if (NS_autoresizingMask & CPViewMinYMargin)
            autoresizingMask |= CPViewMaxYMargin;
    }

    [self setAutoresizingMask:autoresizingMask];
}

@end

@implementation NSView : CPView

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPView class];
}

@end

