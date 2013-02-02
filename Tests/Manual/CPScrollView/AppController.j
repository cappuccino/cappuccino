/*
 * AppController.j
 * Scrolling
 *
 * Created by You on August 27, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPScrollView.j>


@implementation AppController : CPObject
{
    int scrollViewXCount;
    int scrollViewYCount;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    [theWindow orderFront:self];

    scrollViewXCount = 0;
    scrollViewYCount = 0;

    // Vanilla scrollview
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,900,675)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"photo.jpg"]]];

    var scrollView = [self makeScrollview];
    [scrollView setDocumentView:imageView];
    [scrollView setDelegate:self];
    [[theWindow contentView] addSubview:scrollView];

    // Scrollview with a CPTextField in it
    var textField = [CPTextField textFieldWithStringValue:@"Try to select this" placeholder:@"" width:120];

    [textField setFrameOrigin:CGPointMake(20,20)];
    [textField setSelectable:YES];

    var scrollView = [self makeScrollview];

    [[scrollView documentView] addSubview:textField];
    [[theWindow contentView] addSubview:scrollView];

    // In another window
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(120,400,400,300) styleMask:CPTitledWindowMask];
    [aWindow setTitle:@"Scrollview in a ScrollView in a Window."]
    [aWindow orderFront:nil];

    // Scrollview with another scrollview in it
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,900,675)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"photo.jpg"]]];

    var innerScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 150, 150)];
    [innerScrollView setDocumentView:imageView];

    var scrollView = [self makeScrollview];
    [scrollView setFrameOrigin:CGPointMake(20,20)]

    [[scrollView documentView] addSubview:innerScrollView];
    [[aWindow contentView] addSubview:scrollView];

    var button = [CPButton buttonWithTitle:@"Change Scroller Mode"];
    [button setFrameOrigin:CGPointMake(10.0, 10.0)];
    [button setTarget:self];
    [button setAction:@selector(changeScrollerMode:)];

    [[theWindow contentView] addSubview:button];
}

- (void)scrollViewWillScroll:(CPScrollView)aScrollView
{
    CPLogConsole(_cmd+aScrollView);
}

- (void)scrollViewDidScroll:(CPScrollView)aScrollView
{
    CPLogConsole(_cmd+aScrollView);
}

- (void)makeScrollview
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake((scrollViewXCount * 320) + 120, (scrollViewYCount * 220) + 100, 300, 200)];
    [scrollView setDocumentView:[[CPView alloc] initWithFrame:CGRectMake(0,0,1000,1000)]];

    scrollViewXCount += 1;

    if (scrollViewXCount === 3)
    {
        scrollViewXCount = 0;
        scrollViewYCount += 1;
    }

    return scrollView;
}

- (IBAction)changeScrollerMode:(id)aSender
{
    if ([CPScrollView globalScrollerStyle] == CPScrollerStyleOverlay)
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];
    else
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleOverlay];
}

@end
