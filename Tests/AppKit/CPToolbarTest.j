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

@end
