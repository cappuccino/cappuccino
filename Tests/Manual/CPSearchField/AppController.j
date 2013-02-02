/*
 * AppController.j
 * CPSearchField
 *
 * Created by cacaodev on November 27, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

var categories = ["firstName", "lastName"],
    MenuItemPrefix = @"   ";

@implementation AppController : CPObject
{
    CPWindow      theWindow;
    CPTextField   predicateField;

    CPSearchField searchField;
    CPMenu        searchMenuTemplate;

    CPArray       searchCategoryIndexes;
    CPInteger     searchCategoryIndex;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    searchCategoryIndex = 0;
    searchCategoryIndexes = [CPArray arrayWithArray:[1, 2]];

    searchField = [[CPSearchField alloc] initWithFrame:CPMakeRect(30, 72, 150, 30)];

    [searchField setRecentsAutosaveName:"autosave"];
    [searchField setTarget:self];
    [searchField setAction:@selector(updateFilter:)];
    [searchField setAutoresizingMask:CPViewMaxXMargin | CPViewMaxYMargin];

    searchMenuTemplate = [searchField defaultSearchMenuTemplate];

    [searchMenuTemplate insertItemWithTitle:@"Search By"
                                     action:nil
                              keyEquivalent:@""
                                    atIndex:0];

    var item = [[CPMenuItem alloc] initWithTitle:MenuItemPrefix + @"First Name"
                                          action:@selector(changeCategory:)
                                   keyEquivalent:@""];

    [item setTarget:self];
    [item setTag:1];
    [item setState:CPOnState];
    [searchMenuTemplate insertItem:item atIndex:1];

    item = [[CPMenuItem alloc] initWithTitle:MenuItemPrefix + @"Last Name"
                                      action:@selector(changeCategory:)
                                keyEquivalent:@""];
    [item setTarget:self];
    [item setTag:2];
    [item setState:CPOffState];
    [searchMenuTemplate insertItem:item atIndex:2];

    [searchField setSearchMenuTemplate:searchMenuTemplate];

    var button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
    [button setBackgroundColor:[CPColor greenColor]];
    [button setBordered:NO];
    [searchField setSearchButton:button];

    button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
    [button setBackgroundColor:[CPColor blueColor]];
    [button setBordered:NO];
    [searchField setCancelButton:button];

    [[theWindow contentView] addSubview:searchField];

    [self changeCategory:[[searchField menu] itemAtIndex:1]];
    [self updateFilter:searchField];

    [searchField setDelegate:self];

    [theWindow center];
    [theWindow orderFront:self];
}

- (void)controlTextDidChange:(id)note
{
    CPLogConsole(_cmd);
}

- (void)awakeFromCib
{
    [theWindow setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)sendsWholeSearchString:(id)sender
{
    [searchField setSendsWholeSearchString:[sender state]];
}

- (IBAction)searchesImmediately:(id)sender
{
    [searchField setSendsSearchStringImmediately:[sender state]];
}

- (void)changeCategory:(CPMenuItem)menuItem
{
    searchCategoryIndex = [menuItem tag] - 1;
    [searchField setPlaceholderString:[[menuItem title] substringFromIndex:[MenuItemPrefix length]]];

    [self _updateSearchMenuTemplate];
}

- (void)_updateSearchMenuTemplate
{
    for (var i = 0; i < searchCategoryIndexes.length; ++i)
        [[searchMenuTemplate itemAtIndex:i + 1] setState:CPOffState];

    [[searchMenuTemplate itemAtIndex:searchCategoryIndex + 1] setState:CPOnState];
    [searchField setSearchMenuTemplate:searchMenuTemplate];
}

- (void)updateFilter:(id)sender
{
    var searchString = [sender stringValue];
    [self filteredArrayWithString:searchString];
}

- (void)filteredArrayWithString:(CPString)value
{
    var keyPath = categories[searchCategoryIndex],
        predicate = [CPPredicate predicateWithFormat:@"%K CONTAINS %@", keyPath, value];

    [predicateField setStringValue:[predicate predicateFormat]];
}

@end
