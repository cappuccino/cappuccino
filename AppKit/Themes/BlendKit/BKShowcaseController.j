/*
 * BKShowcaseController.j
 * BlendKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <AppKit/CPCollectionView.j>
@import <AppKit/CPColorPanel.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPToolbar.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow_Constants.j>

@import "BKThemeDescriptor.j"

@class CPWindow

@global CPApp

var LEFT_PANEL_WIDTH    = 176.0;

var BKLearnMoreToolbarItemIdentifier                = @"BKLearnMoreToolbarItemIdentifier",
    BKStateToolbarItemIdentifier                    = @"BKStateToolbarItemIdentifier",
    BKBackgroundColorToolbarItemIdentifier          = @"BKBackgroundColorToolbarItemIdentifier";

@implementation BKShowcaseController : CPObject
{
    CPArray             _themeDescriptorClasses;

    CPCollectionView    _themesCollectionView;
    CPCollectionView    _themedObjectsCollectionView;

    CPWindow            theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    _themeDescriptorClasses = [BKThemeDescriptor allThemeDescriptorClasses];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"Toolbar"];

    [toolbar setDelegate:self];
    [theWindow setToolbar:toolbar];

    var contentView = [theWindow contentView],
        bounds = [contentView bounds],
        splitView = [[CPSplitView alloc] initWithFrame:bounds];

    [splitView setIsPaneSplitter:YES];
    [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:splitView];

    // Left Pane
    var label = [CPTextField labelWithTitle:@"THEMES"];

    [label setFont:[CPFont boldSystemFontOfSize:11.0]];
    [label setTextColor:[CPColor colorWithCalibratedRed:93.0 / 255.0 green:93.0 / 255.0 blue:93.0 / 255.0 alpha:1.0]];
    [label setTextShadowColor:[CPColor colorWithCalibratedRed:225.0 / 255.0 green:255.0 / 255.0 blue:255.0 / 255.0 alpha:0.7]];
    [label setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [label sizeToFit];
    [label setFrameOrigin:CGPointMake(5.0, 4.0)];

    var themeDescriptorItem = [[CPCollectionViewItem alloc] init];

    [themeDescriptorItem setView:[[BKThemeDescriptorCell alloc] init]];

    _themesCollectionView = [[CPCollectionView alloc] initWithFrame:CGRectMake(0.0, 0.0, LEFT_PANEL_WIDTH, CGRectGetHeight(bounds))];

    [_themesCollectionView setDelegate:self];
    [_themesCollectionView setItemPrototype:themeDescriptorItem];
    [_themesCollectionView setMinItemSize:CGSizeMake(20.0, 36.0)];
    [_themesCollectionView setMaxItemSize:CGSizeMake(10000000.0, 36.0)];
    [_themesCollectionView setMaxNumberOfColumns:1];
    [_themesCollectionView setContent:_themeDescriptorClasses];
    [_themesCollectionView setAutoresizingMask:CPViewWidthSizable];
    [_themesCollectionView setVerticalMargin:0.0];
    [_themesCollectionView setSelectable:YES];
    [_themesCollectionView setFrameOrigin:CGPointMake(0.0, 20.0)];
    [_themesCollectionView setAutoresizingMask:CPViewWidthSizable];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, LEFT_PANEL_WIDTH, CGRectGetHeight(bounds))],
        contentView = [scrollView contentView];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setDocumentView:_themesCollectionView];

    [contentView setBackgroundColor:[CPColor colorWithRed:212.0 / 255.0 green:221.0 / 255.0 blue:230.0 / 255.0 alpha:1.0]];
    [contentView addSubview:label];

    [splitView addSubview:scrollView];

    // Right Pane
    _themedObjectsCollectionView = [[CPCollectionView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds) - LEFT_PANEL_WIDTH - 1.0, 10.0)];

    var collectionViewItem = [[CPCollectionViewItem alloc] init];

    [collectionViewItem setView:[[BKShowcaseCell alloc] init]];

    [_themedObjectsCollectionView setItemPrototype:collectionViewItem];
    [_themedObjectsCollectionView setVerticalMargin:20.0];
    [_themedObjectsCollectionView setAutoresizingMask:CPViewWidthSizable];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(LEFT_PANEL_WIDTH + 1.0, 0.0, CGRectGetWidth(bounds) - LEFT_PANEL_WIDTH - 1.0, CGRectGetHeight(bounds))];

    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setDocumentView:_themedObjectsCollectionView];

    [splitView addSubview:scrollView];

    [_themesCollectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];

    // Needed when displaying _CPWindowView, to avoid the moving of the main window
    [theWindow setMovable:NO];

    [theWindow setFullPlatformWindow:YES];
    [theWindow makeKeyAndOrderFront:self];
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
    var themeDescriptorClass = _themeDescriptorClasses[[[aCollectionView selectionIndexes] firstIndex]],
        itemSize = [themeDescriptorClass itemSize];

    // Make room for label and apply a minimum size.
    itemSize.width = MAX(100.0, itemSize.width + 20.0);
    itemSize.height = MAX(100.0, itemSize.height + 30.0);

    [_themedObjectsCollectionView setMinItemSize:itemSize];
    [_themedObjectsCollectionView setMaxItemSize:itemSize];

    [_themedObjectsCollectionView setContent:[themeDescriptorClass themedShowcaseObjectTemplates]];
    [BKShowcaseCell setBackgroundColor:[themeDescriptorClass showcaseBackgroundColor]];
}

- (BOOL)hasLearnMoreURL
{
    return [[CPBundle mainBundle] objectForInfoDictionaryKey:@"BKLearnMoreURL"];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [BKLearnMoreToolbarItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, BKBackgroundColorToolbarItemIdentifier, BKStateToolbarItemIdentifier];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    var itemIdentifiers = [CPToolbarFlexibleSpaceItemIdentifier, BKBackgroundColorToolbarItemIdentifier, BKStateToolbarItemIdentifier];

    if ([self hasLearnMoreURL])
        itemIdentifiers = [BKLearnMoreToolbarItemIdentifier].concat(itemIdentifiers);

    return itemIdentifiers;
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];

    [toolbarItem setTarget:self];

    if (anItemIdentifier === BKStateToolbarItemIdentifier)
    {
        var popUpButton = [CPPopUpButton buttonWithTitle:@"Enabled"];

        [popUpButton addItemWithTitle:@"Disabled"];

        [toolbarItem setView:popUpButton];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(changeState:)];
        [toolbarItem setLabel:@"State"];

        var width = CGRectGetWidth([popUpButton frame]);

        [toolbarItem setMinSize:CGSizeMake(width + 20.0, 25.0)];
        [toolbarItem setMaxSize:CGSizeMake(width + 20.0, 25.0)];
    }

    else if (anItemIdentifier === BKBackgroundColorToolbarItemIdentifier)
    {
        var popUpButton = [CPPopUpButton buttonWithTitle:@"Window Background"];

        [popUpButton addItemWithTitle:@"Light Checkers"];
        [popUpButton addItemWithTitle:@"Dark Checkers"];
        [popUpButton addItemWithTitle:@"White"];
        [popUpButton addItemWithTitle:@"Black"];
        [popUpButton addItemWithTitle:@"More Choices..."];

        var itemArray = [popUpButton itemArray];

        [itemArray[0] setRepresentedObject:[BKThemeDescriptor windowBackgroundColor]];
        [itemArray[1] setRepresentedObject:[BKThemeDescriptor lightCheckersColor]];
        [itemArray[2] setRepresentedObject:[BKThemeDescriptor darkCheckersColor]];
        [itemArray[3] setRepresentedObject:[CPColor whiteColor]];
        [itemArray[4] setRepresentedObject:[CPColor blackColor]];

        [toolbarItem setView:popUpButton];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(changeColor:)];
        [toolbarItem setLabel:@"Background Color"];

        var width = CGRectGetWidth([popUpButton frame]);

        [toolbarItem setMinSize:CGSizeMake(width, 25.0)];
        [toolbarItem setMaxSize:CGSizeMake(width, 25.0)];
    }
    else if (anItemIdentifier === BKLearnMoreToolbarItemIdentifier)
    {
        var title = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"BKLearnMoreButtonTitle"];

        if (!title)
            title = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"] || @"Home Page";

        var button = [CPButton buttonWithTitle:title];

        [theWindow setDefaultButton:button];

        [toolbarItem setView:button];
        [toolbarItem setLabel:@"Learn More"];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(learnMore:)];

        var width = CGRectGetWidth([button frame]);

        [toolbarItem setMinSize:CGSizeMake(width, 25.0)];
        [toolbarItem setMaxSize:CGSizeMake(width, 25.0)];
    }

    return toolbarItem;
}

- (void)learnMore:(id)aSender
{
    window.location.href = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"BKLearnMoreURL"];
}

- (BKThemeDescriptor)selectedThemeDescriptor
{
    return _themeDescriptorClasses[[[_themesCollectionView selectionIndexes] firstIndex]];
}

- (void)changeState:(id)aSender
{
    var themedShowcaseObjectTemplates = [[self selectedThemeDescriptor] themedShowcaseObjectTemplates],
        count = [themedShowcaseObjectTemplates count];

    while (count--)
    {
        var themedObject = [themedShowcaseObjectTemplates[count] valueForKey:@"themedObject"];

        if ([themedObject respondsToSelector:@selector(setEnabled:)])
            [themedObject setEnabled:[aSender title] === @"Enabled" ? YES : NO];
    }
}

- (void)changeColor:(id)aSender
{
    var color = nil;

    if ([aSender isKindOfClass:[CPColorPanel class]])
        color = [aSender color];

    else
    {
        if ([aSender titleOfSelectedItem] === @"More Choices...")
        {
            [aSender addItemWithTitle:@"Other"];
            [aSender selectItemWithTitle:@"Other"];

            [CPApp orderFrontColorPanel:self];
        }
        else
        {
            color = [[aSender selectedItem] representedObject];

            [aSender removeItemWithTitle:@"Other"];
        }
    }

    if (color)
    {
        [[self selectedThemeDescriptor] setShowcaseBackgroundColor:color];
        [BKShowcaseCell setBackgroundColor:color];
    }
}

@end

var SelectionColor = nil;

@implementation BKThemeDescriptorCell : CPView
{
    CPTextField _label;
}

+ (CPImage)selectionColor
{
    if (!SelectionColor)
        SelectionColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[BKThemeDescriptorCell class]] pathForResource:@"selection.png"] size:CGSizeMake(1.0, 36.0)]];

    return SelectionColor;
}

- (void)setRepresentedObject:(id)aThemeDescriptor
{
    if (!_label)
    {
        _label = [CPTextField labelWithTitle:@"hello"];

        [_label setFont:[CPFont systemFontOfSize:11.0]];
        [_label setFrame:CGRectMake(10.0, 0.0, CGRectGetWidth([self bounds]) - 20.0, CGRectGetHeight([self bounds]))];

        [_label setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_label setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self addSubview:_label];
    }

    [_label setStringValue:[aThemeDescriptor themeName] + " (" + [[aThemeDescriptor themedShowcaseObjectTemplates] count] + ")"];
}

- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [[self class] selectionColor] : nil];

    [_label setTextShadowOffset:isSelected ? CGSizeMake(0.0, 1.0) : CGSizeMakeZero()];
    [_label setTextShadowColor:isSelected ? [CPColor blackColor] : nil];
    [_label setFont:isSelected ? [CPFont boldSystemFontOfSize:11.0] : [CPFont systemFontOfSize:11.0]];
    [_label setTextColor:isSelected ? [CPColor whiteColor] : [CPColor blackColor]];
}

@end


var ShowcaseCellBackgroundColor = nil,
    BKShowcaseCellBackgroundColorDidChangeNotification  = @"BKShowcaseCellBackgroundColorDidChangeNotification";

@implementation BKShowcaseCell : CPView
{
    CPView      _backgroundView;

    CPView      _view;
    CPTextField _label;
}

+ (void)setBackgroundColor:(CPColor)aColor
{
    if (ShowcaseCellBackgroundColor === aColor)
        return;

    ShowcaseCellBackgroundColor = aColor;

    [[CPNotificationCenter defaultCenter]
        postNotificationName:BKShowcaseCellBackgroundColorDidChangeNotification
                      object:nil];
}

+ (CPColor)backgroundColor
{
    return ShowcaseCellBackgroundColor;
}

- (id)init
{
    self = [super init];

    if (self)
        [[CPNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(showcaseBackgroundDidChange:)
                   name:BKShowcaseCellBackgroundColorDidChangeNotification
                 object:nil];

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [[CPNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(showcaseBackgroundDidChange:)
                   name:BKShowcaseCellBackgroundColorDidChangeNotification
                 object:nil];

    return self;
}

- (void)showcaseBackgroundDidChange:(CPNotification)aNotification
{
    [_backgroundView setBackgroundColor:[BKShowcaseCell backgroundColor]];
}

- (void)setSelected:(BOOL)isSelected
{
}

- (void)setRepresentedObject:(id)anObject
{
    if (!_label)
    {
        _label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_label setAlignment:CPCenterTextAlignment];
        [_label setAutoresizingMask:CPViewMinYMargin | CPViewWidthSizable];
        [_label setFont:[CPFont boldSystemFontOfSize:11.0]];

        [self addSubview:_label];
    }

    [_label setStringValue:[anObject valueForKey:@"label"]];
    [_label sizeToFit];

    [_label setFrame:CGRectMake(0.0, CGRectGetHeight([self bounds]) - CGRectGetHeight([_label frame]),
        CGRectGetWidth([self bounds]), CGRectGetHeight([_label frame]))];

    if (!_backgroundView)
    {
        _backgroundView = [[CPView alloc] init];

        [self addSubview:_backgroundView];
    }

    [_backgroundView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), CGRectGetMinY([_label frame]))];
    [_backgroundView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    if (_view)
        [_view removeFromSuperview];

    _view = [anObject valueForKey:@"themedObject"];

    [_view setTheme:nil];
    [_view setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [_view setFrameOrigin:CGPointMake((CGRectGetWidth([_backgroundView bounds]) - CGRectGetWidth([_view frame])) / 2.0,
        (CGRectGetHeight([_backgroundView bounds]) - CGRectGetHeight([_view frame])) / 2.0)];

    [_backgroundView addSubview:_view];
    [_backgroundView setBackgroundColor:[BKShowcaseCell backgroundColor]];
}

@end
