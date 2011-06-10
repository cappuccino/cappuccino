/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

var GRADIENT_NORMAL,
    GRADIENT_HIGHLIGHTED,
    IE_FILTER = "progid:DXImageTransform.Microsoft.gradient(startColorstr='#fcfcfc', endColorstr='#dfdfdf')";

@implementation _CPRuleEditorPopUpButton : CPPopUpButton
{
    CPInteger radius;
}

+ (void)initialize
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine))
    {
        GRADIENT_NORMAL = "-webkit-gradient(linear, left top, left bottom, from(rgb(252, 252, 252)), to(rgb(223, 223, 223)))",
        GRADIENT_HIGHLIGHTED = "-webkit-gradient(linear, left top, left bottom, from(rgb(223, 223, 223)), to(rgb(252, 252, 252)))";
    }
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
    {
        GRADIENT_NORMAL = "-moz-linear-gradient(top,  rgb(252, 252, 252),  rgb(223, 223, 223))",
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

        [self setTextColor:[CPColor colorWithWhite:101/255 alpha:1]];
        [self setBordered:NO];
     }

    return self;
}

- (id)hitTest:(CPPoint)point
{
    var slice = [self superview];
    if (!CPRectContainsPoint([self frame], point) || ![self sliceIsEditable])
        return nil;

    return self;
}

- (void)setHighlighted:(BOOL)shouldHighlight
{
    _DOMElement.style.backgroundImage = (shouldHighlight) ? GRADIENT_HIGHLIGHTED : GRADIENT_NORMAL;
}

- (BOOL)sliceIsEditable
{
    return [[self superview] isEditable];
}

- (BOOL)trackMouse:(CPEvent)theEvent
{
    if (![self sliceIsEditable])
        return NO;

    return [super trackMouse:theEvent];
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentRect = [super contentRectForBounds:bounds];
    contentRect.origin.x += radius;
    contentRect.size.width -= 2 * radius;

    return contentRect;
}

- (void)layoutSubviews
{
    radius = FLOOR(CGRectGetHeight([self bounds])/2);

    var style = _DOMElement.style,
        radiusCSS = radius + "px";

    //style.webkitBorderRadius = radiusCSS;
    //style.mozBorderRadius = radiusCSS;
    style.borderRadius = radiusCSS;

    [super layoutSubviews];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    var arrow_width = FLOOR(CGRectGetHeight(bounds)/3.5);

    CGContextTranslateCTM(context, CGRectGetWidth(bounds) - radius - arrow_width, CGRectGetHeight(bounds) / 2);

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

@end

@implementation _CPRuleEditorButton : CPButton
{
    CPInteger radius;
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

@end

