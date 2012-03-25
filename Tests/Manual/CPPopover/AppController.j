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
    CPPopUpButton buttonEdge;
    CPPopUpButton buttonStyle;
    CPPopUpButton buttonAnimation;
    CPPopUpButton buttonBehaviour;
    CPPopover     popover;
    CPTextField   appearanceLabel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        contentViewSize = [contentView frameSize];

    var button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CGPointMake(1, 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setFrameOrigin:CGPointMake(1, 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin]
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame]) - 1, 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin]
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame]) - 1, 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin]
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame])- 1, contentViewSize.height - CGRectGetHeight([button frame]) - 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin]
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame])- 1, contentViewSize.height - 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin]
    [button setFrameOrigin:CGPointMake(1, contentViewSize.height - CGRectGetHeight([button frame]) - 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin]
    [button setFrameOrigin:CGPointMake(1, contentViewSize.height - 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin]
    [button setCenter:[contentView center]];
    [contentView addSubview:button];


    buttonEdge = [[CPPopUpButton alloc] initWithFrame:CGRectMake(150, 10, 130, 24)];
    [buttonEdge addItemWithTitle:"Automatic"];
    [buttonEdge addItemWithTitle:"Bottom"];
    [buttonEdge addItemWithTitle:"Top"];
    [buttonEdge addItemWithTitle:"Right"];
    [buttonEdge addItemWithTitle:"Left"];
    [contentView addSubview:buttonEdge];

    buttonStyle = [[CPPopUpButton alloc] initWithFrame:CGRectMake(290, 10, 130, 24)];
    [buttonStyle addItemWithTitle:"Minimal"];
    [buttonStyle addItemWithTitle:"HUD"];
    [contentView addSubview:buttonStyle];

    buttonAnimation = [[CPPopUpButton alloc] initWithFrame:CGRectMake(430, 10, 130, 24)];
    [buttonAnimation addItemWithTitle:"With animation"];
    [buttonAnimation addItemWithTitle:"No animation"];
    [contentView addSubview:buttonAnimation];

    buttonBehaviour = [[CPPopUpButton alloc] initWithFrame:CGRectMake(570, 10, 130, 24)];
    [buttonBehaviour addItemWithTitle:"Transient"];
    [buttonBehaviour addItemWithTitle:"Not managed"];
    [contentView addSubview:buttonBehaviour];

    [theWindow orderFront:self];
}

- (IBAction)open:(id)sender
{
    var edge;

    switch ([buttonEdge title])
    {
        case "Automatic":
            edge = nil;
            break;
        case "Bottom":
            edge = CPMaxYEdge;
            break;
        case "Top":
            edge = CPMinYEdge;
            break;
        case "Left":
            edge = CPMinXEdge;
            break;
        case "Right":
            edge = CPMaxXEdge;
            break;
    }

    var appearance;

    switch ([buttonStyle title])
    {
        case "Minimal":
            appearance = CPPopoverAppearanceMinimal;
            break;
        case "HUD":
            appearance = CPPopoverAppearanceHUD;
            break;
    }

    var pop = [self popoverWithAppearance:appearance];

    [pop showRelativeToRect:nil ofView:sender preferredEdge:edge];

    CPLog.info("content size -  w:" + [pop contentSize].width + " h:" + [pop contentSize].width);
    CPLog.info("positioning rect - x: " + [pop positioningRect].origin.x + " y: " + [pop positioningRect].origin.x
                    + " w:" + [pop positioningRect].size.width + " h:" + [pop positioningRect].size.width);
}

- (CPPopover)popoverWithAppearance:(int)appearance
{
    if (!popover || [buttonBehaviour title] === @"Not managed")
    {
        popover = [CPPopover new];

        var controller = [[CPViewController alloc] init],
            view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320, 300)];

        appearanceLabel = [CPTextField labelWithTitle:[buttonEdge title]];
        [appearanceLabel setFont:[CPFont boldSystemFontOfSize:30.0]];
        [appearanceLabel setFrameOrigin:CGPointMake(0, 70)];
        [appearanceLabel setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset"];
        [appearanceLabel setFrameSize:CPSizeMake([view frame].size.width, 50)];
        [appearanceLabel setAlignment:CPCenterTextAlignment];
        [view addSubview:appearanceLabel];

        [controller setView:view];
        [popover setContentViewController:controller];
        [popover setDelegate:self];
    }

    [appearanceLabel setTextColor:(appearance === CPPopoverAppearanceHUD) ? [CPColor whiteColor] : [CPColor colorWithHexString:@"444"]];
    [appearanceLabel setValue:(appearance === CPPopoverAppearanceHUD) ? [CPColor colorWithHexString:@"333"] : [CPColor colorWithHexString:@"fff"] forThemeAttribute:@"text-shadow-color"];
    [appearanceLabel setStringValue:[buttonEdge title]];
    [popover setAnimates:([buttonAnimation title] === @"With animation")];
    [popover setBehaviour:([buttonBehaviour title] === @"Transient") ? CPPopoverBehaviorTransient : CPPopoverBehaviorApplicationDefined];
    [popover setAppearance:appearance];

    return popover;
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
