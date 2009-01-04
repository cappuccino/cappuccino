/*
 * _CPCibCustomView.j
 * AppKit
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

@import "CPView.j"


/* @ignore */

@implementation _CPCibCustomView : CPView
{
    CPString    _className;
}

- (CPString)customClassName
{
    return _className;
}

@end

var _CPCibCustomViewClassNameKey    = @"_CPCibCustomViewClassNameKey";

@implementation _CPCibCustomView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        _className = [aCoder decodeObjectForKey:_CPCibCustomViewClassNameKey];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_className forKey:_CPCibCustomViewClassNameKey];
}

- (id)_cibInstantiate
{
    var theClass = CPClassFromString(_className);
    
    // If we don't have this class, just use CPView.
    // FIXME: Should we instead throw an exception?
    if (!theClass)
    {
        CPLog("Unknown class \"" + _className + "\" in cib file, using CPView instead.");
        
        theClass = [CPView class];
    }

    var view = [[theClass alloc] initWithFrame:[self frame]];
        
    if (view)
    {
        view._superview = _superview;
        view._window = _window; // Doesn't matter that we don't call _setWindow: since nothing has a window yet anyways(?)
        
        [view setBounds:[self bounds]];
        
        // Since the object replacement logic hasn't had a chance to kick in yet, we need to do it manually:
        
        // we need to copy subviews since each time we add a subview to a different view its removed from the original subviews array
        var subviews = [[self subviews] copy],
            index = 0,
            count = subviews.length;
        
        for (; index < count; ++index)
            [view addSubview:subviews[index]];

        [view setAutoresizingMask:[self autoresizingMask]];
        [view setAutoresizesSubviews:[self autoresizesSubviews]];
    
        [view setHitTests:[self hitTests]];
        [view setHidden:[self isHidden]];
        [view setAlphaValue:[self alphaValue]];
    
        [view setBackgroundColor:[self backgroundColor]];
    }
    
    return view;
}

@end
