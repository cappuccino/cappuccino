/*
 * AppController.j
 * menu-keyequivs
 *
 * Created by You on May 5, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        button = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    [button addItem:[self _itemWithTitle:@"Escape" keyEquivalent:CPEscapeFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Tab forward" keyEquivalent:CPTabCharacter]];
    [button addItem:[self _itemWithTitle:@"Tab back" keyEquivalent:CPBackTabCharacter]];
    [button addItem:[self _itemWithTitle:@"Space" keyEquivalent:CPSpaceFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Return" keyEquivalent:CPCarriageReturnCharacter]];
    [button addItem:[self _itemWithTitle:@"Delete back" keyEquivalent:CPBackspaceCharacter]];
    [button addItem:[self _itemWithTitle:@"Delete forward" keyEquivalent:CPDeleteCharacter]];
    [button addItem:[self _itemWithTitle:@"Home" keyEquivalent:CPHomeFunctionKey]];
    [button addItem:[self _itemWithTitle:@"End" keyEquivalent:CPEndFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Up arrow" keyEquivalent:CPUpArrowFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Down arrow" keyEquivalent:CPDownArrowFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Left arrow" keyEquivalent:CPLeftArrowFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Right arrow" keyEquivalent:CPRightArrowFunctionKey]];
    [button addItem:[self _itemWithTitle:@"Clear" keyEquivalent:CPClearDisplayFunctionKey]];

    var combiItem = [[CPMenuItem alloc] initWithTitle:@"Combi" action:nil keyEquivalent:"t"];
    [combiItem setKeyEquivalentModifierMask:CPCommandKeyMask | CPShiftKeyMask | CPControlKeyMask | CPAlternateKeyMask];
    [button addItem:combiItem];


    [button sizeToFit];
    [button setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [button setCenter:[contentView center]];

    [contentView addSubview:button];

    [theWindow orderFront:self];
}

- (CPMenuItem)_itemWithTitle:(CPString)theTitle keyEquivalent:(CPString)theKeyEquivalent
{
    var menuItem = [[CPMenuItem alloc] initWithTitle:theTitle action:nil keyEquivalent:theKeyEquivalent];
    [menuItem setKeyEquivalentModifierMask:0];
    return menuItem;
}

@end
