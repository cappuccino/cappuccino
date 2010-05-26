//
//  WebWindow.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/18/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "WebWindow.h"


static NSMutableArray * DisabledWindows;

CFMachPortRef tap_port;

CGEventRef headTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    // It's dangerous to fail in this code: could disable mousedown system-wide. So just try catch it all.
    @try
    {
        [DisabledWindows makeObjectsPerformSelector:@selector(stopIgnoringMouseEvents)];
        [DisabledWindows removeAllObjects];

        if (type == kCGEventLeftMouseDown)
        {
            CGPoint location = CGEventGetLocation(event);
            NSPoint NSLocation = NSMakePoint(location.x, location.y);

            for (NSWindow * window in [NSApp windows])
            {
                if ([window isKindOfClass:[WebWindow class]] && ![(WebWindow *)window hitTest:NSLocation])
                {
                    [window setIgnoresMouseEvents:YES];

                    [DisabledWindows addObject:window];
                }
            }
        }
        else if (type == kCGEventTapDisabledByTimeout)
            CGEventTapEnable(tap_port, YES);

    }
    @catch (NSException * anException)
    {
    }

    return event;
}


@interface WebWindowContentView : NSView
{
}
@end

@implementation WebWindow

+ (void)initialize
{
    if (self != [WebWindow class])
        return;

    DisabledWindows = [[NSMutableArray alloc] init];

    //| CGEventMaskBit(kCGEventTapDisabledByTimeout)
    tap_port = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                                kCGEventTapOptionDefault,
                                CGEventMaskBit(kCGEventLeftMouseDown),
                                headTapCallback, NULL);

    if (NULL == tap_port)
    {
        fprintf(stderr, "Error creating event tap\n");
        return;
    }

    /* Create a run loop source from the tap port, add it to my run loop
     * and start executing the loop
     */
    CFRunLoopSourceRef tap_source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap_port, 0);

    if (NULL == tap_source)
    {
        fprintf(stderr, "Error converting port to run loop source\n");

        if (tap_port != NULL)
            CFRelease(tap_port);

        return;
    }

    CFRunLoopAddSource(CFRunLoopGetCurrent(), tap_source, kCFRunLoopCommonModes);
}

- (id)initWithContentRect:(NSRect)aContentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)aBufferingType defer:(BOOL)shouldDeferCreation
{
    self = [super initWithContentRect:aContentRect styleMask:NSBorderlessWindowMask backing:aBufferingType defer:shouldDeferCreation];

    if (self)
    {
        id delegate = [NSApp delegate];

        shadowView = [[WebWindowContentView alloc] init];

        [self setContentView:shadowView];

        webView = [[WebView alloc] initWithFrame:NSZeroRect];

        [webView setDrawsBackground:NO];
        [webView setUIDelegate:delegate];
        [webView setFrameLoadDelegate:delegate];
        [webView setResourceLoadDelegate:delegate];
        [webView setPolicyDelegate:delegate];
        [webView setShouldCloseWithWindow:YES];

        [shadowView addSubview:webView];

        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self setReleasedWhenClosed:YES];
		[super setHasShadow:NO];
    }

    return self;
}

- (void)setFrame:(NSRect)aFrame display:(BOOL)shouldDisplay
{
    [webView setFrame:NSMakeRect(33.0, 33.0, NSWidth(aFrame), NSHeight(aFrame))];
    [super setFrame:NSInsetRect(aFrame, -33.0, -33.0) display:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self];

    [shadowView release];
    [webView release];
    [super dealloc];
}

- (BOOL)canBecomeKeyWindow
{
    // Necessary since this apparently returns NO for borderless windows.
    return YES;
}

- (NSView *)webHitTest:(NSPoint)aPoint
{
    NSPoint locationInWebView = [[self contentView] convertPoint:aPoint fromView:nil];

    return [(NSView *)[self contentView] hitTest:locationInWebView];
}

- (void)sendEvent:(NSEvent *)anEvent
{
    NSInteger type = [anEvent type];

    if (type == NSLeftMouseDown)
    {
        NSView * view = [self webHitTest:[anEvent locationInWindow]];

        leftMouseDownView = view;

        [view mouseDown:anEvent];
    }

    else if (type == NSLeftMouseDragged)
        [leftMouseDownView mouseDragged:anEvent];

    else if (type == NSLeftMouseUp)
        [leftMouseDownView mouseUp:anEvent];

    else if (type == NSRightMouseDown)
    {
        NSView * view = [self webHitTest:[anEvent locationInWindow]];

        rightMouseDownView = view;

        [view rightMouseDown:anEvent];
    }
    else if (type == NSRightMouseDragged)
        [rightMouseDownView rightMouseDragged:anEvent];

    else if (type == NSRightMouseUp)
        [rightMouseDownView rightMouseUp:anEvent];

    else
        [super sendEvent:anEvent];

    // FIXME: other
}

// Override this to avoid the beep from unhandled events.
- (void)keyDown:(NSEvent *)anEvent
{
}

+ (WebWindow *)webWindow
{
    return [[WebWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
}

- (WebView *)webView
{
    return webView;
}

- (void)updateShadow
{
    [super setHasShadow:hasShadow && shadowStyle == CPCustomWindowShadowStyle];
    [shadowView setNeedsDisplay:YES];
}

- (BOOL)hasShadow
{
    return hasShadow;
}

- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    if (hasShadow == shouldHaveShadow)
        return;

    hasShadow = shouldHaveShadow;

    [self updateShadow];
}

- (CPWindowShadowStyle)shadowStyle
{
    return shadowStyle;
}

- (void)setShadowStyle:(CPWindowShadowStyle)aStyle
{
    if (shadowStyle == aStyle)
        return;

    shadowStyle = aStyle;

    [self updateShadow];
}

- (BOOL)hitTest:(NSPoint)aPoint
{
    NSInteger windowNumber = [[[webView windowScriptObject] valueForKey:@"cpWindowNumber"] intValue];

#if LOGGING
    WebScriptObject * frame = [[[NSApp delegate] windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"(objj_msgSend(objj_msgSend(CPApp, \"windowWithWindowNumber:\", %d), \"frame\"))", windowNumber]],
                    * origin = [frame valueForKey:@"origin"],
                    * size = [frame valueForKey:@"size"];

    NSLog(@"(%f, %f) in { %f, %f, %f, %f }", aPoint.x, aPoint.y, [[origin valueForKey:@"x"] floatValue], [[origin valueForKey:@"y"] floatValue], [[size valueForKey:@"width"] floatValue], [[size valueForKey:@"height"] floatValue]);
#endif

    return [[[[NSApp delegate] windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"(CGRectContainsPoint(objj_msgSend(objj_msgSend(CPApp, \"windowWithWindowNumber:\", %d), \"frame\"), CGPointMake(%f, %f)))", windowNumber, aPoint.x, aPoint.y]] boolValue];
}

- (void)stopIgnoringMouseEvents
{
    [self setIgnoresMouseEvents:NO];
}

- (void)becomeKeyWindow
{
    [super becomeKeyWindow];

    [self updateShadow];
}

- (void)resignKeyWindow
{
    [super resignKeyWindow];

    [self updateShadow];
}

@end

@interface NSImage (Additions)

- (void)drawInRect:(NSRect)aRect slices:(CGFloat [])slices;

@end

@implementation NSImage (Additions)

- (void)drawInRect:(NSRect)aRect slices:(CGFloat [])slices
{
    NSRect imageBounds = NSMakeRect(0.0, 0.0, [self size].width, [self size].height);

    [self drawInRect:NSMakeRect(0.0, 0.0, slices[0], slices[1])
            fromRect:NSMakeRect(0.0, 0.0, slices[0], slices[1])
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(NSMaxX(aRect) - slices[2], 0.0, slices[2], slices[1])
            fromRect:NSMakeRect(NSMaxX(imageBounds) - slices[2], 0.0, slices[2], slices[1])
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(0.0, NSMaxY(aRect) - slices[3], slices[0], slices[3])
            fromRect:NSMakeRect(0.0, NSMaxY(imageBounds) - slices[3], slices[0], slices[3])
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(NSMaxX(aRect) - slices[2], NSMaxY(aRect) - slices[3], slices[2], slices[3])
            fromRect:NSMakeRect(NSMaxX(imageBounds) - slices[2], NSMaxY(imageBounds) - slices[3], slices[2], slices[3])
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(slices[0], 0.0, NSWidth(aRect) - slices[0] - slices[2], slices[1])
            fromRect:NSMakeRect(slices[0], 0.0, 1.0, slices[1])
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(0.0, slices[1], slices[0], NSHeight(aRect) - slices[1] - slices[3])
            fromRect:NSMakeRect(0.0, slices[1], slices[0], 1.0)
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(NSMaxX(aRect) - slices[2], slices[1], slices[2], NSHeight(aRect) - slices[1] - slices[3])
            fromRect:NSMakeRect(NSMaxX(imageBounds) - slices[2], slices[1], slices[2], 1.0)
           operation:NSCompositeSourceOver
            fraction:1.0];

    [self drawInRect:NSMakeRect(slices[0], NSMaxY(aRect) - slices[3], NSWidth(aRect) - slices[0] - slices[2], slices[3])
            fromRect:NSMakeRect(slices[0], NSMaxY(imageBounds) - slices[3], 1.0, slices[3])
           operation:NSCompositeSourceOver
            fraction:1.0];
}

@end

@implementation WebWindowContentView : NSView
{
}

static float OUTlINE_HORIZONTAL_INSET   = 33.0;
static float OUTlINE_VERTICAL_INSET     = 33.0;

- (void)drawStandardActiveShadowInRect:(NSRect)aRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGRect bounds = CGRectInset(*(CGRect *)&aRect, OUTlINE_HORIZONTAL_INSET - 0.5, OUTlINE_VERTICAL_INSET - 0.5);

    CGColorRef shadowColor = CGColorCreateGenericGray(0.0, 0.8);
    CGContextSetShadowWithColor (context, CGSizeMake(0.0, -10.0), 100.0, shadowColor);
    CGColorRelease(shadowColor);

    CGColorRef fillColor = CGColorCreateGenericGray(1.0, 1.0);
    CGColorRef strokeColor = CGColorCreateGenericGray(0.0, 0.2);

    CGContextSetFillColorWithColor(context, fillColor);
    CGContextSetStrokeColorWithColor(context, strokeColor);

    CGColorRelease(fillColor);
    CGColorRelease(strokeColor);

    CGContextBeginPath(context);

    CGContextAddArc(context, CGRectGetMinX(bounds) + 5.0, CGRectGetMaxY(bounds) - 5.0, 5.0, M_PI, M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 5.0, CGRectGetMaxY(bounds) - 5.0, 5.0, M_PI_2, 0, YES);
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));

    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawStandardInactiveShadowInRect:(NSRect)aRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGRect bounds = CGRectInset(*(CGRect *)&aRect, OUTlINE_HORIZONTAL_INSET - 0.5, OUTlINE_VERTICAL_INSET - 0.5);

    CGColorRef shadowColor = CGColorCreateGenericGray(0.0, 0.5);
    CGContextSetShadowWithColor (context, CGSizeMake(0.0, -10.0), 40.0, shadowColor);
    CGColorRelease(shadowColor);

    CGColorRef fillColor = CGColorCreateGenericGray(1.0, 1.0);
    CGColorRef strokeColor = CGColorCreateGenericGray(0.0, 0.2);

    CGContextSetFillColorWithColor(context, fillColor);
    CGContextSetStrokeColorWithColor(context, strokeColor);

    CGColorRelease(fillColor);
    CGColorRelease(strokeColor);

    CGContextBeginPath(context);

    CGContextAddArc(context, CGRectGetMinX(bounds) + 5.0, CGRectGetMaxY(bounds) - 5.0, 5.0, M_PI, M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 5.0, CGRectGetMaxY(bounds) - 5.0, 5.0, M_PI_2, 0, YES);
    CGContextAddLineToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));

    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawMenuShadowInRect:(NSRect)aRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGRect bounds = CGRectInset(*(CGRect *)&aRect, OUTlINE_HORIZONTAL_INSET - 0.5, OUTlINE_VERTICAL_INSET - 0.5);

    CGColorRef shadowColor = CGColorCreateGenericGray(0.0, 0.5);
    CGContextSetShadowWithColor (context, CGSizeMake(0.0, -10.0), 30.0, shadowColor);
    CGColorRelease(shadowColor);

    CGColorRef fillColor = CGColorCreateGenericGray(1.0, 1.0);
    CGColorRef strokeColor = CGColorCreateGenericGray(0.0, 0.2);

    CGContextSetFillColorWithColor(context, fillColor);
    CGContextSetStrokeColorWithColor(context, strokeColor);

    CGColorRelease(fillColor);
    CGColorRelease(strokeColor);

    CGContextBeginPath(context);

    CGContextAddArc(context, CGRectGetMinX(bounds) + 3.0, CGRectGetMaxY(bounds) - 3.0, 2.0, M_PI, M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 3.0, CGRectGetMaxY(bounds) - 3.0, 2.0, M_PI_2, 0, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 3.0, CGRectGetMinY(bounds) + 3.0, 2.0, 0, 3 * M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMinX(bounds) + 3.0, CGRectGetMinY(bounds) + 3.0, 2.0, 3 * M_PI_2, M_PI, YES);

    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFill);//Stroke);

/*
    CGContextBeginPath(context);

    CGContextAddArc(context, CGRectGetMinX(bounds) + 3.0, CGRectGetMaxY(bounds) - 3.0, 2.0, M_PI, M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 3.0, CGRectGetMaxY(bounds) - 3.0, 2.0, M_PI_2, 0, YES);
    CGContextAddArc(context, CGRectGetMaxX(bounds) - 3.0, CGRectGetMinY(bounds) + 3.0, 2.0, 0, 3 * M_PI_2, YES);
    CGContextAddArc(context, CGRectGetMinX(bounds) + 3.0, CGRectGetMinY(bounds) + 3.0, 2.0, 3 * M_PI_2, M_PI, YES);

    CGContextClosePath(context);

    CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorClear));

    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawPath(context, kCGPathFill);
*/
}

- (NSImage *)shadowImageWithSelector:(SEL)aSelector
{
    static NSMutableDictionary * images = nil;

    if (!images)
        images = [[NSMutableDictionary alloc] init];

    NSString * name = NSStringFromSelector(aSelector);
    NSImage * image = [images objectForKey:name];

    if (!image)
    {
        image = [[NSImage alloc] initWithSize:NSMakeSize(100.0, 100.0)];

        [image lockFocus];
        objc_msgSend(self, aSelector, NSMakeRect(0.0, 0.0, 100.0, 100.0));
        [image unlockFocus];

        [images setObject:image forKey:name];

        [image release];
    }

    return image;
}

- (void)drawShadowWithSelector:(SEL)aSelector inRect:(NSRect)aRect
{
    CGFloat slices[] = { 40.0, 49.0, 40.0, 49.0 };

    if (NSWidth(aRect) > 100.0 || NSHeight(aRect) > 100.0)
        [[self shadowImageWithSelector:aSelector] drawInRect:aRect slices:slices];
    else
        objc_msgSend(self, aSelector, aRect);
}

- (void)drawRect:(NSRect)aRect
{
    WebWindow * window = (WebWindow *)[self window];
    NSRect bounds = [self bounds];

    if (![window hasShadow])
        return;

    if ([window shadowStyle] == CPStandardWindowShadowStyle)
        if ([window isKeyWindow])
            return [self drawShadowWithSelector:@selector(drawStandardActiveShadowInRect:) inRect:bounds];
        else
            return [self drawShadowWithSelector:@selector(drawStandardInactiveShadowInRect:) inRect:bounds];


    if ([window shadowStyle] == CPMenuWindowShadowStyle)
        return [self drawShadowWithSelector:@selector(drawMenuShadowInRect:) inRect:bounds];
}

@end

