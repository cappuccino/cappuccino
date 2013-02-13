/*
 * AppController.j
 * Smart Folders Demo
 *
 * Created by cacaodev on November 25, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import "BadgedOutlineView.j"
@import "ImageAndTextView.j"

@import <AppKit/CPScrollView.j>

var rootItems = [CPArray arrayWithObject:[CPDictionary dictionaryWithObjectsAndKeys:@"SMART FOLDERS", @"name", YES, @"isContainer"]],
    smartFolderImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/SmartFolder.png" size:CGSizeMake(24, 24)],
    newFolder = [CPDictionary dictionaryWithObjectsAndKeys:@"Smart Folder", @"name", [CPPredicate predicateWithFormat:@"firstName BEGINSWITH ''"], @"predicate"];

@implementation AppController : CPObject
{
// Outlets in MainMenu.cib
    @outlet CPWindow            theWindow;
    @outlet CPView              searchBar;
    @outlet CPSearchField       searchField;
    @outlet CPOutlineView       smartOutlineView;
    @outlet CPTableView         table;
    @outlet CPArrayController   tableController;

// Outlets in PredicateEditor.cib
    @outlet CPPredicateEditor   predicateEditor;
    @outlet CPTextField         folderNameField;
    @outlet CPWindow            predicateSheet;

//Model
    CPArray                     smartFolders;
    CPString                    searchCategory;
    CPArray                     tableArray @accessors;
    CPPredicate                 filterPredicate @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    var path = [[CPBundle mainBundle] pathForResource:@"tableArray.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    smartFolders = [CPArray array];
    // restore saved folders if they exist
    var saved = [[CPUserDefaults standardUserDefaults] objectForKey:@"SmartFolders"];
    if (saved)
    {
        [smartFolders addObjectsFromArray:saved];
        [smartOutlineView reloadData];
    }

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(ruleEditorRowsDidChange:) name:CPRuleEditorRowsDidChangeNotification object:nil];
}
// Save folders into defaults
- (void)saveSmartFolders
{
    [CPTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(_saveSmartFolders) userInfo:nil repeats:NO];
}

- (void)_saveSmartFolders
{
	var defaults = [CPUserDefaults standardUserDefaults];
	[defaults setObject:smartFolders forKey:@"SmartFolders"];
}

- (void)awakeFromCib
{
// Search Bar
    var color = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/searchBarBlue.png" size:CGSizeMake(1.0, 34.0)]];
    [searchBar setBackgroundColor:color];

// Smart Outline View
    var dataView = [[ImageAndTextView alloc] initWithFrame:CGRectMakeZero()],
        column = [[smartOutlineView tableColumns] objectAtIndex:0];
    [column setDataView:dataView];
    [smartOutlineView setBackgroundColor:[CPColor colorWithRed:212.0 / 255.0 green:221.0 / 255.0 blue:230.0 / 255.0 alpha:1.0]];
    [smartOutlineView setDoubleAction:@selector(editFolderAction:)];
    [smartOutlineView setAction:@selector(outlineViewAction:)];
    [smartOutlineView setSourceListDataSource:self];
    [smartOutlineView setRowHeight:26];
    [smartOutlineView expandItem:[smartOutlineView itemAtRow:0]];

// Search Field
    [searchField setSearchMenuTemplate:[searchField defaultSearchMenuTemplate]];
    [searchField setRecentsAutosaveName:"autosave"];

// Button Bar
    var plusButton = [CPButtonBar plusButton],
        minusButton = [CPButtonBar minusButton],
        superView = [[smartOutlineView enclosingScrollView] contentView],
        buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, CGRectGetHeight([superView frame]) - 26, CGRectGetWidth([superView frame]), 26)];

    [plusButton setTarget:self];
    [minusButton setTarget:self];
    [plusButton setAction:@selector(createNewFolder:)];
    [minusButton setAction:@selector(removeFolder:)];

    [buttonBar setHasResizeControl:YES];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [buttonBar setButtons:[CPArray arrayWithObjects:plusButton, minusButton]];
    [superView addSubview:buttonBar];

    [theWindow setFullPlatformWindow:YES];
}
// Get the table data
- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        array = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    var count = [array count];
    while (count--)
    {
        var record = array[count],
            string = [record objectForKey:@"birthDate"],
            date = [[CPDate alloc] initWithString:string];

        [record setObject:date forKey:@"birthDate"];
    }

    [self setTableArray:array];
}

// =======================
// ! Search field action
// =======================
- (IBAction)searchFieldFilter:(id)sender
{
    var searchString = [searchField stringValue],
        predicate = [CPPredicate predicateWithFormat:@"(%K CONTAINS[cd] %@) OR (%K CONTAINS[cd] %@)", "firstName", searchString, "lastName", searchString];

    [self setFilterPredicate:predicate];
}

// ========================
// ! Manage smart folders
// ========================

// Simple click: just filter
- (IBAction)outlineViewAction:(id)sender
{
    var folder = [self selectedFolder],
        predicate = [folder objectForKey:@"predicate"];

    [self setFilterPredicate:predicate];

    [CPTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(setPredicateEditorValue:) userInfo:predicate repeats:NO];
}

- (void)setPredicateEditorValue:(CPTimer)timer
{
    [predicateEditor setObjectValue:[timer userInfo]];
}

// Double click: edit folder
- (IBAction)editFolderAction:(id)sender
{
    var folder = [self selectedFolder];
    [self displaySheetWithFolder:folder];
}

- (IBAction)createNewFolder:(id)sender
{
    var folder = [newFolder copy];
    [smartFolders addObject:folder];
    [smartOutlineView reloadData];
    [smartOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:[smartFolders count]] byExtendingSelection:NO];

    [self displaySheetWithFolder:folder];
}

- (IBAction)removeFolder:(id)sender
{
    var selectionIndexes = [smartOutlineView selectedRowIndexes];
    if ([selectionIndexes count] == 0)
        return;

    [smartFolders removeObjectAtIndex:[selectionIndexes firstIndex] - 1];
    [smartOutlineView reloadData];
    [smartOutlineView selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
    [self saveSmartFolders];
}

- (void)displaySheetWithFolder:(id)folder
{
    if (predicateSheet == nil)
        [CPBundle loadCibNamed:@"PredicateEditor" owner:self];

    [folderNameField setStringValue:[folder objectForKey:@"name"]];
    [predicateEditor setObjectValue:[folder objectForKey:@"predicate"]]; // nil is ok

    [predicateSheet makeFirstResponder:folderNameField];

    [CPApp beginSheet:predicateSheet modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:folder:) contextInfo:folder];
}

- (IBAction)closeSheet:(id)sender
{
    if ([sender tag] == CPOKButton)
    	[predicateEditor reloadPredicate];

    [CPApp endSheet:predicateSheet returnCode:[sender tag]];
}

- (void)sheetDidEnd:(CPWindow)aSheet returnCode:(int)returnCode folder:(id)folder
{
    var name = [folderNameField stringValue];

    if (returnCode == CPOKButton && [name length] > 0)
    {
        var predicate = [predicateEditor objectValue];
        [self setFilterPredicate:predicate];

    	[folder setObject:predicate forKey:@"predicate"];
    	[folder setObject:name forKey:@"name"];
        [folder setObject:[[tableController arrangedObjects] count] forKey:@"count"];
    	[smartOutlineView reloadData];

    	[self saveSmartFolders];
    }
}
// convenience method
- (id)selectedFolder
{
    var selectionIndexes = [smartOutlineView selectedRowIndexes];
    if ([selectionIndexes count] > 0)
    {
        return [smartFolders objectAtIndex:[selectionIndexes firstIndex] - 1]; // O is not selectable
    }

    return nil;
}

// ================================================================
//  Badged Outline View data source & delegate methods.
// ================================================================

- (CPArray)childrenForItem:(id)item
{
    if (item == nil)
        return rootItems;

    return smartFolders;
}

- (id)outlineView:(CPOutlineView)theOutlineView child:(CPInteger)index ofItem:(id)item
{
    var children = [self childrenForItem:item];
    return [children objectAtIndex:index];
}

- (CPInteger)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)item
{
    var children = [self childrenForItem:item];
    return [[self childrenForItem:item] count];
}

- (id)outlineView:(CPOutlineView)theOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return " " + [item objectForKey:@"name"];
}

- (void)outlineView:(CPOutlineView)theOutlineView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)tableColumn item:(id)item
{
    if (![aView isKindOfClass:[ImageAndTextView class]])
        return;

    var isContainer = !![item objectForKey:@"isContainer"];
    if (isContainer)
    {
        [aView setFont:[CPFont boldSystemFontOfSize:11.0]];
        [aView setTextColor:[CPColor colorWithWhite:100.0 / 255.0 alpha:0.9]];
        [aView setImagePosition:CPNoImage];
    }
    else
    {
        [aView setImagePosition:CPImageLeft];
        [aView setImage:smartFolderImage];
    }
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView shouldSelectItem:(id)item
{
    return ![item objectForKey:@"isContainer"];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)item
{
    return !![item objectForKey:@"isContainer"];
}
// Badged outline data source methods
- (BOOL)sourceList:(CPOutlineView)aSourceList itemHasBadge:(id)item
{
    return ([item objectForKey:@"count"] != nil);
}

- (CPInteger)sourceList:(CPOutlineView)aSourceList badgeValueForItem:(id)item
{
    return [item objectForKey:@"count"];
}

// Resize the sheet if needed
- (void)ruleEditorRowsDidChange:(CPNotification)notif
{
/*
    var frame = [predicateSheet frame],
        newHeight = [predicateEditor numberOfRows] * [predicateEditor rowHeight] + 103;

    frame.size.height = MAX([predicateSheet minSize].height, newHeight);
    [predicateSheet setFrame:frame display:[predicateSheet isSheet] animate:[predicateSheet isSheet]];
*/
}

@end
