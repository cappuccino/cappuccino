/*
 * AppController.j
 * CPTokenFieldTest
 *
 * Created by Alexander Ljungberg on October 2, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var tokenFieldA = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 40, 300, 30)],
        label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 500, 24)];

    [label setStringValue:"This token field has no auto suggestions and uses space to separate tokens."];
    [contentView addSubview:label];

    [tokenFieldA setEditable:YES];
    [tokenFieldA setPlaceholderString:"Edit me!"];

    [tokenFieldA setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString:@" "]];

    [contentView addSubview:tokenFieldA];

    [theWindow orderFront:self];

}

@end
