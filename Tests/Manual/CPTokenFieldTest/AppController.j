/*
 * AppController.j
 * CPTokenFieldTest
 *
 * Created by Alexander Ljungberg on October 2, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>

var STATES = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'];

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],

        tokenFieldA = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 40, 500, 30)],
        label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 500, 24)];

    [label setStringValue:"This token field has no auto suggestions and uses space to separate tokens."];
    [contentView addSubview:label];

    [tokenFieldA setEditable:YES];
    [tokenFieldA setPlaceholderString:"Type in a token!"];

    [tokenFieldA setTokenizingCharacterSet:[CPCharacterSet characterSetWithCharactersInString:@" "]];

    [contentView addSubview:tokenFieldA];

    var tokenFieldB = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 110, 500, 30)],
        labelB = [[CPTextField alloc] initWithFrame:CGRectMake(15, 80, 500, 24)];

    [labelB setStringValue:"This token field has no bezel, uses comma to separate tokens and has auto suggest."];
    [contentView addSubview:labelB];

    [tokenFieldB setEditable:YES];
    [tokenFieldB setBezeled:NO];
    [tokenFieldB setPlaceholderString:"Edit me!"];

	[tokenFieldB setObjectValue:["Missouri", "California"]];
    [tokenFieldB setDelegate:self];

    [contentView addSubview:tokenFieldB];

    var tokenFieldC = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 170, 500, 30)],
        labelC = [[CPTextField alloc] initWithFrame:CGRectMake(15, 150, 500, 24)];

    [labelC setStringValue:"This token field can't fit all its tokens."];
    [contentView addSubview:labelC];

    [tokenFieldC setEditable:YES];
    [tokenFieldC setPlaceholderString:"Edit me!"];

	[tokenFieldC setObjectValue:['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado']];
    [tokenFieldC setDelegate:self];

    [contentView addSubview:tokenFieldC];

    [theWindow orderFront:self];

}

- (CPArray)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    var r = [];

    // Don't complete 'blank' - this would show all available matches which is excessive.
    if (!substring)
        return r;

    for (var i = 0; i < STATES.length; i++)
        if (STATES[i].toLowerCase().indexOf(substring.toLowerCase()) == 0)
            r.push(STATES[i]);

    return r;
}

@end
