/*
 * BorderView.j
 * UserlandNSTest
 *
 * Created by aparajita on April 11, 2012.
 * Copyright 2012, The Cappuccino Foundation. All rights reserved.
 */

@import <AppKit/CPColor.j>
@import <AppKit/CPView.j>

BorderViewDefaultBorderWidth = 1.0;
BorderViewDefaultBorderColor = nil;


@implementation BorderView : CPView
{
    int     borderWidth @accessors;
    CPColor borderColor @accessors;
}

+ (void)initialize
{
    if (self === [BorderView class])
        BorderViewDefaultBorderColor = [CPColor colorWithHexString:@"0000ff"];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        borderWidth = BorderViewDefaultBorderWidth;
        borderColor = BorderViewDefaultBorderColor;
    }

    return self;
}

- (void)setBorderWidth:(int)width
{
    if (width === borderWidth)
        return;

    borderWidth = width;
    [self setNeedsDisplay:YES];
}

- (void)setBorderColorWithHexString:(CPString)aColor
{
    CPLog("setBorderColorWithHexString:%s", aColor);

    var hexString = [borderColor hexString] || @"";

    if (aColor.toLowerCase() === hexString.toLowerCase())
        return;

    borderColor = [CPColor colorWithHexString:aColor];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)dirtyRect
{
    var path = [CPBezierPath bezierPathWithRect:CGRectInset([self bounds], borderWidth / 2.0, borderWidth / 2.0)];

    [path setLineWidth:borderWidth];
    [borderColor set];
    [path stroke];
}

@end

var BorderViewBorderWidthKey = @"BorderViewBorderWidthKey",
    BorderViewBorderColorKey = @"BorderViewBorderColorKey";

@implementation BorderView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        borderWidth = [aCoder decodeIntForKey:BorderViewBorderWidthKey];
        borderColor = [aCoder decodeObjectForKey:BorderViewBorderColorKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:borderWidth forKey:BorderViewBorderWidthKey];
    [aCoder encodeObject:borderColor forKey:BorderViewBorderColorKey];
}

@end
