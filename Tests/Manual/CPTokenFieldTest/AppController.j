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
    CPTokenField    tokenFieldD;

    CPArray         allPersons;
    CPButton        manipulateTokenInsertionButton;
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

    [tokenFieldB setAction:@selector(tokenFieldAction:)];
    [tokenFieldB setTarget:self];

    [contentView addSubview:tokenFieldB];

    manipulateTokenInsertionButton = [CPCheckBox checkBoxWithTitle:"Token transformations"];
    [manipulateTokenInsertionButton setFrame:CGRectMake(525, 110, 200, 50)];
    [contentView addSubview:manipulateTokenInsertionButton];

    var tokenFieldC = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 170, 500, 30)],
        labelC = [[CPTextField alloc] initWithFrame:CGRectMake(15, 150, 500, 24)];

    [labelC setStringValue:"This token field can't fit all its tokens."];
    [contentView addSubview:labelC];

    [tokenFieldC setEditable:YES];
    [tokenFieldC setPlaceholderString:"Edit me!"];

    [tokenFieldC setObjectValue:['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado']];
    [tokenFieldC setDelegate:self];

    [contentView addSubview:tokenFieldC];

    [tokenFieldC setSendsActionOnEndEditing:YES];
    [tokenFieldC setAction:@selector(tokenFieldAction:)];
    [tokenFieldC setTarget:self];

    tokenFieldD = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 230, 500, 30)],
        labelD = [[CPTextField alloc] initWithFrame:CGRectMake(15, 210, 500, 24)];

    [labelD setStringValue:"This token field contains represented objects."];
    [contentView addSubview:labelD];

    [tokenFieldD setEditable:YES];

    // Delegate must be set before objectValue
    [tokenFieldD setDelegate:self];

    var tokenFieldDEditable = [CPCheckBox checkBoxWithTitle:"Editable"];
    [tokenFieldDEditable sizeToFit];
    [tokenFieldDEditable setFrameOrigin:CGPointMake(525, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDEditable bind:CPValueBinding toObject:tokenFieldD withKeyPath:@"editable" options:nil];
    [contentView addSubview:tokenFieldDEditable];

    var tokenFieldDMenus = [CPCheckBox checkBoxWithTitle:"Menus"];
    [tokenFieldDMenus sizeToFit];
    [tokenFieldDMenus setFrameOrigin:CGPointMake(CGRectGetMaxX([tokenFieldDEditable frame]) + 5, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDMenus bind:CPValueBinding toObject:self withKeyPath:@"tokenFieldDHasMenus" options:nil];
    [contentView addSubview:tokenFieldDMenus];

    var tokenFieldDClose = [CPCheckBox checkBoxWithTitle:"Close Buttons"];
    [tokenFieldDClose sizeToFit];
    [tokenFieldDClose setFrameOrigin:CGPointMake(CGRectGetMaxX([tokenFieldDMenus frame]) + 5, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDClose bind:CPValueBinding toObject:self withKeyPath:@"tokenFieldDHasCloseButtons" options:nil];
    [contentView addSubview:tokenFieldDClose];

    allPersons = [
        [Person personWithFirstName:@"Luc" lastName:@"Vauvillier"],
        [Person personWithFirstName:@"John" lastName:@"Doe"],
        [Person personWithFirstName:@"Amélie" lastName:@"Poulain"],
        [Person personWithFirstName:@"Jean" lastName:@"Valjean"]
    ];
    [tokenFieldD setObjectValue:[allPersons copy]];

    [contentView addSubview:tokenFieldD];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(15, 270, 0, 0)];
    [button setTitle:"Get Object Values"];
    [button sizeToFit];
    [button setTarget:self];
    [button setAction:@selector(getObjectValues:)];
    [contentView addSubview:button];

    [theWindow orderFront:self];

}

- (void)setTokenFieldDHasMenus:(BOOL)shouldHaveMenus
{
    if (shouldHaveMenus)
    {
        [[tokenFieldD objectValue] enumerateObjectsUsingBlock:function(aPerson)
            {
                var menu = [CPMenu new];
                for (var i = 0; i < 3; i++)
                    [menu addItem:[[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"%@ Item %i", aPerson, i] action:nil keyEquivalent:nil]];
                aPerson.menu = menu;
            }];
    }
    else
        [[tokenFieldD objectValue] makeObjectsPerformSelector:@selector(setMenu:) withObject:nil];
}

- (BOOL)tokenFieldDHasMenus
{
    return !![[[tokenFieldD objectValue] firstObject] menu];
}

- (void)setTokenFieldDHasCloseButtons:(BOOL)shouldHaveCloseButtons
{
   [tokenFieldD setButtonType:shouldHaveCloseButtons ? CPTokenFieldDeleteButtonType : CPTokenFieldDisclosureButtonType];
}

- (BOOL)tokenFieldDHasCloseButtons
{
    return !![tokenFieldD buttonType] === CPTokenFieldDeleteButtonType;
}

- (void)getObjectValues:(id)sender
{
    alert([tokenFieldD objectValue]);
}

- (CPArray)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    var r = [];

    // Don't complete 'blank' - this would show all available matches which is excessive.
    if (!substring)
        return r;


    if (aTokenField !== tokenFieldD)
    {
        for (var i = 0; i < STATES.length; i++)
            if (STATES[i].toLowerCase().indexOf(substring.toLowerCase()) == 0)
                r.push(STATES[i]);
    }
    else
    {
        for (var i = 0; i < allPersons.length; i++)
            if ([allPersons[i] fullname].toLowerCase().indexOf(substring.toLowerCase()) == 0)
                r.push(allPersons[i]);
    }

    return r;
}

- (CPString)tokenField:(CPTokenField)tokenField displayStringForRepresentedObject:(id)representedObject
{
    if ([representedObject isKindOfClass:Person])
    {
        return [representedObject fullname];
    }

    return representedObject;
}

- (@action)tokenFieldAction:(id)sender
{
    CPLog.info("tokenFieldAction: " + sender);
}

- (CPArray)tokenField:tokenField shouldAddObjects:tokens atIndex:index
{
    CPLog.info("tokenField: " + tokenField + " shouldAddObjects: " + tokens + " atIndex: " + index);

    // Texas -> Utah, Michigan -> Michigan & Arkansas, Washington -> nil

    if ([manipulateTokenInsertionButton intValue])
    {
        if (tokens[0] == "Texas")
            return ["Utah"];
        else if (tokens[0] == "Michigan")
            return ["Michigan", "Arkansas"];
        else if (tokens[0] == "Washington")
            return [];
    }

    return tokens;
}

- (BOOL)tokenField:(CPTokenField)aTokenField hasMenuForRepresentedObject:(id)aRepresentedObject
{
    return !!aRepresentedObject.menu;
}

- (CPMenu)tokenField:(CPTokenField)aTokenField menuForRepresentedObject:(id)aRepresentedObject
{
    return aRepresentedObject.menu;
}

@end

// A sample of a custom Object

@implementation Person : CPObject
{
    CPString    _firstName;
    CPString    _lastName;

    CPMenu      menu @accessors;
}

+ (id)personWithFirstName:(CPString)aFirstName lastName:(CPString)aLastName
{
    return [[self alloc] initWithFirstName:aFirstName lastName:aLastName];
}

- (id)initWithFirstName:(CPString)aFirstName lastName:(CPString)aLastName
{
    self = [super init];
    if (self)
    {
        _firstName = aFirstName;
        _lastName = aLastName;
    }
    return self;
}

- (CPString)fullname
{
    return [CPString stringWithFormat:@"%@ %@", _firstName, _lastName];
}

@end
