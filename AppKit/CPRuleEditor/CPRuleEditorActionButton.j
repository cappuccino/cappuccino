/*
 * CPRuleEditorActionButton.j
 * AppKit
 *
 * Created by JC Bordes [jcbordes at gmail dot com] Copyright 2012 JC Bordes
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
 
 @import <AppKit/CPButton.j>

var GRADIENT_NORMAL;
var GRADIENT_HIGHLIGHTED;
var IE_FILTER = "progid:DXImageTransform.Microsoft.gradient(startColorstr='#fcfcfc', endColorstr='#dfdfdf')";

@implementation CPRuleEditorActionButton : CPButton
{
    CPInteger radius;
}

+ (void)initialize
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine))
    {
        GRADIENT_NORMAL = "-webkit-gradient(linear, left top, left bottom, from(rgb(252, 252, 252)), to(rgb(223, 223, 223)))";
        GRADIENT_HIGHLIGHTED = "-webkit-gradient(linear, left top, left bottom, from(rgb(223, 223, 223)), to(rgb(252, 252, 252)))";
    }
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
    {
        GRADIENT_NORMAL = "-moz-linear-gradient(top,  rgb(252, 252, 252),  rgb(223, 223, 223))";
        GRADIENT_HIGHLIGHTED = "-moz-linear-gradient(top,  rgb(223, 223, 223),  rgb(252, 252, 252))";
    }
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        [self setFont:[CPFont boldFontWithName:@"Apple Symbol" size:12.0]];
        [self setTextColor:[CPColor colorWithWhite:150/255 alpha:1]];
        [self setAlignment:CPCenterTextAlignment];
        [self setAutoresizingMask:CPViewMinXMargin];
        [self setImagePosition:CPImageOnly];
        [self setBordered:NO];
        var style = _DOMElement.style;
        style.border = "1px solid rgb(189, 189, 189)";
        style.filter = IE_FILTER;
    }

    return self;
}

- (void)layoutSubviews
{
    radius = FLOOR(CGRectGetHeight([self bounds])/2);

    var style = _DOMElement.style,
        radiusCSS = radius + "px";

    style.borderRadius = radiusCSS;
    style.backgroundImage = ([self isHighlighted]) ? GRADIENT_HIGHLIGHTED : GRADIENT_NORMAL;

    [super layoutSubviews];
}

-(BOOL)acceptsFirstResponder
{
    return NO;
}

@end
