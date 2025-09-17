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

+ (void)createTokenfieldContents:(CPView)contentView withDelegate:(id)aDelegate
{
    var tokenFieldA = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 40, 500, 30)],
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
    [tokenFieldB setDelegate:aDelegate];

    [tokenFieldB setAction:@selector(tokenFieldAction:)];
    [tokenFieldB setTarget:aDelegate];

    [contentView addSubview:tokenFieldB];

    var manipulateTokenInsertionButton = [CPCheckBox checkBoxWithTitle:"Token transformations"];
    [manipulateTokenInsertionButton setFrame:CGRectMake(525, 110, 200, 50)];
    [contentView addSubview:manipulateTokenInsertionButton];
    tokenFieldB.manipulateTokenInsertionButton = manipulateTokenInsertionButton;

    var tokenFieldC = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 170, 500, 30)],
        labelC = [[CPTextField alloc] initWithFrame:CGRectMake(15, 150, 500, 24)];

    [labelC setStringValue:"This token field can't fit all its tokens."];
    [contentView addSubview:labelC];

    [tokenFieldC setEditable:YES];
    [tokenFieldC setPlaceholderString:"Edit me!"];

    [tokenFieldC setObjectValue:['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado']];
    [tokenFieldC setDelegate:aDelegate];

    [contentView addSubview:tokenFieldC];

    [tokenFieldC setSendsActionOnEndEditing:YES];
    [tokenFieldC setAction:@selector(tokenFieldAction:)];
    [tokenFieldC setTarget:aDelegate];

    var tokenFieldD = [[CPTokenField alloc] initWithFrame:CGRectMake(15, 230, 500, 30)],
        labelD = [[CPTextField alloc] initWithFrame:CGRectMake(15, 210, 500, 24)],
        tokenFieldDController = [TokenFieldOptionsController new];

    tokenFieldDController.tokenField = tokenFieldD;

    [labelD setStringValue:"This token field contains represented objects."];
    [contentView addSubview:labelD];

    [tokenFieldD setEditable:YES];

    // Delegate must be set before objectValue
    [tokenFieldD setDelegate:aDelegate];

    var tokenFieldDEditable = [CPCheckBox checkBoxWithTitle:"Editable"];
    [tokenFieldDEditable sizeToFit];
    [tokenFieldDEditable setFrameOrigin:CGPointMake(525, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDEditable bind:CPValueBinding toObject:tokenFieldD withKeyPath:@"editable" options:nil];
    [contentView addSubview:tokenFieldDEditable];

    var tokenFieldDMenus = [CPCheckBox checkBoxWithTitle:"Menus"];
    [tokenFieldDMenus sizeToFit];
    [tokenFieldDMenus setFrameOrigin:CGPointMake(CGRectGetMaxX([tokenFieldDEditable frame]) + 5, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDMenus bind:CPValueBinding toObject:tokenFieldDController withKeyPath:@"tokenFieldHasMenus" options:nil];
    [contentView addSubview:tokenFieldDMenus];

    var tokenFieldDClose = [CPCheckBox checkBoxWithTitle:"Close Buttons"];
    [tokenFieldDClose sizeToFit];
    [tokenFieldDClose setFrameOrigin:CGPointMake(CGRectGetMaxX([tokenFieldDMenus frame]) + 5, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDClose bind:CPValueBinding toObject:tokenFieldDController withKeyPath:@"tokenFieldHasCloseButtons" options:nil];
    [contentView addSubview:tokenFieldDClose];

    tokenFieldD._testCompletions = [
        [Person personWithFirstName:@"Luc" lastName:@"Vauvillier"],
        [Person personWithFirstName:@"John" lastName:@"Doe"],
        [Person personWithFirstName:@"Amélie" lastName:@"Poulain"],
        [Person personWithFirstName:@"Jean" lastName:@"Valjean"]
    ];
    [tokenFieldD setObjectValue:[tokenFieldD._testCompletions copy]];

    var tokenFieldDEditable = [CPCheckBox checkBoxWithTitle:"Editable"];
    [tokenFieldDEditable sizeToFit];
    [tokenFieldDEditable setFrameOrigin:CGPointMake(525, 5 + CGRectGetMinY([tokenFieldD frame]))];
    [tokenFieldDEditable bind:CPValueBinding toObject:tokenFieldD withKeyPath:@"editable" options:nil];
    [contentView addSubview:tokenFieldDEditable];

    [contentView addSubview:tokenFieldD];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(15, 270, 0, 0)];
    [button setTitle:"Get Object Values"];
    [button sizeToFit];
    [button setTarget:tokenFieldDController];
    [button setAction:@selector(getObjectValues:)];
    [contentView addSubview:button];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [[self class] createTokenfieldContents:contentView withDelegate:self];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                    selector:@selector(checkDidFocusNotification:)
                                    name:CPTextFieldDidFocusNotification
                                    object:nil]

    [[CPNotificationCenter defaultCenter] addObserver:self
                                    selector:@selector(checkDidBlurNotification:)
                                    name:CPTextFieldDidBlurNotification
                                    object:nil]


    var popoverButton = [[CPButton alloc] initWithFrame:CGRectMake(15, 310, 0, 0)];
    [popoverButton setTitle:"Token Field in a Popover"];
    [popoverButton sizeToFit];
    [popoverButton setTarget:self];
    [popoverButton setAction:@selector(openPopover:)];
    [contentView addSubview:popoverButton];

    [theWindow orderFront:self];
}

- (@action)checkDidFocusNotification:(CPNotification)aNotification
{
    console.log("Field did focus");
}

- (@action)checkDidBlurNotification:(CPNotification)aNotification
{
    console.log("Field did blur");
}

- (@action)openPopover:(id)sender
{
    var aPopover = [CPPopover new],
        controller = [CPViewController new];

    [aPopover setContentViewController:controller];
    [aPopover setContentSize:CGSizeMake(800, 315)];
    [[self class] createTokenfieldContents:[controller view] withDelegate:self];
    [aPopover setAnimates:YES];
    [aPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:CPMaxXEdge];
    [aPopover setBehavior:CPPopoverBehaviorTransient];
}

- (CPArray)tokenField:(CPTokenField)aTokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    var r = [];

    // Don't complete 'blank' - this would show all available matches which is excessive.
    if (!substring)
        return r;

    if (!aTokenField['_testCompletions'])
    {
        for (var i = 0; i < STATES.length; i++)
            if (STATES[i].toLowerCase().indexOf(substring.toLowerCase()) == 0)
                r.push(STATES[i]);
    }
    else
    {
        var allPersons = aTokenField._testCompletions;
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

    if (tokenField['manipulateTokenInsertionButton'] && [tokenField['manipulateTokenInsertionButton'] intValue])
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

@implementation TokenFieldOptionsController : CPObject
{
    CPTokenField tokenField;
}

- (BOOL)tokenFieldHasMenus
{
    return !![[[tokenField objectValue] firstObject] menu];
}

- (void)setTokenFieldHasCloseButtons:(BOOL)shouldHaveCloseButtons
{
   [tokenField setButtonType:shouldHaveCloseButtons ? CPTokenFieldDeleteButtonType : CPTokenFieldDisclosureButtonType];
}

- (BOOL)tokenFieldHasCloseButtons
{
    return !![tokenField buttonType] === CPTokenFieldDeleteButtonType;
}

- (void)setTokenFieldHasMenus:(BOOL)shouldHaveMenus
{
    if (shouldHaveMenus)
    {
        [[tokenField objectValue] enumerateObjectsUsingBlock:function(aPerson)
            {
                var menu = [CPMenu new];
                for (var i = 0; i < 3; i++)
                    [menu addItem:[[CPMenuItem alloc] initWithTitle:[CPString stringWithFormat:@"%@ Item %i", aPerson, i] action:nil keyEquivalent:nil]];
                aPerson.menu = menu;
            }];
    }
    else
        [[tokenField objectValue] makeObjectsPerformSelector:@selector(setMenu:) withObject:nil];
}

- (void)getObjectValues:(id)sender
{
    alert([tokenField objectValue]);
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
