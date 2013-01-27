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
    CPPopUpButton       buttonEdge;
    CPPopUpButton       buttonStyle;
    CPPopUpButton       buttonAnimation;
    CPPopUpButton       buttonBehaviour;
    CPButton            lastButton;
    int                 lastPreferredEdge;
    @outlet CPTextField titleLabel;
    @outlet CPPopover   popover;
    @outlet CPPopover   windowPopover;
    @outlet CPWindow    popoverWindow;
    @outlet CPPopover   nestedPopover;
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
    [button setAutoresizingMask:CPViewMinXMargin];
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame]) - 1, 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin];
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame]) - 1, 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame])- 1, contentViewSize.height - CGRectGetHeight([button frame]) - 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [button setFrameOrigin:CGPointMake(contentViewSize.width - CGRectGetWidth([button frame])- 1, contentViewSize.height - 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin];
    [button setFrameOrigin:CGPointMake(1, contentViewSize.height - CGRectGetHeight([button frame]) - 1)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin];
    [button setFrameOrigin:CGPointMake(1, contentViewSize.height - 100)];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"click"];
    [button setTarget:self];
    [button setAction:@selector(open:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [button setCenter:[contentView center]];
    [contentView addSubview:button];

    button = [CPButton buttonWithTitle:@"Open window"];
    [button setTarget:self];
    [button setAction:@selector(openWindow:)];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
    [button setCenter:[contentView center]];
    [button setFrameOrigin:CGPointMake(CGRectGetMinX([button frame]), 70)];
    [contentView addSubview:button];

    var buttonHeight = [[CPTheme defaultTheme] valueForAttributeWithName:@"min-size" forClass:CPPopUpButton].height;

    buttonEdge = [[CPPopUpButton alloc] initWithFrame:CGRectMake(150, 10, 130, buttonHeight)];
    [buttonEdge addItemWithTitle:"Automatic"];
    [buttonEdge addItemWithTitle:"Bottom"];
    [buttonEdge addItemWithTitle:"Top"];
    [buttonEdge addItemWithTitle:"Right"];
    [buttonEdge addItemWithTitle:"Left"];
    [contentView addSubview:buttonEdge];

    buttonStyle = [[CPPopUpButton alloc] initWithFrame:CGRectMake(290, 10, 130, buttonHeight)];
    [buttonStyle addItemWithTitle:"Minimal"];
    [buttonStyle addItemWithTitle:"HUD"];
    [contentView addSubview:buttonStyle];

    buttonAnimation = [[CPPopUpButton alloc] initWithFrame:CGRectMake(430, 10, 130, buttonHeight)];
    [buttonAnimation addItemWithTitle:"With animation"];
    [buttonAnimation addItemWithTitle:"No animation"];
    [contentView addSubview:buttonAnimation];

    buttonBehaviour = [[CPPopUpButton alloc] initWithFrame:CGRectMake(570, 10, 130, buttonHeight)];
    [buttonBehaviour addItemWithTitle:"Transient"];
    [buttonBehaviour addItemWithTitle:"Not managed"];
    [contentView addSubview:buttonBehaviour];

    [windowPopover setDelegate:self];
    [nestedPopover setDelegate:self];

    [theWindow orderFront:self];
}

- (int)popoverEdge
{
    switch ([buttonEdge title])
    {
        case "Automatic":
            return nil;
        case "Bottom":
            return CPMaxYEdge;
        case "Top":
            return CPMinYEdge;
        case "Left":
            return CPMinXEdge;
        case "Right":
            return CPMaxXEdge;
        default:
            return nil;
    }
}

- (@action)open:(id)sender
{
    var edge = [self popoverEdge],
        appearance,
        color;

    switch ([buttonStyle title])
    {
        case "Minimal":
            appearance = CPPopoverAppearanceMinimal;
            color = [CPColor blackColor];
            break;

        case "HUD":
            appearance = CPPopoverAppearanceHUD;
            color = [CPColor whiteColor];
            break;
    }

    [titleLabel setTextColor:color];
    [self initPopover:popover withAppearance:appearance];
    lastButton = sender;
    lastPreferredEdge = edge;
    [popover showRelativeToRect:nil ofView:sender preferredEdge:edge];
}

- (void)openWindow:(id)sender
{
    [popoverWindow makeKeyAndOrderFront:nil];
}

- (@action)openWindowPopover:(id)sender
{
    [windowPopover showRelativeToRect:nil ofView:sender preferredEdge:[self popoverEdge]];
}

- (@action)openNestedPopover:(id)sender
{
    [nestedPopover showRelativeToRect:nil ofView:sender preferredEdge:[self popoverEdge]];
}

- (@action)setTransient:(id)sender
{
    [windowPopover setBehavior:[sender state] === CPOnState ? CPPopoverBehaviorTransient : CPPopoverBehaviorApplicationDefined];
    [nestedPopover setBehavior:[sender state] === CPOnState ? CPPopoverBehaviorTransient : CPPopoverBehaviorApplicationDefined];
}

- (@action)movePopover:(id)sender
{
    if (++lastPreferredEdge > CPMaxYEdge)
        lastPreferredEdge = CPMinXEdge;

    [popover showRelativeToRect:CGRectMakeZero() ofView:lastButton preferredEdge:lastPreferredEdge];
}

- (@action)closePopover:(id)sender
{
    [popover close];
}

- (void)initPopover:(CPPopover)aPopover withAppearance:(int)appearance
{
    [aPopover setDelegate:self];
    [aPopover setAnimates:([buttonAnimation title] === @"With animation")];
    [aPopover setBehavior:([buttonBehaviour title] === @"Transient") ? CPPopoverBehaviorTransient : CPPopoverBehaviorApplicationDefined];
    [aPopover setAppearance:appearance];
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

    var popWindow = [[[aPopover contentViewController] view] window];
    [popWindow makeFirstResponder:[[popWindow contentView] nextValidKeyView]];
}

- (BOOL)popoverShouldClose:(CPPopover)aPopover
{
    CPLog.info("popover " + aPopover + " should close");
    return YES;
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
