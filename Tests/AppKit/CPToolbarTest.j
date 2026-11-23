/*
 *  CPToolbarTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-16.
 *  Copyright David Richardson 2026.
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

@import <AppKit/AppKit.j>

@import "BuiltThemes.j"

var ToolbarTestItemIdentifier = @"ToolbarTestItem";

/*
    Makes a toolbar item whose view is a button with the given target.
*/
var ToolbarTestMakeViewItem = function(aTarget)
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 24.0)],
        item = [[CPToolbarItem alloc] initWithItemIdentifier:ToolbarTestItemIdentifier];

    [button setTitle:@"Test"];
    [button setTarget:aTarget];
    [button setAction:@selector(toolbarTestAction:)];

    [item setLabel:@"Test"];
    [item setView:button];
    [item setMinSize:CGSizeMake(60.0, 24.0)];
    [item setMaxSize:CGSizeMake(60.0, 24.0)];

    return item;
};

/*
    A toolbar delegate that gives view items. It gives a new item for each call, as AppKit expects,
    or one cached item for every call when cachesItems is YES.
*/
@implementation _ToolbarTestDelegate : CPObject
{
    CPArray         itemIdentifiers @accessors;
    BOOL            cachesItems     @accessors;
    CPToolbarItem   cachedItem      @accessors(readonly);
    CPArray         givenItems      @accessors(readonly);
}

- (id)init
{
    if (self = [super init])
    {
        itemIdentifiers = [ToolbarTestItemIdentifier];
        cachesItems = NO;
        givenItems = [];
    }

    return self;
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return itemIdentifiers;
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return itemIdentifiers;
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    if (cachesItems && cachedItem)
        return cachedItem;

    var item = ToolbarTestMakeViewItem(self);

    [givenItems addObject:item];

    if (cachesItems)
        cachedItem = item;

    return item;
}

- (void)toolbarTestAction:(id)aSender
{
}

@end

/*
    A toolbar delegate that gives standard items only and records the notifications of added and
    removed items.
*/
@implementation _ToolbarTestRecordingDelegate : CPObject
{
    CPArray     itemIdentifiers     @accessors;
    CPArray     addedItems          @accessors(readonly);
    CPArray     removedItems        @accessors(readonly);
}

- (id)init
{
    if (self = [super init])
    {
        itemIdentifiers = [CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier];
        addedItems = [];
        removedItems = [];
    }

    return self;
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return itemIdentifiers;
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return itemIdentifiers;
}

- (void)toolbarWillAddItem:(CPNotification)aNotification
{
    [addedItems addObject:[[aNotification userInfo] objectForKey:@"item"]];
}

- (void)toolbarDidRemoveItem:(CPNotification)aNotification
{
    [removedItems addObject:[[aNotification userInfo] objectForKey:@"item"]];
}

@end

/*
    Returns the item identifiers of a toolbar's items.
*/
var ToolbarTestIdentifiersOf = function(aToolbar)
{
    return [[aToolbar items] valueForKey:@"itemIdentifier"];
};

/*
    Dragging information for a drop on the customization overlay.
*/
/*
    A toolbar delegate and validator with one item, which is enabled only while its window has
    no attached sheet.
*/
@implementation _ToolbarTestSheetValidator : CPObject
{
    CPWindow    window  @accessors;
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [@"SheetValidatedItem"];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [@"SheetValidatedItem"];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];

    [item setLabel:@"Validated"];
    [item setTarget:self];
    [item setAction:@selector(act:)];

    return item;
}

- (void)act:(id)aSender
{
}

- (BOOL)validateToolbarItem:(CPToolbarItem)anItem
{
    return ![window attachedSheet];
}

@end

@implementation _ToolbarTestDraggingInfo : CPObject
{
    CPPasteboard    draggingPasteboard  @accessors;
    CGPoint         draggingLocation    @accessors;
    id              draggingSource      @accessors;
}

@end

@implementation CPToolbarTest : OJTestCase

- (void)testTheItemTheDelegateGivesForInsertionIsInserted
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestInsertion"];

    [toolbar setDelegate:delegate];

    var givenItem = [delegate givenItems][0],
        insertedItem = [toolbar items][0];

    [self assert:givenItem same:insertedItem message:@"the toolbar must insert the item that the delegate gives"];
    [self assert:[givenItem view] same:[insertedItem view] message:@"the toolbar must show the view that the application made"];
    [self assert:toolbar same:[insertedItem toolbar]];
}

- (void)testTheViewOfAnInsertedItemKeepsItsTarget
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestTarget"];

    [toolbar setDelegate:delegate];

    [self assert:delegate same:[[[toolbar items][0] view] target] message:@"the control in a view item must keep its target"];
}

/*
    nib2cib gives a decoded toolbar its items in these two instance variables. An outlet in the
    same cib reaches the decoded item and its view, so the toolbar must show those.
*/
- (void)testAnItemDecodedWithTheToolbarIsInsertedAsDecoded
{
    var sourceToolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestDecoded"],
        sourceItem = ToolbarTestMakeViewItem(nil);

    sourceToolbar._identifiedItems = @{ ToolbarTestItemIdentifier: sourceItem };
    sourceToolbar._defaultItems = [sourceItem];

    var toolbar = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:sourceToolbar]];

    // The decoded toolbar loads its items at the end of the run loop.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    var decodedItem = [toolbar._identifiedItems objectForKey:ToolbarTestItemIdentifier],
        insertedItem = [toolbar items][0];

    [self assert:decodedItem same:insertedItem message:@"the toolbar must insert the decoded item"];
    [self assert:[decodedItem view] same:[insertedItem view] message:@"the toolbar must show the decoded view"];
}

- (void)testAnItemGivenForTwoPlacesIsCopiedForTheSecond
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestTwoPlaces"];

    [delegate setCachesItems:YES];
    [delegate setItemIdentifiers:[ToolbarTestItemIdentifier, ToolbarTestItemIdentifier]];
    [toolbar setDelegate:delegate];

    var cachedItem = [delegate cachedItem],
        items = [toolbar items];

    [self assert:cachedItem same:items[0] message:@"the first place must hold the item that the delegate gives"];
    [self assertFalse:cachedItem === items[1] message:@"the second place must hold a copy"];
    [self assertFalse:[cachedItem view] === [items[1] view] message:@"the copy must have a view of its own"];
    [self assert:toolbar same:[items[1] toolbar]];
}

- (void)testAnItemShownByAnotherToolbarIsCopied
{
    var delegate = [_ToolbarTestDelegate new],
        firstToolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestShared"],
        secondToolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestShared"];

    [delegate setCachesItems:YES];
    [firstToolbar setDelegate:delegate];
    [secondToolbar setDelegate:delegate];

    var cachedItem = [delegate cachedItem];

    [self assert:cachedItem same:[firstToolbar items][0] message:@"the first toolbar must keep the item"];
    [self assert:firstToolbar same:[cachedItem toolbar]];
    [self assertFalse:cachedItem === [secondToolbar items][0] message:@"the second toolbar must show a copy"];
    [self assert:secondToolbar same:[[secondToolbar items][0] toolbar]];
}

- (void)testAReloadKeepsTheItemThatTheToolbarShows
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestReload"];

    [delegate setCachesItems:YES];
    [toolbar setDelegate:delegate];

    // A change of display mode reloads the items.
    [toolbar setDisplayMode:CPToolbarDisplayModeIconOnly];

    [self assert:[delegate cachedItem] same:[toolbar items][0] message:@"a reload must not copy an item that the toolbar shows"];
}

- (void)testAnItemViewThatAReloadDiscardsNoLongerFollowsItsItem
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestItemViews"];

    [delegate setCachesItems:YES];
    [toolbar setDelegate:delegate];

    var toolbarView = [toolbar _toolbarView],
        item = [toolbar items][0],
        discardedItemView = [toolbarView viewForItem:item];

    [toolbar setDisplayMode:CPToolbarDisplayModeIconOnly];

    var currentItemView = [toolbarView viewForItem:item];

    [self assertFalse:discardedItemView === currentItemView message:@"a reload must make new item views"];

    [item setEnabled:NO];

    [self assertFalse:[currentItemView isEnabled] message:@"the current item view must follow its item"];
    [self assertTrue:[discardedItemView isEnabled] message:@"a discarded item view must no longer follow its item"];
}

/*
    Returns the toolbar view and the view of the first item of a new toolbar.
*/
- (CPArray)toolbarViewAndItemView
{
    var delegate = [_ToolbarTestDelegate new],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestLabel"];

    [toolbar setDelegate:delegate];

    var toolbarView = [toolbar _toolbarView];

    return [toolbarView, [toolbarView viewForItem:[toolbar items][0]]];
}

- (void)testNoThemeGivesToolbarLabelsAShadow
{
    var toolbarView = [self toolbarViewAndItemView][0];

    [self assertNull:[toolbarView valueForThemeAttribute:@"label-shadow-color" inState:CPThemeStateNormal]];
    [self assertNull:[toolbarView valueForThemeAttribute:@"label-shadow-color" inState:CPThemeStateHighlighted]];
}

- (void)testALabelTakesTheLabelColorOfTheToolbarView
{
    var views = [self toolbarViewAndItemView],
        color = [CPColor redColor];

    [views[0] setValue:color forThemeAttribute:@"label-color"];
    [views[1] layoutSubviews];

    [self assert:color same:[views[1]._labelField textColor]];
}

- (void)testADisabledItemTakesTheDisabledLabelColorAtFullOpacity
{
    var views = [self toolbarViewAndItemView],
        color = [CPColor blueColor];

    [views[0] setValue:[CPColor redColor] forThemeAttribute:@"label-color"];
    [views[0] setValue:color forThemeAttribute:@"label-color" inState:CPThemeStateDisabled];
    [views[1] setEnabled:NO];
    [views[1] layoutSubviews];

    [self assert:color same:[views[1]._labelField textColor]];
    [self assert:1.0 equals:[views[1]._labelField alphaValue]];
}

- (void)testAnItemInAHUDWindowTakesTheHUDLabelColor
{
    var views = [self toolbarViewAndItemView],
        color = [CPColor greenColor];

    [views[0] setValue:color forThemeAttribute:@"label-color" inState:CPThemeStateHUD];
    [views[1] setThemeState:CPThemeStateHUD];
    [views[1] layoutSubviews];

    [self assert:color same:[views[1]._labelField textColor]];
}

- (void)testAHighlightedItemTakesTheHighlightedLabelShadow
{
    var views = [self toolbarViewAndItemView],
        color = [CPColor redColor],
        offset = CGSizeMake(0.0, 2.0);

    [views[0] setValue:color forThemeAttribute:@"label-shadow-color" inState:CPThemeStateHighlighted];
    [views[0] setValue:offset forThemeAttribute:@"label-shadow-offset" inState:CPThemeStateHighlighted];
    /*
        The test item has a custom view, which never takes the highlight: -mouseDown: passes the
        click on. The label depends only on the highlighted theme state, so the test sets it.
    */
    [views[1] setThemeState:CPThemeStateHighlighted];
    [views[1] layoutSubviews];

    [self assert:color same:[views[1]._labelField textShadowColor]];
    [self assertTrue:CGSizeEqualToSize(offset, [views[1]._labelField textShadowOffset])];
}

- (void)testALabelTakesTheLabelFontOfTheToolbarView
{
    var views = [self toolbarViewAndItemView],
        font = [CPFont boldSystemFontOfSize:13.0];

    [views[0] setValue:font forThemeAttribute:@"label-font"];
    [views[1] updateFromItem];

    [self assert:font same:[views[1]._labelField font]];
}

// MARK: Standard items

/*
    Show Fonts, Print and Customize Toolbar had identifiers but no standard item, so a toolbar
    that listed one asked its delegate and raised when the delegate gave none.
*/
- (void)assertStandardItem:(CPString)anIdentifier label:(CPString)aLabel paletteLabel:(CPString)aPaletteLabel action:(SEL)anAction imageName:(CPString)anImageName
{
    var item = [CPToolbarItem _standardItemWithItemIdentifier:anIdentifier];

    [self assertNotNull:item message:anIdentifier];
    [self assert:anIdentifier equals:[item itemIdentifier] message:anIdentifier + @", identifier"];
    [self assert:aLabel equals:[item label] message:anIdentifier + @", label"];
    [self assert:aPaletteLabel equals:[item paletteLabel] message:anIdentifier + @", palette label"];
    [self assert:anAction equals:[item action] message:anIdentifier + @", action"];
    [self assert:[CPImage imageNamed:anImageName] same:[item image] message:anIdentifier + @", image"];
}

- (void)testShowFontsPrintAndCustomizeToolbarAreStandardItems
{
    [self assertStandardItem:CPToolbarShowFontsItemIdentifier label:@"Fonts" paletteLabel:@"Show Fonts" action:@selector(orderFrontFontPanel:) imageName:CPImageNameFontPanel];
    [self assertStandardItem:CPToolbarPrintItemIdentifier label:@"Print" paletteLabel:@"Print" action:@selector(printDocument:) imageName:CPImageNamePrint];
    [self assertStandardItem:CPToolbarCustomizeToolbarItemIdentifier label:@"Customize" paletteLabel:@"Customize Toolbar" action:@selector(runToolbarCustomizationPalette:) imageName:CPImageNameCustomizeToolbar];
}

/*
    As in AppKit, Show Fonts goes to the shared font manager; Print and Customize Toolbar go
    along the responder chain.
*/
- (void)testTheStandardItemsHaveAppKitsTargets
{
    [self assert:[CPFontManager sharedFontManager] same:[[CPToolbarItem _standardItemWithItemIdentifier:CPToolbarShowFontsItemIdentifier] target]];
    [self assertNull:[[CPToolbarItem _standardItemWithItemIdentifier:CPToolbarPrintItemIdentifier] target]];
    [self assertNull:[[CPToolbarItem _standardItemWithItemIdentifier:CPToolbarCustomizeToolbarItemIdentifier] target]];
}

/*
    These tests read the built Aristo3 theme, so they need the themes built first, as
    `npx jake build` does.
*/
- (void)testAristo3GivesTheImagesOfTheStandardItems
{
    var theme = BuiltThemeNamed(@"Aristo3"),
        names = [@"font-panel", @"print", @"customize-toolbar"];

    [self assertNotNull:theme message:@"The built blends hold no Aristo3 theme. Build the themes first."];

    for (var i = 0; i < names.length; i++)
        [self assertNotNull:[[theme attributeWithName:names[i] forClass:[CPImage defaultThemeClass]] values] message:names[i]];
}

// MARK: Customization and configuration

- (void)testCustomizationAndAutosaveAreOffByDefault
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestDefaults"];

    [self assertFalse:[toolbar allowsUserCustomization] message:@"customization"];
    [self assertFalse:[toolbar autosavesConfiguration] message:@"autosave"];
}

- (void)testCustomizationAndAutosaveSurviveArchiving
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestArchiving"];

    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:toolbar]];

    [self assertTrue:[decoded allowsUserCustomization] message:@"customization"];
    [self assertTrue:[decoded autosavesConfiguration] message:@"autosave"];

    [[CPUserDefaults standardUserDefaults] removeObjectForKey:@"CPToolbar Configuration CPToolbarTestArchiving"];
}

- (void)testInsertingAnItemPlacesItAtTheIndex
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestInsert"];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar insertItemWithItemIdentifier:CPToolbarSeparatorItemIdentifier atIndex:1];

    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar)];
    [self assert:toolbar same:[[toolbar items][1] toolbar]];
}

- (void)testInsertingAnItemTellsTheDelegateAndPostsANotification
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestWillAdd"],
        delegate = [_ToolbarTestRecordingDelegate new],
        posted = [],
        observer = [[CPNotificationCenter defaultCenter] addObserverForName:CPToolbarWillAddItemNotification object:toolbar queue:nil usingBlock:function(aNotification)
        {
            posted.push(aNotification);
        }];

    [toolbar setDelegate:delegate];
    [toolbar insertItemWithItemIdentifier:CPToolbarSeparatorItemIdentifier atIndex:0];

    [[CPNotificationCenter defaultCenter] removeObserver:observer];

    [self assert:[[toolbar items][0]] equals:[delegate addedItems] message:@"the delegate"];
    [self assert:1 equals:posted.length message:@"the notification"];
    [self assert:[toolbar items][0] same:[[posted[0] userInfo] objectForKey:@"item"]];
}

- (void)testRemovingAnItemTellsTheDelegateAndPostsANotification
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestDidRemove"],
        delegate = [_ToolbarTestRecordingDelegate new],
        posted = [],
        observer = [[CPNotificationCenter defaultCenter] addObserverForName:CPToolbarDidRemoveItemNotification object:toolbar queue:nil usingBlock:function(aNotification)
        {
            posted.push(aNotification);
        }];

    [toolbar setDelegate:delegate];

    var removedItem = [toolbar items][0];

    [toolbar removeItemAtIndex:0];

    [[CPNotificationCenter defaultCenter] removeObserver:observer];

    [self assert:[CPToolbarFlexibleSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar)];
    [self assert:[removedItem] equals:[delegate removedItems] message:@"the delegate"];
    [self assert:1 equals:posted.length message:@"the notification"];
}

- (void)testTheConfigurationDictionaryHoldsTheItemsAndTheModes
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestConfiguration"];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar setDisplayMode:CPToolbarDisplayModeIconOnly];

    var configuration = [toolbar configurationDictionary];

    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier] equals:[configuration objectForKey:@"TB Item Identifiers"]];
    [self assert:CPToolbarDisplayModeIconOnly equals:[configuration objectForKey:@"TB Display Mode"]];
    [self assert:1 equals:[configuration objectForKey:@"TB Is Shown"]];
}

- (void)testAConfigurationTakesThePlaceOfTheDefaultItems
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestSetConfiguration"];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar setConfigurationFromDictionary:@{ @"TB Item Identifiers": [CPToolbarSeparatorItemIdentifier, CPToolbarSpaceItemIdentifier] }];

    [self assert:[CPToolbarSeparatorItemIdentifier, CPToolbarSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar)];
}

/*
    A saved configuration can hold an identifier that the application no longer gives. The
    toolbar leaves it out instead of raising.
*/
- (void)testAnIdentifierWithoutAnItemIsLeftOutOfAConfiguration
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestUnknownIdentifier"];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar setConfigurationFromDictionary:@{ @"TB Item Identifiers": [@"CPToolbarTestNoSuchItem", CPToolbarSpaceItemIdentifier] }];

    [self assert:[CPToolbarSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar)];
}

- (void)testAnAutosavingToolbarSavesAChangeAndANewToolbarTakesIt
{
    var identifier = @"CPToolbarTestAutosave",
        defaultsKey = @"CPToolbar Configuration " + identifier,
        toolbar = [[CPToolbar alloc] initWithIdentifier:identifier];

    [[CPUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar removeItemAtIndex:0];

    var saved = [[CPUserDefaults standardUserDefaults] objectForKey:defaultsKey];

    [self assert:[CPToolbarFlexibleSpaceItemIdentifier] equals:[saved objectForKey:@"TB Item Identifiers"] message:@"the saved configuration"];

    var laterToolbar = [[CPToolbar alloc] initWithIdentifier:identifier + @"Later"];

    [[CPUserDefaults standardUserDefaults] setObject:saved forKey:defaultsKey + @"Later"];
    [laterToolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [laterToolbar setAutosavesConfiguration:YES];

    [self assert:[CPToolbarFlexibleSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(laterToolbar) message:@"the toolbar that takes it"];

    [[CPUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
    [[CPUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey + @"Later"];
}

- (void)testAToolbarWithTheSameIdentifierFollowsAChange
{
    var first = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestShared"],
        second = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestShared"];

    [first setDelegate:[_ToolbarTestRecordingDelegate new]];
    [second setDelegate:[_ToolbarTestRecordingDelegate new]];

    [first insertItemWithItemIdentifier:CPToolbarSeparatorItemIdentifier atIndex:2];
    [first setDisplayMode:CPToolbarDisplayModeLabelOnly];

    [self assert:ToolbarTestIdentifiersOf(first) equals:ToolbarTestIdentifiersOf(second) message:@"the items"];
    [self assert:CPToolbarDisplayModeLabelOnly equals:[second displayMode] message:@"the display mode"];
}

// MARK: Customization palette

- (void)testADropGoesBeforeTheFirstItemWhoseCentreIsAtOrRightOfIt
{
    var centres = [20.0, 60.0, 100.0];

    [self assert:0 equals:_CPToolbarInsertionIndex(centres, 5.0) message:@"left of every item"];
    [self assert:1 equals:_CPToolbarInsertionIndex(centres, 40.0) message:@"between the first two"];
    [self assert:3 equals:_CPToolbarInsertionIndex(centres, 120.0) message:@"right of every item"];
    [self assert:1 equals:_CPToolbarInsertionIndex([20.0, Infinity], 400.0) message:@"a hidden item counts as beyond the edge"];
}

- (void)testThePaletteOffersTheAllowedItemsAndTheDefaultSet
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestPalette"],
        delegate = [_ToolbarTestRecordingDelegate new];

    [delegate setItemIdentifiers:[CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier]];
    [toolbar setDelegate:delegate];

    var palette = [[_CPToolbarCustomizationPalette alloc] initWithToolbar:toolbar];

    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier] equals:[[palette itemViews] valueForKey:@"itemIdentifier"] message:@"the allowed items"];
    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier] equals:[[palette defaultSetView] defaultSet] message:@"the default set"];
}

- (void)testThePaletteRunsOnlyWhenTheToolbarAllowsCustomization
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestNoCustomization"];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar runCustomizationPalette:nil];

    [self assertFalse:[toolbar customizationPaletteIsRunning]];
}

- (void)testTheWindowEnablesCustomizationOnlyWhenTheToolbarAllowsIt
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestWindowValidation"],
        menuItem = [[CPMenuItem alloc] initWithTitle:@"Customize Toolbar…" action:@selector(runToolbarCustomizationPalette:) keyEquivalent:@""];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [window setToolbar:toolbar];

    [self assertFalse:[window validateUserInterfaceItem:menuItem] message:@"customization off"];

    [toolbar setAllowsUserCustomization:YES];

    [self assertTrue:[window validateUserInterfaceItem:menuItem] message:@"customization on"];
}

- (void)testDroppingTheDefaultSetRestoresTheDefaultItems
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestDefaultSetDrop"],
        pasteboard = [CPPasteboard pasteboardWithName:@"CPToolbarTestDefaultSetDrop"],
        info = [_ToolbarTestDraggingInfo new];

    [toolbar setDelegate:[_ToolbarTestRecordingDelegate new]];
    [toolbar removeItemAtIndex:0];

    var overlay = [[_CPToolbarCustomizationOverlay alloc] initWithToolbar:toolbar frame:CGRectMake(0.0, 0.0, 400.0, 50.0)];

    [pasteboard declareTypes:[_CPToolbarDefaultSetPboardType] owner:nil];
    [pasteboard setPropertyList:[toolbar _defaultItemIdentifiers] forType:_CPToolbarDefaultSetPboardType];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:CGPointMake(10.0, 10.0)];

    [self assertTrue:[overlay performDragOperation:info]];
    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar)];
}

/*
    An item that its validator disables while a sheet is attached is enabled again when the
    sheet ends: the toolbar validates its items on CPWindowDidEndSheetNotification, and the
    window has no attached sheet by then.
*/
- (void)testTheToolbarValidatesItsItemsWhenASheetEnds
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 800.0, 300.0) styleMask:CPTitledWindowMask],
        sheet = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:CPDocModalWindowMask],
        toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestSheetValidation"],
        delegate = [_ToolbarTestSheetValidator new];

    [delegate setWindow:window];
    [toolbar setDelegate:delegate];
    [window setToolbar:toolbar];

    var item = [toolbar items][0];

    [self assertTrue:[[toolbar visibleItems] containsObject:item] message:@"the item is visible"];

    [sheet._windowView _enableSheet:YES inWindow:window];
    window._sheetContext = {
        "sheet": sheet,
        "modalDelegate": nil,
        "endSelector": nil,
        "contextInfo": nil,
        "returnCode": -1,
        "opened": NO,
        "isAttached": NO,
        "isClosing": YES,
        "savedConstrains": sheet._constrainsToUsableScreen
    };

    [toolbar validateVisibleItems];
    [self assertFalse:[item isEnabled] message:@"disabled while the sheet is attached"];

    [window _cleanupSheetWindow];
    [self assertTrue:[item isEnabled] message:@"enabled when the sheet ends"];
}

/*
    A drop from the palette of an item that is already in the toolbar moves that item; only the
    space items can appear more than once.
*/
- (void)testDroppingAPresentItemMovesItAndOnlySpacesRepeat
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestPresentItemDrop"],
        delegate = [_ToolbarTestRecordingDelegate new],
        pasteboard = [CPPasteboard pasteboardWithName:@"CPToolbarTestPresentItemDrop"],
        info = [_ToolbarTestDraggingInfo new];

    [delegate setItemIdentifiers:[CPToolbarSpaceItemIdentifier, CPToolbarPrintItemIdentifier]];
    [toolbar setDelegate:delegate];

    var overlay = [[_CPToolbarCustomizationOverlay alloc] initWithToolbar:toolbar frame:CGRectMake(0.0, 0.0, 400.0, 50.0)];

    [pasteboard declareTypes:[_CPToolbarItemIdentifierPboardType] owner:nil];
    [pasteboard setString:CPToolbarPrintItemIdentifier forType:_CPToolbarItemIdentifierPboardType];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:CGPointMake(0.0, 10.0)];

    [self assertTrue:[overlay performDragOperation:info]];
    [self assert:[CPToolbarPrintItemIdentifier, CPToolbarSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar) message:@"a present item moves"];

    [pasteboard setString:CPToolbarSpaceItemIdentifier forType:_CPToolbarItemIdentifierPboardType];

    [self assertTrue:[overlay performDragOperation:info]];
    [self assert:[CPToolbarSpaceItemIdentifier, CPToolbarPrintItemIdentifier, CPToolbarSpaceItemIdentifier] equals:ToolbarTestIdentifiersOf(toolbar) message:@"a space repeats"];
}

/*
    In the small size mode an image item takes AppKit's small toolbar image, 24 points against
    32; in the regular size mode it keeps its size.
*/
- (void)testSmallSizeScalesAnImageItemToTheSmallImageSize
{
    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"CPToolbarTestSmallSize"],
        delegate = [_ToolbarTestRecordingDelegate new];

    [delegate setItemIdentifiers:[CPToolbarPrintItemIdentifier]];
    [toolbar setDelegate:delegate];
    [toolbar _toolbarView];

    var itemView = [[toolbar _toolbarView] viewForItem:[toolbar items][0]];

    [self assertTrue:CGSizeEqualToSize(CGSizeMake(32.0, 32.0), [itemView _sizeForSizeMode:CGSizeMake(32.0, 32.0)]) message:@"regular"];

    [toolbar setSizeMode:CPToolbarSizeModeSmall];
    itemView = [[toolbar _toolbarView] viewForItem:[toolbar items][0]];

    [self assertTrue:CGSizeEqualToSize(CGSizeMake(24.0, 24.0), [itemView _sizeForSizeMode:CGSizeMake(32.0, 32.0)]) message:@"small"];
}

@end
