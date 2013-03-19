/*
 * AppController.j
 * CPComboBoxTest
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2011, Intalio, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPComboBox.j>


@implementation Companies : CPObject
{
    CPMutableArray items @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        items = [CPMutableArray array];

        var employees = "Tom,Dick,Harry,Ted,Sam,Fred,Ralph,Ed,Tim,John,Bill,Irving,Stan,Rodney".split(",");

        employees = [CPArray arrayWithObjects:employees count:employees.length];
        [items addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Spacely Sprockets", @"name", employees, @"employees"]];

        employees = "Jane,Sally,Joan,Sara,Melissa,Beverly,Gillian,Sandra,Samantha,Mary,Kate".split(",");
        employees = [CPArray arrayWithObjects:employees count:employees.length];
        [items addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Cogswell Cogs", @"name", employees, @"employees"]];
    }

    return self;
}

@end

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    CPWindow            testWindow;
    CPString            employee @accessors;
    Companies           companies @accessors;
    CPArrayController   companiesController;
    CPArrayController   employeesController;
    CPComboBox          combo;
    @outlet CPComboBox  cibCombo;
    @outlet CPTextField comboTarget;
    CPString            fontName;
    int                 nextCheckboxY;

    @outlet CPComboBox  disabledCombo;
}

- (id)init
{
    if (self = [super init])
    {
        fontName = [CPFont systemFontFace];
        companies = [Companies new];
    }

    return self;
}

- (void)awakeFromCib
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    testWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(30, 50, 500, 400) styleMask:CPTitledWindowMask | CPResizableWindowMask];

    // test disabling from IB
    if (![disabledCombo isEnabled])
        console.log("diabledCombo box has been correctly disabled from Interface Builder.");
    else
        console.log("There was a problem disabling disabledCombo from Interface Builder.");

    var contentView = [testWindow contentView],
        companiesScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(30, 30, 200, 100)],
        companiesTable = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        employeesScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(250, 30, 200, 200)],
        employeesTable = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];

    [testWindow setTitle:@"CPComboBox (from code)"];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [column setResizingMask:CPTableColumnAutoresizingMask];
    [companiesTable addTableColumn:column];
    [companiesTable setAllowsMultipleSelection:YES];
    [companiesTable setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [companiesScrollView setHasHorizontalScroller:NO];
    [companiesScrollView setHasVerticalScroller:YES];
    [companiesScrollView setDocumentView:companiesTable];
    [companiesScrollView setBorderType:CPBezelBorder];
    [companiesTable setHeaderView:nil];
    [companiesTable setAllowsEmptySelection:NO];

    [contentView addSubview:companiesScrollView];

    column = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [column setResizingMask:CPTableColumnAutoresizingMask];
    [employeesTable addTableColumn:column];
    [employeesTable setAllowsMultipleSelection:YES];
    [employeesTable setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [employeesScrollView setHasHorizontalScroller:NO];
    [employeesScrollView setHasVerticalScroller:YES];
    [employeesScrollView setDocumentView:employeesTable];
    [employeesScrollView setBorderType:CPBezelBorder];
    [employeesTable setHeaderView:nil];
    [employeesTable setAllowsEmptySelection:YES];

    [contentView addSubview:employeesScrollView];

    combo = [[CPComboBox alloc] initWithFrame:CGRectMake(250, 240, 200, 31)];
    [combo setCompletes:YES];
    [contentView addSubview:combo];

    var textfield = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:200];
    [textfield setFrameOrigin:CGPointMake(250, 290)];
    [contentView addSubview:textfield];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(comboNote:) name:CPComboBoxSelectionDidChangeNotification object:combo];
    [center addObserver:self selector:@selector(comboNote:) name:CPComboBoxSelectionIsChangingNotification object:combo];
    [center addObserver:self selector:@selector(comboNote:) name:CPComboBoxWillDismissNotification object:combo];
    [center addObserver:self selector:@selector(comboNote:) name:CPComboBoxWillPopUpNotification object:combo];
    [center addObserver:self selector:@selector(comboNote:) name:CPControlTextDidEndEditingNotification object:combo];

    nextCheckboxY = 166;
    [self makeCheckBoxWithTitle:@"Enabled" defaultState:CPOnState];
    [self makeCheckBoxWithTitle:@"Button bordered" defaultState:CPOnState];
    [self makeCheckBoxWithTitle:@"Bold" defaultState:CPOffState];
    [self makeCheckBoxWithTitle:@"Completes" defaultState:CPOnState];
    [self makeCheckBoxWithTitle:@"Force selection" defaultState:CPOffState];
    [self makeCheckBoxWithTitle:@"Vertical scrollbar" defaultState:CPOnState];
    [self makeCheckBoxWithTitle:@"Big item height" defaultState:CPOffState];
    [self makeCheckBoxWithTitle:@"More visible items" defaultState:CPOffState];

    companiesController = [CPArrayController new];
    [companiesController bind:@"contentArray" toObject:companies withKeyPath:@"items" options:nil];

    employeesController = [CPArrayController new];
    [employeesController bind:@"contentArray" toObject:companiesController withKeyPath:@"selection.employees" options:nil];

    var employeeController = [CPObjectController new];
    [employeeController bind:@"content" toObject:employeesController withKeyPath:@"selection.self" options:nil];

    [[companiesTable tableColumnWithIdentifier:@"name"] bind:@"value" toObject:companiesController withKeyPath:@"arrangedObjects.name" options:nil];
    [[employeesTable tableColumnWithIdentifier:@"name"] bind:@"value" toObject:employeesController withKeyPath:@"arrangedObjects" options:nil];
    [combo bind:@"contentValues" toObject:employeesController withKeyPath:@"arrangedObjects" options:nil];
    [combo bind:@"value" toObject:employeeController withKeyPath:@"content" options:nil];

    [companiesController addObserver:self forKeyPath:@"selection" options:0 context:@"companies.selection"];
    [companiesController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:@"companies.selectionIndexes"];
    [companiesController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:@"companies.arrangedObjects"];
    [employeesController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:@"employees.selectionIndexes"];
    [employeesController addObserver:self forKeyPath:@"selection" options:0 context:@"employees.selection"];
    [employeesController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:@"employees.arrangedObjects"];
    [combo addObserver:self forKeyPath:@"value" options:0 context:@"combo.value"];

    [testWindow setInitialFirstResponder:combo];
    [testWindow makeKeyAndOrderFront:self];
}

- (void)makeCheckBoxWithTitle:(CPString)aTitle defaultState:(BOOL)aState
{
    var checkbox = [CPCheckBox checkBoxWithTitle:aTitle];
    [checkbox setFrameOrigin:CGPointMake(55, nextCheckboxY)];
    [checkbox setState:aState];
    [checkbox setTarget:self];
    [checkbox setAction:@selector(setComboState:)];
    [[testWindow contentView] addSubview:checkbox];

    nextCheckboxY += 25;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    console.log("\nkeyPath: %s\ncontext: %s\nnew: %s\nold: %s", keyPath, context, [[change valueForKey:CPKeyValueChangeNewKey] description], [[change valueForKey:CPKeyValueChangeOldKey] description]);
}

- (void)setComboState:(id)sender
{
    var title = [sender title],
        state = [sender state] === CPOnState;

    if (title === @"Enabled")
        [combo setEnabled:state];
    else if (title === @"Button bordered")
        [combo setButtonBordered:state];
    else if (title === @"Bold")
    {
        var font = [sender state] === CPOnState ? [CPFont boldFontWithName:fontName size:12] : [CPFont fontWithName:fontName size:12];
        [combo setFont:font];
    }
    else if (title === @"Completes")
        [combo setCompletes:state];
    else if (title === @"Force selection")
        [combo setForceSelection:state];
    else if (title === @"Vertical scroller")
        [combo setHasVerticalScroller:state];
    else if (title === @"Big item height")
        [combo setItemHeight:state ? 47 : 23];
    else if (title === @"More visible items")
        [combo setNumberOfVisibleItems:state ? 10 : 5];
}

- (void)comboNote:(CPNotification)aNote
{
    console.log([aNote name]);

    var object = [aNote object];

    if ([aNote name] === CPComboBoxWillDismissNotification)
        console.log("Selected: %d - %s", [object indexOfSelectedItem], [object objectValueOfSelectedItem]);
}

@end
