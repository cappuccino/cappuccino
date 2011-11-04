/*
 * AppController.j
 * test
 *
 * Created by You on July 6, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@import <AppKit/CPPopover.j>

@implementation AppController : CPObject
{
    CPPopUpButton buttonGravity;
    CPPopUpButton buttonStyle;
    CPPopUpButton buttonAnimation;
    CPPopUpButton buttonBehaviour;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CPPointMake(10, 60)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CPPointMake( [contentView frameSize].width - 50, 60)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CPPointMake( [contentView frameSize].width - 50, [contentView frameSize].height - 50)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CPPointMake( 10, [contentView frameSize].height - 50)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin]
    [button setCenter:[contentView center]];
    [contentView addSubview:button];


    buttonGravity = [[CPPopUpButton alloc] initWithFrame:CPRectMake(10, 10, 130, 24)];
    [buttonGravity addItemWithTitle:"Automatic"];
    [buttonGravity addItemWithTitle:"Bottom"];
    [buttonGravity addItemWithTitle:"Top"];
    [buttonGravity addItemWithTitle:"Right"];
    [buttonGravity addItemWithTitle:"Left"];
    [contentView addSubview:buttonGravity];

    buttonStyle = [[CPPopUpButton alloc] initWithFrame:CPRectMake(150, 10, 130, 24)];
    [buttonStyle addItemWithTitle:"Minimal"];
    [buttonStyle addItemWithTitle:"HUD"];
    [contentView addSubview:buttonStyle];

    buttonAnimation = [[CPPopUpButton alloc] initWithFrame:CPRectMake(290, 10, 130, 24)];
    [buttonAnimation addItemWithTitle:"With animation"];
    [buttonAnimation addItemWithTitle:"No animation"];
    [contentView addSubview:buttonAnimation];

    buttonBehaviour = [[CPPopUpButton alloc] initWithFrame:CPRectMake(430, 10, 130, 24)];
    [buttonBehaviour addItemWithTitle:"Transient"];
    [buttonBehaviour addItemWithTitle:"Not managed"];
    [contentView addSubview:buttonBehaviour];

    [theWindow orderFront:self];
}

- (IBAction)open:(id)sender
{
    var g;
    switch ([buttonGravity title])
    {
        case "Automatic":
            g = nil;
            break;
        case "Bottom":
            g = CPMaxYEdge;
            break;
        case "Top":
            g = CPMinYEdge;
            break;
        case "Left":
            g = CPMinXEdge;
            break;
        case "Right":
            g = CPMaxXEdge;
            break;
    }

    var a;
    switch ([buttonStyle title])
    {
        case "Minimal":
            a = CPPopoverAppearanceMinimal;
            break;
        case "HUD":
            a = CPPopoverAppearanceHUD;
            break;
    }

    var p = [[CPPopover alloc] init],
        viewC = [[CPViewController alloc] init],
        view = [[CPView alloc] initWithFrame:CPRectMake(0.0, 0.0, 320, 300)],
        label = [CPTextField labelWithTitle:[buttonGravity title]];

    [label setFont:[CPFont boldSystemFontOfSize:30.0]];
    [label setFrameOrigin:CPPointMake(0, 70)];
    [label setValue:(a == CPPopoverAppearanceHUD) ? [CPColor colorWithHexString:@"333"] : [CPColor colorWithHexString:@"fff"] forThemeAttribute:@"text-shadow-color"];
    [label setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
    [label setTextColor:(a == CPPopoverAppearanceHUD) ? [CPColor whiteColor] : [CPColor colorWithHexString:@"444"]];
    [label setFrameSize:CPSizeMake([view frame].size.width, 50)];
    [label setAlignment:CPCenterTextAlignment];
    [view addSubview:label];

    [viewC setView:view];
    [p setContentViewController:viewC];
    [p setAnimates:([buttonAnimation title] == @"With animation")];
    [p setBehaviour:([buttonBehaviour title] == @"Transient") ? CPPopoverBehaviorTransient : CPPopoverBehaviorApplicationDefined];
    [p setAppearance:a];
    [p setDelegate:self];
    [p showRelativeToRect:nil ofView:sender preferredEdge:g];
    CPLog.info("content size -  w:" + [p contentSize].width + " h:" + [p contentSize].width);
    CPLog.info("positioning rect - x: " + [p positioningRect].origin.x + " y: " + [p positioningRect].origin.x
                    + " w:" + [p positioningRect].size.width + " h:" + [p positioningRect].size.width);
}


#pragma mark -
#pragma mark CPPopover Delegate

- (void)popoverWillShow:(CPPopover)aPopover
{
    CPLog.info("popover " + aPopover + " will show");
}

- (void)popoverDidShow:(CPPopover)aPopover
{
    CPLog.info("popover " + aPopover + " did show");
}

- (void)popoverWillClose:(CPPopover)aPopover
{
    CPLog.info("popover " + aPopover + " will close");
}

- (void)popoverDidClose:(CPPopover)aPopover
{
    CPLog.info("popover " + aPopover + " did close");
}

@end
