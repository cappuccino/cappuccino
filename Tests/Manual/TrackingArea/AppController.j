/*
 * AppController.j
 * TrackingArea
 *
 * Created by Didier Korthoudt on November 2, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPTrackingArea.j>

@class SensibleView;
@class SensibleViewTA;
@class SensibleViewAutoTA;

@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    
    SensibleView    v1;
    SensibleView    v2;
    SensibleView    v3;
    SensibleView    v4;
    SensibleView    v5;
    SensibleView    v6;
    SensibleView    v7;
    SensibleView    v8;

    SensibleViewTA      w2;
    SensibleView        w3;
    SensibleViewAutoTA  w4;
    SensibleView        w5;
    SensibleView        w6;
    SensibleView        w7;

    @outlet SensibleView    s1;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

    var p = [theWindow contentView];
    
    // No tracking area
    
    v1 = [[SensibleView alloc] initWithFrame:CGRectMake(30, 10, 50, 50)];
    
    [v1 setViewName:@"no_tracking_area"];
    [v1 setViewColor:[CPColor greenColor]];
    [v1 setViewCursor:[CPCursor crosshairCursor]];
    
    [p addSubview:v1];
    
    var l = [CPTextField labelWithTitle:@"No tracking area"];
    
    [l setCenter:CGPointMake([v1 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];

    [p addSubview:l];
    
    // CPTrackingMouseEnteredAndExited
    
    v2 = [[SensibleView alloc] initWithFrame:CGRectMake(160, 10, 50, 50)];
    
    [v2 setViewName:@"CPTrackingMouseEnteredAndExited"];
    [v2 setViewColor:[CPColor greenColor]];
    [v2 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v2
                                        userInfo:nil];

    [v2 addTrackingArea:t];

    [p addSubview:v2];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v2 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingCursorUpdate
    
    v3 = [[SensibleView alloc] initWithFrame:CGRectMake(290, 10, 50, 50)];
    
    [v3 setViewName:@"CPTrackingCursorUpdate"];
    [v3 setViewColor:[CPColor greenColor]];
    [v3 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v3
                                        userInfo:nil];
    
    [v3 addTrackingArea:t];
    
    [p addSubview:v3];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingCursorUpdate\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v3 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingMouseMoved
    
    v4 = [[SensibleView alloc] initWithFrame:CGRectMake(420, 10, 50, 50)];
    
    [v4 setViewName:@"CPTrackingMouseMoved"];
    [v4 setViewColor:[CPColor greenColor]];
    [v4 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseMoved | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v4
                                        userInfo:nil];
    
    [v4 addTrackingArea:t];
    
    [p addSubview:v4];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseMoved\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v4 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingMouseEnteredAndExited & CPTrackingCursorUpdate
    
    v5 = [[SensibleView alloc] initWithFrame:CGRectMake(550, 10, 50, 50)];
    
    [v5 setViewName:@"CPTrackingMouseEnteredAndExited+CPTrackingCursorUpdate"];
    [v5 setViewColor:[CPColor greenColor]];
    [v5 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v5
                                        userInfo:nil];
    
    [v5 addTrackingArea:t];
    
    [p addSubview:v5];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\nCPTrackingCursorUpdate\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v5 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingMouseMoved & CPTrackingCursorUpdate
    
    v6 = [[SensibleView alloc] initWithFrame:CGRectMake(680, 10, 50, 50)];
    
    [v6 setViewName:@"CPTrackingMouseMoved+CPTrackingCursorUpdate"];
    [v6 setViewColor:[CPColor greenColor]];
    [v6 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseMoved | CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v6
                                        userInfo:nil];
    
    [v6 addTrackingArea:t];
    
    [p addSubview:v6];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseMoved\nCPTrackingCursorUpdate\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v6 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingMouseEnteredAndExited & CPTrackingMouseMoved
    
    v7 = [[SensibleView alloc] initWithFrame:CGRectMake(810, 10, 50, 50)];
    
    [v7 setViewName:@"CPTrackingMouseEnteredAndExited+CPTrackingMouseMoved"];
    [v7 setViewColor:[CPColor greenColor]];
    [v7 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v7
                                        userInfo:nil];
    
    [v7 addTrackingArea:t];
    
    [p addSubview:v7];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\nCPTrackingMouseMoved\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v7 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingMouseEnteredAndExited & CPTrackingMouseMoved & CPTrackingCursorUpdate
    
    v8 = [[SensibleView alloc] initWithFrame:CGRectMake(940, 10, 50, 50)];
    
    [v8 setViewName:@"CPTrackingMouseEnteredAndExited+CPTrackingMouseMoved+CPTrackingCursorUpdate"];
    [v8 setViewColor:[CPColor greenColor]];
    [v8 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v8
                                        userInfo:nil];
    
    [v8 addTrackingArea:t];
    
    [p addSubview:v8];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\nCPTrackingMouseMoved\nCPTrackingCursorUpdate\nCPTrackingInVisibleRect"];
    
    [l setCenter:CGPointMake([v8 center].x, 90)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // Not CPTrackingInVisibleRect
    
    w2 = [[SensibleViewTA alloc] initWithFrame:CGRectMake(160, 110, 50, 50)];
    
    [w2 setViewName:@"Not CPTrackingInVisibleRect"];
    [w2 setViewColor:[CPColor greenColor]];
    [w2 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMake(0, 0, 25, 25)
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow
                                           owner:w2
                                        userInfo:nil];
    
    [w2 addTrackingArea:t];
    
    [p addSubview:w2];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\n(top-left quarter is the active area)"];
    
    [l setCenter:CGPointMake([w2 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // CPTrackingEnabledDuringMouseDrag
    
    w3 = [[SensibleView alloc] initWithFrame:CGRectMake(290, 110, 50, 50)];
    
    [w3 setViewName:@"CPTrackingEnabledDuringMouseDrag"];
    [w3 setViewColor:[CPColor greenColor]];
    [w3 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect | CPTrackingEnabledDuringMouseDrag
                                           owner:w3
                                        userInfo:nil];
    
    [w3 addTrackingArea:t];
    
    [p addSubview:w3];
    
    var l = [CPTextField labelWithTitle:@"CPTrackingMouseEnteredAndExited\nCPTrackingInVisibleRect\nCPTrackingEnabledDuringMouseDrag"];
    
    [l setCenter:CGPointMake([w3 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // View in CPScrollView
    
    [s1 setViewName:@"View in CPScrollView"];
    [s1 setViewColor:[CPColor greenColor]];
    [s1 setViewCursor:[CPCursor crosshairCursor]];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:s1
                                        userInfo:nil];
    
    [s1 addTrackingArea:t];
    
    // No itinial TA
    
    w4 = [[SensibleViewAutoTA alloc] initWithFrame:CGRectMake(420, 110, 50, 50)];
    
    [w4 setViewName:@"No itinial TA"];
    [w4 setViewColor:[CPColor greenColor]];
    [w4 setViewCursor:[CPCursor crosshairCursor]];
    
    [p addSubview:w4];
    
    var l = [CPTextField labelWithTitle:@"This one has no initial\ntracking area but\nuses updateTrackingAreas to\nattach one"];
    
    [l setCenter:CGPointMake([w4 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    // Two views with tracking areas where the owner is not the view itself
    
    w5 = [[SensibleView alloc] initWithFrame:CGRectMake(550, 110, 50, 50)];
    
    [w5 setViewName:@"firstView"];
    [w5 setViewColor:[CPColor greenColor]];
    [w5 setViewCursor:[CPCursor crosshairCursor]];
    
    [p addSubview:w5];
    
    var l = [CPTextField labelWithTitle:@"(firstView)\nThis view has a tracking area\nowned by the blue view"];
    
    [l setCenter:CGPointMake([w5 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    w6 = [[SensibleView alloc] initWithFrame:CGRectMake(680, 110, 50, 50)];
    
    [w6 setViewName:@"secondView"];
    [w6 setViewColor:[CPColor greenColor]];
    [w6 setViewCursor:[CPCursor crosshairCursor]];
    
    [p addSubview:w6];
    
    var l = [CPTextField labelWithTitle:@"(secondView)\nThis view has a tracking area\nowned by the blue view"];
    
    [l setCenter:CGPointMake([w6 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    w7 = [[SensibleView alloc] initWithFrame:CGRectMake(810, 110, 50, 50)];
    
    [w7 setViewName:@"masterView"];
    [w7 setViewColor:[CPColor blueColor]];
    [w7 setViewCursor:[CPCursor crosshairCursor]];
    
    [p addSubview:w7];
    
    var l = [CPTextField labelWithTitle:@"I'm the owner of the\ntracking areas of\nthe 2 views on my left"];
    
    [l setCenter:CGPointMake([w7 center].x, 190)];
    [l setFont:[CPFont systemFontOfSize:8]];
    [l setAlignment:CPCenterTextAlignment];
    
    [p addSubview:l];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:w7
                                        userInfo:@{ @"trigger": @"View 1" } ];
    
    [w5 addTrackingArea:t];

    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:w7
                                        userInfo:@{ @"trigger": @"View 2" } ];
    
    [w6 addTrackingArea:t];
    
    
    // Cursor update complex test
    
    for (var i = 0; i < 10; i++)
    {
        var v = [[(i == 7 ? SensibleViewWithoutCursorUpdate : SensibleView) alloc] initWithFrame:CGRectMake((i == 0 ? 50 : 20), (i == 0 ? 240 : 20), 400-(i*40), 400-(i*40))];

        [p addSubview:v];
        p = v;
        
        [v setViewName:[CPString stringWithFormat:@"v%d",i]];
        
        var c = [CPColor colorWithHexString:[CPString stringWithFormat:@"%d%d%d%d%d%d",i,i,i,i,i,i]];
        
        [v setViewColor:c];
        
        switch (i)
        {
            case 0: [v setViewCursor:[CPCursor crosshairCursor]]; break;
            case 1: [v setViewCursor:[CPCursor pointingHandCursor]]; break;
            case 2: [v setViewCursor:[CPCursor resizeNorthwestCursor]]; break;
            case 3: [v setViewCursor:nil]; break;
            case 4: [v setViewCursor:[CPCursor dragCopyCursor]]; break;
            case 5: [v setViewCursor:[CPCursor dragLinkCursor]]; break;
            case 6: [v setViewCursor:[CPCursor contextualMenuCursor]]; break;
            case 7: [v setViewCursor:[CPCursor openHandCursor]]; break;
            case 8: [v setViewCursor:[CPCursor closedHandCursor]]; break;
            case 9: [v setViewCursor:[CPCursor resizeNorthSouthCursor]]; break;
        }
        
        var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                             options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect | CPTrackingEnabledDuringMouseDrag
                                               owner:v
                                            userInfo:nil];
        [v addTrackingArea:t];
    }


    var p = [theWindow contentView];
    
    for (var i = 0; i < 10; i++)
    {
        var v = [[(i == 7 ? SensibleViewWithoutCursorUpdate : SensibleView) alloc] initWithFrame:CGRectMake((i == 0 ? 460 : 0), (i == 0 ? 240 : 0), 400-(i*40), 400-(i*40))];

        [p addSubview:v];
        p = v;
        
        [v setViewName:[CPString stringWithFormat:@"v%d",i]];
        
        var c = [CPColor colorWithHexString:[CPString stringWithFormat:@"%d%d%d%d%d%d",i,i,i,i,i,i]];
        
        [v setViewColor:c];
        
        switch (i)
        {
            case 0: [v setViewCursor:[CPCursor crosshairCursor]]; break;
            case 1: [v setViewCursor:[CPCursor pointingHandCursor]]; break;
            case 2: [v setViewCursor:[CPCursor resizeNorthwestCursor]]; break;
            case 3: [v setViewCursor:nil]; break;
            case 4: [v setViewCursor:[CPCursor dragCopyCursor]]; break;
            case 5: [v setViewCursor:[CPCursor dragLinkCursor]]; break;
            case 6: [v setViewCursor:[CPCursor contextualMenuCursor]]; break;
            case 7: [v setViewCursor:[CPCursor openHandCursor]]; break;
            case 8: [v setViewCursor:[CPCursor closedHandCursor]]; break;
            case 9: [v setViewCursor:[CPCursor resizeNorthSouthCursor]]; break;
        }
        
        var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                             options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                               owner:v
                                            userInfo:nil];
        [v addTrackingArea:t];
    }
    
    var item = [CPButton buttonWithTitle:@"Click to add view that catches cursor updates but not mouse entered/exited events"];
    
    [item setTarget:self];
    [item setAction:@selector(addAView:)];
    [item setCenter:CGPointMake(455, 660)];
    
    [[theWindow contentView] addSubview:item];
}

- (void)addAView:(id)aSender
{
    var v = [[SensibleView alloc] initWithFrame:CGRectMake(250, 440, 410, 200)];
    
    var c = [CPColor colorWithHexString:@"c8d3b2"];
    [v setViewColor:c];
    [v setViewName:@"overview"];
    [v setViewCursor:[CPCursor disappearingItemCursor]];
    
    [v setAlphaValue:0.7];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:v
                                        userInfo:nil];
    [v addTrackingArea:t];

    
    [[theWindow contentView] addSubview:v];

    [aSender setEnabled:NO];
}

@end

@implementation SensibleView : CPView
{
    CPString    viewName    @accessors;
    CPCursor    viewCursor  @accessors;
    CPColor     viewColor;
    CPTextField coords;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        coords = [CPTextField labelWithTitle:@"WWWW,WWWW"];
        [coords setFont:[CPFont systemFontOfSize:9]];
        [coords setAlignment:CPCenterTextAlignment];
        [coords setCenter:CGPointMake(25,25)];
        [coords setStringValue:@""];
        
        [self addSubview:coords];
    }
    
    return self;
}

- (void)mouseEntered:(CPEvent)anEvent
{
    CPLog.trace("mouseEntered @"+viewName);

    [self setBackgroundColor:[CPColor redColor]];
    
    var trigger = [[[anEvent trackingArea] userInfo] valueForKey:@"trigger"];
    
    if (trigger)
        [coords setStringValue:trigger];
}

- (void)mouseExited:(CPEvent)anEvent
{
    CPLog.trace("mouseExited @"+viewName);

    [self setBackgroundColor:viewColor];
    
    [coords setStringValue:@""];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    var l = [anEvent locationInWindow];
    
    [coords setStringValue:[CPString stringWithFormat:@"%d,%d",l.x,l.y]];
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    CPLog.trace("cursorUpdate @"+viewName);

    if (viewCursor)
        [viewCursor set];
}

- (void)setViewColor:(CPColor)aColor
{
    viewColor = aColor;
    [self setBackgroundColor:aColor];
}

@end

@implementation SensibleViewWithoutCursorUpdate : CPView
{
    CPString    viewName    @accessors;
    CPCursor    viewCursor  @accessors;
    CPColor     viewColor;
    CPTextField coords;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        coords = [CPTextField labelWithTitle:@"WWWW,WWWW"];
        [coords setFont:[CPFont systemFontOfSize:9]];
        [coords setAlignment:CPCenterTextAlignment];
        [coords setCenter:CGPointMake(25,25)];
        [coords setStringValue:@""];

        [self addSubview:coords];
    }

    return self;
}

- (void)mouseEntered:(CPEvent)anEvent
{
    CPLog.trace("mouseEntered @"+viewName);

    [self setBackgroundColor:[CPColor redColor]];

    var trigger = [[[anEvent trackingArea] userInfo] valueForKey:@"trigger"];

    if (trigger)
        [coords setStringValue:trigger];
}

- (void)mouseExited:(CPEvent)anEvent
{
    CPLog.trace("mouseExited @"+viewName);

    [self setBackgroundColor:viewColor];

    [coords setStringValue:@""];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    var l = [anEvent locationInWindow];

    [coords setStringValue:[CPString stringWithFormat:@"%d,%d",l.x,l.y]];
}

- (void)setViewColor:(CPColor)aColor
{
    viewColor = aColor;
    [self setBackgroundColor:aColor];
}

@end

@implementation SensibleViewTA : SensibleView

- (void)updateTrackingAreas
{
    CPLog.trace("updateTrackingAreas @"+viewName);
    
    [self removeAllTrackingAreas];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMake(0, 0, 25, 25)
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow
                                           owner:self
                                        userInfo:nil];
    
    [self addTrackingArea:t];
}

@end

@implementation SensibleViewAutoTA : SensibleView

- (void)updateTrackingAreas
{
    CPLog.trace("updateTrackingAreas @"+viewName);
    
    [self removeAllTrackingAreas];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect
                                           owner:self
                                        userInfo:nil];
    
    [self addTrackingArea:t];
}

@end

