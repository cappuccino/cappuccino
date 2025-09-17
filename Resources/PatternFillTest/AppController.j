/*
 * AppController.j
 * test
 *
 * Created by aparajita on March 7, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPView      contentView;
    MyView      myView;
    CPImage     patternImage1;
    BOOL        patternImage1Loaded;
    CPImage     patternImage2;
    BOOL        patternImage2Loaded;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var x = 20,
        theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    contentView = [theWindow contentView];

    var label1 = [CPTextField labelWithTitle:@"Dynamically drawn"],
        label2 = [CPTextField labelWithTitle:@"Screen capture from IE before COORD fix, notice the fuzziness in the pattern"];

    patternImage1 = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"help.png"] size:CGSizeMake(21, 22)];

    var view2 = [[CPImageView alloc] initWithFrame:CGRectMake(x, 210, 200, 200)],
        img2 = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"bad.png"] size:CGSizeMake(200, 200)];

    patternImage2 = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"pattern.gif"] size:CGSizeMake(56, 32)];

    var fillColor1 = [CPColor colorWithPatternImage:patternImage1],
        fillColor2 = [CPColor colorWithPatternImage:patternImage2];

    [view2 setImage:img2];

    myView = [[MyView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) fillColor1:fillColor1 fillColor2:fillColor2];

    [label1 setFrameOrigin:CGPointMake(x, 20)];
    [myView setFrameOrigin:CGPointMake(x, CGRectGetMaxY([label1 frame]) + 5)];

    [label2 setFrameOrigin:CGPointMake(x, CGRectGetMaxY([myView frame]) + 20)];
    [view2 setFrameOrigin:CGPointMake(x, CGRectGetMaxY([label2 frame]) + 5)];

    var label3 = [CPTextField labelWithTitle:@"Pattern fill with rendered path"];
    [label3 setFrameOrigin:CGPointMake(300, 20)];

    var patternView = [[PatternView alloc] initWithFrame:CGRectMake(300, CGRectGetMaxY([label3 frame]) + 5, 200, 200)];

    // Pattern images MUST be loaded before they are used, so we have to use a load delegate
    // for each image and draw only when we have them all.
    if ([patternImage1 loadStatus] === CPImageLoadStatusCompleted)
        patternImage1Loaded = YES;
    else
    {
        patternImage1Loaded = NO;
        [patternImage1 setDelegate:self];
    }

    if ([patternImage2 loadStatus] === CPImageLoadStatusCompleted)
        patternImage2Loaded = YES;
    else
    {
        patternImage2Loaded = NO;
        [patternImage2 setDelegate:self];
    }

    if (patternImage1Loaded && patternImage2Loaded)
        [self addSubviews];

    [contentView addSubview:label1];
    [contentView addSubview:label2];
    [contentView addSubview:label3];
    [contentView addSubview:myView];
    [contentView addSubview:view2];
    [contentView addSubview:patternView];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)imageDidLoad:(CPImage)anImage
{
    if (anImage == patternImage1)
        patternImage1Loaded = YES;
    else if (anImage == patternImage2)
        patternImage2Loaded = YES;

    if (patternImage1Loaded && patternImage2Loaded)
        [myView setNeedsDisplay:YES];
}

@end

@implementation MyView : CPView
{
    CPColor fillColor1;
    CPColor fillColor2;
}

- (id)initWithFrame:(CGRect)aFrame fillColor1:(CPColor)aColor1 fillColor2:(CPColor)aColor2
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        fillColor1 = aColor1;
        fillColor2 = aColor2;
    }

    return self;
}

- (void)drawRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];

    CGContextSetFillColor(context, fillColor1);
    CGContextFillRect(context, [self bounds]);

    CGContextSetFillColor(context, [CPColor yellowColor]);
    CGContextFillEllipseInRect(context, CGRectInset(bounds, 40, 40));

    CGContextSetStrokeColor(context, [CPColor blueColor]);
    CGContextStrokeRect(context, CGRectInset(bounds, 0.5, 0.5));

    CGContextSetStrokeColor(context, [CPColor redColor]);
    CGContextStrokeEllipseInRect(context, CGRectInset(bounds, 20.5, 20.5));

    CGContextSetStrokeColor(context, [CPColor greenColor]);
    CGContextStrokeRect(context, CGRectInset(bounds, 30.5, 30.5));

    CGContextSetFillColor(context, fillColor2);
    CGContextFillEllipseInRect(context, CGRectInset(bounds, 50, 50));
}

@end

@implementation PatternView : CPView

- (void)drawRect:(CGRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, 0.0, 40.0);
    CGPathAddLineToPoint(path, NULL, 26.9, 36.0);
    CGPathAddCurveToPoint(path, NULL, 31.7, 36.0, 36.0, 32.1, 36.0, 27.3);
    CGPathAddLineToPoint(path, NULL, 40.0, 0.0);
    CGPathAddLineToPoint(path, NULL, 11.8, 3.0);
    CGPathAddCurveToPoint(path, NULL, 7.0, 3.0, 3.0, 6.9, 3.0, 11.7);
    CGPathAddLineToPoint(path, NULL, 0.0, 40.0);
    CGPathCloseSubpath(path);

    var patternContext = CGContextCreatePatternContext(context, CGSizeMake(50, 70));

    CGContextSetFillColor(patternContext, [CPColor colorWithRed:188 / 255 green:222 / 255 blue:178 / 255 alpha:1.0]);

    CGContextAddPath(patternContext, path);
    CGContextFillPath(patternContext);

    CGContextSetLineWidth(patternContext, 0.8);
    CGContextSetStrokeColor(patternContext, [CPColor colorWithRed:0 green:156 / 255 blue:86 / 255 alpha:1.0]);
    CGContextSetLineJoin(patternContext, "miter");
    CGContextSetMiterLimit(patternContext, 4.0);

    CGContextAddPath(patternContext, path);
    CGContextStrokePath(patternContext);

    var bounds = [self bounds];

    CGContextSetFillPattern(context, patternContext);
    CGContextFillRect(context, bounds);

    CGContextSetStrokeColor(context, [CPColor blueColor]);
    CGContextStrokeRect(context, CGRectInset(bounds, 0.5, 0.5));
}

@end

