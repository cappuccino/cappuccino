/*
 * _CPToolTipWindowView.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2011 <primalmotion@archipelproject.org>
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

@import "_CPWindowView.j"


@implementation _CPToolTipWindowView : _CPWindowView
{
    BOOL        _mouseDownPressed   @accessors(getter=isMouseDownPressed, setter=setMouseDownPressed:);
    unsigned    _gravity            @accessors(property=gravity);
}

#pragma mark -
#pragma mark Class methods

+ (CPString)defaultThemeClass
{
    return @"tooltip";
}

+ (CPDictionary)themeAttributes
{
    return @{
        // 1. The DOM-based CSS rendering attributes. 
        // _CPWindowView will natively apply this to the outer window bounds.
        @"bezel-color":[CPColor colorWithCSSDictionary:@{
            @"background-color": @"#FFFFCA",
            @"border": @"1px solid #B0B0B0",
            @"border-radius": @"2px",
            @"box-sizing": @"border-box",
            @"box-shadow": @"0px 1px 3px rgba(0,0,0,0.25)"
        }],
        @"color": [CPColor blackColor],
        
        // 2. Legacy attributes zeroed out to satisfy the build process/theme inheritance
        @"background-color": [CPColor clearColor],
        @"stroke-color": [CPColor clearColor],
        @"stroke-width": 0.0,
        @"border-radius": 0.0
    };
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [super contentRectForFrameRect:aFrameRect];

    // This pushes the text inwards so it doesn't touch the outer CSS border
    contentRect.origin.x += 3;
    contentRect.origin.y += 3;
    contentRect.size.width -= 6;
    contentRect.size.height -= 6;

    return contentRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var aFrameRect = CGRectMakeCopy(aContentRect);

    aFrameRect.origin.x -= 3;
    aFrameRect.origin.y -= 3;
    aFrameRect.size.width += 9;
    aFrameRect.size.height += 9;

    return aFrameRect;
}

#pragma mark -
#pragma mark DOM/CSS Rendering

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Apply the CSS dictionary to the standard CPView subview (contentView).
    // This bypasses the _CPWindowView canvas interceptor and applies directly to the DOM.

    [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];
}

- (void)drawRect:(CGRect)aRect
{
    // Intentionally empty to disable legacy Canvas drawing.
}

@end
