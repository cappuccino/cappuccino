/*
 * CPRuleEditorPopUpButton.j
 * AppKit
 *
 * Created by cacaodev@gmail.com
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

var GRADIENT_NORMAL,
    GRADIENT_HIGHLIGHTED,
    IE_FILTER = "progid:DXImageTransform.Microsoft.gradient(startColorstr='#fcfcfc', endColorstr='#dfdfdf')";

@implementation CPRuleEditorPopUpButton : CPPopUpButton
{
    CPInteger _radius;
    BOOL _isEditable @accessors(property=editable);
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
    if (self = [super initWithFrame:aFrame])
    {
        var style = _DOMElement.style;
        style.backgroundImage = GRADIENT_NORMAL;
        style.border = "1px solid rgb(189, 189, 189)";
        style.filter = IE_FILTER;
        
        _radius=9.0;
        _isEditable=YES;

        [self setTextColor:[CPColor colorWithWhite:0 alpha:1]];
        [self setBordered:NO];
     }

    return self;
}

-(BOOL)editable
{
	return [self enabled];
}

-(void)setEditable:(BOOL)isEditable
{
	[self setEnabled:isEditable];
}

- (void)setHighlighted:(BOOL)shouldHighlight
{
    _DOMElement.style.backgroundImage = (shouldHighlight) ? GRADIENT_HIGHLIGHTED : GRADIENT_NORMAL;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentRect = [super contentRectForBounds:bounds];
    contentRect.origin.x += _radius;
    contentRect.size.width -= 2 * _radius;

    return contentRect;
}

- (void)layoutSubviews
{
    _radius = FLOOR(CGRectGetHeight([self bounds])/2);

    var style = _DOMElement.style,
        radiusCSS = _radius + "px";

    style.borderRadius=radiusCSS;

    [super layoutSubviews];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    var arrow_width = FLOOR(CGRectGetHeight(bounds)/3.5);

    CGContextTranslateCTM(context, CGRectGetWidth(bounds) - _radius - arrow_width, CGRectGetHeight(bounds) / 2);

    var arrowsPath = [CPBezierPath bezierPath];
    [arrowsPath moveToPoint:CGPointMake(0, 1)];
    [arrowsPath lineToPoint:CGPointMake(arrow_width, 1)];
    [arrowsPath lineToPoint:CGPointMake(arrow_width/2, arrow_width + 1)];
    [arrowsPath closePath];

    CGContextSetFillColor(context, [CPColor colorWithWhite:101/255 alpha:1]);
    [arrowsPath fill];

    CGContextScaleCTM(context, 1 , -1);
    [arrowsPath fill];
}

-(BOOL)acceptsFirstResponder
{
    return NO;
}

@end
