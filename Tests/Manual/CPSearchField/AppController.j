/*
 * AppController.j
 *
 * Created by __Me__ on __Date__.
 * Copyright 2008 __MyCompanyName__. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

var categories = ["firstName","lastName"],
    MenuItemPrefix = @"   ";

@implementation AppController : CPObject
{
	CPSearchField   searchField;	
	CPTableView     table;
	
	CPArray         tableArray;
	CPArray         filteredArray;
	
	CPMenu          searchMenuTemplate;
	
	CPArray         searchCategoryIndexes;
	CPInteger       searchCategoryIndex;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	searchCategoryIndex = 0;
	searchCategoryIndexes = [CPArray arrayWithArray:[1, 2]];
	
    var theWindow = [[CPWindow alloc] initWithContentRect:CPMakeRect(0,10,500,300) styleMask:CPTitledWindowMask|CPResizableWindowMask],
        contentView = [theWindow contentView];
    
    var searchFieldContainer = [[CPView alloc] initWithFrame:CPMakeRect(10,10,220,50)];
    [searchFieldContainer setBackgroundColor:[CPColor redColor]];
    [searchFieldContainer setAutoresizingMask:CPViewWidthSizable];
    
    searchField = [[CPSearchField alloc] initWithFrame:CPMakeRect(10,10,200,30)];    
   
    [searchField setRecentsAutosaveName:"autosave"];
    [searchField setTarget:self];
    [searchField setAction:@selector(updateFilter:)];
    [searchField setAutoresizingMask:CPViewWidthSizable];
    
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
    
    [searchFieldContainer addSubview:searchField];
    [contentView addSubview:searchFieldContainer];
    
    tableArray = [CPArray arrayWithObjects:
                [CPDictionary dictionaryWithObjects:["Jimmy","McNulty",46] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Kima","Greggs",41] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Lester","Freamon",57] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Kevin	","Russel",37] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["William","Moreland",53] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Cedric","Daniels",47] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Roland","Pryzbylewski",27] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Omar","Little",29] forKeys:["firstName","lastName","age"]],
                [CPDictionary dictionaryWithObjects:["Avon","Barkstale",49] forKeys:["firstName","lastName","age"]],
                nil];
	filteredArray = tableArray;

 	table = [[CPTableView alloc] initWithFrame:CPMakeRect(10,60,300,300)];
	[table setUsesAlternatingRowBackgroundColors:YES];
	var colone = [[CPTableColumn alloc] initWithIdentifier:@"firstName"];
	[colone setWidth:150];	
	[table addTableColumn:colone];
	
	var coltwo = [[CPTableColumn alloc] initWithIdentifier:@"lastName"];
	[coltwo setWidth:150];	
	[table addTableColumn:coltwo];
	
	[table setDataSource:self];	
	[contentView addSubview:table];
	
    [self changeCategory:[[searchField menu] itemAtIndex:1]];
    [self updateFilter:nil];
    
    [theWindow center];
	[theWindow orderFront:self]; 
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
	return [filteredArray count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{
	return [filteredArray[rowIndex] objectForKey:[aTableColumn identifier]];
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
	var searchString = [searchField stringValue];
	
	filteredArray = [self filteredArrayWithString:searchString];
	[table reloadData];
}

- (CPArray)filteredArrayWithString:(CPString)string
{
	var keyPath = categories[searchCategoryIndex];
	CPLogConsole("Filter the table here. Predicate would be *" + keyPath + " CONTAINS '" + string + "'*");
	return tableArray;
}

@end
