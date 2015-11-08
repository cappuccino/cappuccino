/*
 * AppController.j
 * TrackingArea
 *
 * Created by You on November 2, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
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
    
    for (var i = 0; i < 10; i++)
    {
        CPLog.trace("i="+i);
        var v = [[SensibleView alloc] initWithFrame:CGRectMake((i == 0 ? 50 : 20), (i == 0 ? 200 : 20), 400-(i*40), 400-(i*40))];
        
        [p addSubview:v];
        p = v;
        
        [v setViewName:[CPString stringWithFormat:@"v%d",i]];
        
        var c = [CPColor colorWithHexString:[CPString stringWithFormat:@"%d%d%d%d%d%d",i,i,i,i,i,i]];
        
        [v setViewColor:c];
        [v setBackgroundColor:c];
        
        switch (i)
        {
            case 0: [v setViewCursor:[CPCursor crosshairCursor]]; break;
            case 1: [v setViewCursor:[CPCursor pointingHandCursor]]; break;
            case 2: [v setViewCursor:[CPCursor resizeNorthwestCursor]]; break;
            case 3: [v setViewCursor:[CPCursor IBeamCursor]]; break;
            case 4: [v setViewCursor:[CPCursor dragCopyCursor]]; break;
            case 5: [v setViewCursor:[CPCursor dragLinkCursor]]; break;
            case 6: [v setViewCursor:[CPCursor contextualMenuCursor]]; break;
            case 7: [v setViewCursor:[CPCursor openHandCursor]]; break;
            case 8: [v setViewCursor:[CPCursor closedHandCursor]]; break;
            case 9: [v setViewCursor:[CPCursor resizeNorthSouthCursor]]; break;
        }
        
        var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                             options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                               owner:v
                                            userInfo:nil];
        [v addTrackingArea:t];
    }


    var p = [theWindow contentView];
    
    for (var i = 0; i < 10; i++)
    {
        CPLog.trace("i="+i);
        var v = [[SensibleView alloc] initWithFrame:CGRectMake((i == 0 ? 460 : 0), (i == 0 ? 200 : 0), 400-(i*40), 400-(i*40))];
        
        [p addSubview:v];
        p = v;
        
        [v setViewName:[CPString stringWithFormat:@"v%d",i]];
        
        var c = [CPColor colorWithHexString:[CPString stringWithFormat:@"%d%d%d%d%d%d",i,i,i,i,i,i]];
        
        [v setViewColor:c];
        [v setBackgroundColor:c];
        
        switch (i)
        {
            case 0: [v setViewCursor:[CPCursor crosshairCursor]]; break;
            case 1: [v setViewCursor:[CPCursor pointingHandCursor]]; break;
            case 2: [v setViewCursor:[CPCursor resizeNorthwestCursor]]; break;
            case 3: [v setViewCursor:[CPCursor IBeamCursor]]; break;
            case 4: [v setViewCursor:[CPCursor dragCopyCursor]]; break;
            case 5: [v setViewCursor:[CPCursor dragLinkCursor]]; break;
            case 6: [v setViewCursor:[CPCursor contextualMenuCursor]]; break;
            case 7: [v setViewCursor:[CPCursor openHandCursor]]; break;
            case 8: [v setViewCursor:[CPCursor closedHandCursor]]; break;
            case 9: [v setViewCursor:[CPCursor resizeNorthSouthCursor]]; break;
        }
        
        var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                             options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                               owner:v
                                            userInfo:nil];
        [v addTrackingArea:t];
    }
    
    var item = [CPButton buttonWithTitle:@"Clic to add view"];
    
    [item setTarget:self];
    [item setAction:@selector(addAView:)];
    [item setCenter:CGPointMake(455, 620)];
    
    [[theWindow contentView] addSubview:item];
}

- (void)addAView:(id)aSender
{
    var v = [[SensibleView alloc] initWithFrame:CGRectMake(250, 400, 410, 200)];
    
    var c = [CPColor colorWithHexString:@"c8d3b2"];
    [v setBackgroundColor:c];
    [v setViewColor:c];
    [v setViewName:@"overview"];
    [v setViewCursor:[CPCursor disappearingItemCursor]];
    
    [v setAlphaValue:0.7];
    
    var t = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                         options:CPTrackingCursorUpdate | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                           owner:v
                                        userInfo:nil];
    [v addTrackingArea:t];

    
    [[theWindow contentView] addSubview:v];
}

@end

@implementation SensibleView : CPView
{
    CPString    viewName    @accessors;
    CPCursor    viewCursor  @accessors;
    CPColor     viewColor   @accessors;
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [self setBackgroundColor:[CPColor redColor]];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [self setBackgroundColor:viewColor];
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    CPLog.trace("cursorUpdate in "+viewName);
    [viewCursor set];
}

@end

