/*
 * AppController.j
 * outlineview
 *
 * Created by You on January 22, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPOutlineView.j>

CPLogRegister(CPLogConsole);

CustomOutlineViewDragType = @"CustomOutlineViewDragType";


var rowHeights = [ ];

@implementation Menu : CPObject
{
    Menu            _menu @accessors(property=menu);

    CPString        _title @accessors(property=title);
    CPArray         _children @accessors(property=children);
}

+ (id)menuWithTitle:(CPString)theTitle
{
    return [[self alloc] initWithTitle:theTitle];
}

+ (id)menuWithTitle:(CPString)theTitle children:(CPArray)theChildren
{
    return [[self alloc] initWithTitle:theTitle children:theChildren];
}

- (id)initWithTitle:(CPString)theTitle
{
    return [self initWithTitle:theTitle children:nil];
}

- (id)initWithTitle:(CPString)theTitle children:(CPArray)theChildren
{
    if ((self = [super init]))
    {
        _title = theTitle;
        [self setChildren:theChildren];
    }

    return self;
}

- (CPString)description
{
    return [self title];
}

- (void)insertSubmenu:(Menu)theItem atIndex:(int)theIndex
{
    // CPLog.debug(@"insert menu: %@ in menu: %@ at index: %i", theItem, self, theIndex);

    if ([[self children] containsObject:theItem])
        return;

    if ([theItem menu])
        [theItem removeFromMenu];

    [theItem setMenu:self];

    if (theIndex === -1)
        [[self children] addObject:theItem];
    else
        [[self children] insertObject:theItem atIndex:theIndex];

    // CPLog.debug(@"%@ children: %@", self, [self children]);
}

- (void)removeFromMenu
{
    // CPLog.debug(@"remove menu: %@ from menu: %@", self, [self menu]);

    [[[self menu] children] removeObject:self];

    CPLog.debug([[self menu] children]);

    [self setMenu:nil];
}

- (void)setChildren:(CPArray)theChildren
{
    if (theChildren === nil)
        theChildren = [];

    if (_children === theChildren)
        return;

    var childIndex = [theChildren count];
    while (childIndex--)
    {
        var child = theChildren[childIndex];
        [child setMenu:self];
    }

    _children = theChildren;
}

- (id)initWithCoder:(CPCoder)theCoder
{
    if (self = [super init])
    {
        _menu = [theCoder decodeObjectForKey:@"MenuSuperMenuKey"];
        _title = [theCoder decodeObjectForKey:@"MenuTitleKey"];
        [self setChildren:[theCoder decodeObjectForKey:@"MenuChildrenKey"]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_menu forKey:@"MenuSuperMenuKey"];
    [aCoder encodeObject:_title forKey:@"MenuTitleKey"];
    [aCoder encodeObject:_children forKey:@"MenuChildrenKey"];
}

@end

@implementation AppController : CPObject
{
    Menu            _menu @accessors(property=menu);
    CPOutlineView   _outlineView;

    CPArray         _draggedItems;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    _menu = [Menu menuWithTitle:@"Top" children:[
        [Menu menuWithTitle:@"1" children:[
            [Menu menuWithTitle:@"1.1" children:[
                [Menu menuWithTitle:@"1.1.1"],
                [Menu menuWithTitle:@"1.1.2"],
            ]],
            [Menu menuWithTitle:@"1.2" children:[
                [Menu menuWithTitle:@"1.2.1" children:[
                    [Menu menuWithTitle:@"1.2.1.1"],
                    [Menu menuWithTitle:@"1.2.1.2"],
                    [Menu menuWithTitle:@"1.2.1.3"],
                ]],
                [Menu menuWithTitle:@"1.2.2"],
                [Menu menuWithTitle:@"1.2.3"]
            ]]
        ]],
         [Menu menuWithTitle:@"2" children:nil],
         [Menu menuWithTitle:@"3" children:[
          [Menu menuWithTitle:@"3.1" children:[
              [Menu menuWithTitle:@"3.1.1"],
              [Menu menuWithTitle:@"3.1.2"],
              [Menu menuWithTitle:@"3.1.3"],
          ]],
          [Menu menuWithTitle:@"3.2" children:[
              [Menu menuWithTitle:@"3.2.1"],
              [Menu menuWithTitle:@"3.2.2"],
              [Menu menuWithTitle:@"3.2.3"],
              [Menu menuWithTitle:@"3.2.4"],
          ]],
          [Menu menuWithTitle:@"3.3" children:[
              [Menu menuWithTitle:@"3.3.1"],
              [Menu menuWithTitle:@"3.3.2"],
              [Menu menuWithTitle:@"3.3.3"],
              [Menu menuWithTitle:@"3.3.4"],
              [Menu menuWithTitle:@"3.3.5"],
          ]]
         ]]
    ]];

    var scrollView = [[CPScrollView alloc] initWithFrame:[contentView bounds]];

    _outlineView = [[CPOutlineView alloc] initWithFrame:[contentView bounds]];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"One"];
    [_outlineView addTableColumn:column];
    //[_outlineView setOutlineTableColumn:column];
    setTimeout(function(){
    [column setWidth:200];
    },0);

    [_outlineView addTableColumn:[[CPTableColumn alloc] initWithIdentifier:@"Two"]];
    [_outlineView addTableColumn:[[CPTableColumn alloc] initWithIdentifier:@"Three"]];

    [_outlineView registerForDraggedTypes:[CustomOutlineViewDragType]];

    [_outlineView setDataSource:self];
    [_outlineView setDelegate:self];
    [_outlineView setAllowsMultipleSelection:YES];
    [_outlineView expandItem:nil expandChildren:YES];
    // [_outlineView setRowHeight:50.0];
    // [_outlineView setIntercellSpacing:CGSizeMake(0.0, 10.0)]

    [scrollView setDocumentView:_outlineView];
    [theWindow setContentView:scrollView];

    // [theWindow setContentView:_outlineView];

    [theWindow orderFront:self];

    [column setWidth:CGRectGetWidth([_outlineView bounds])];
}

- (id)outlineView:(CPOutlineView)theOutlineView child:(int)theIndex ofItem:(id)theItem
{
    if (theItem === nil)
        theItem = [self menu];

    // CPLog.debug(@"child: %i ofItem:%@ : %@", theIndex, theItem, [[theItem children] objectAtIndex:theIndex]);

    return [[theItem children] objectAtIndex:theIndex];
}

- (BOOL)outlineView:(CPOutlineView)theOutlineView isItemExpandable:(id)theItem
{
    if (theItem === nil)
        theItem = [self menu];

    // CPLog.debug(@"isItemExpandable:%@ : %@", theItem, [[theItem children] count] > 0);

    return [[theItem children] count] > 0;
}

- (int)outlineView:(CPOutlineView)theOutlineView numberOfChildrenOfItem:(id)theItem
{
    if (theItem === nil)
        theItem = [self menu];

    // CPLog.debug(@"numberOfChildrenOfItem:%@ : %i", theItem, [[theItem children] count]);

    return [[theItem children] count];
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)theColumn byItem:(id)theItem
{
    // if ([theColumn identifier] === @"Two")
    //  return @"Two";

    if (theItem === nil)
        theItem = [self menu];

    // CPLog.debug(@"objectValueForTableColumn:%@ byItem:%@ : %@", theColumn, theItem, [theItem title]);

    return [theItem title];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteBoard)thePasteBoard
{
    _draggedItems = theItems;
    [thePasteBoard declareTypes:[CustomOutlineViewDragType] owner:self];
    [thePasteBoard setData:[CPKeyedArchiver archivedDataWithRootObject:theItems] forType:CustomOutlineViewDragType];

    return YES;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id /*< CPDraggingInfo >*/)theInfo proposedItem:(id)theItem proposedChildIndex:(int)theIndex
{
    CPLog.debug(@"validate item: %@ at index: %i", theItem, theIndex);

    if (theItem === nil)
        [anOutlineView setDropItem:nil dropChildIndex:theIndex];

    [anOutlineView setDropItem:theItem dropChildIndex:theIndex];

    return CPDragOperationEvery;
}

- (BOOL)outlineView:(CPOutlineView)outlineView acceptDrop:(id /*< CPDraggingInfo >*/)theInfo item:(id)theItem childIndex:(int)theIndex
{
    if (theItem === nil)
        theItem = [self menu];

    // CPLog.debug(@"drop item: %@ at index: %i", theItem, theIndex);

    var menuIndex = [_draggedItems count];

    while (menuIndex--)
    {
        var menu = [_draggedItems objectAtIndex:menuIndex];

        // CPLog.debug(@"move item: %@ to: %@ index: %@", menu, theItem, theIndex);

        if (menu === theItem)
            continue;

        [menu removeFromMenu];
        [theItem insertSubmenu:menu atIndex:theIndex];
        theIndex += 1;
    }

    return YES;
}

- (int)outlineView:(CPOutlineView)outlineView heightOfRowByItem:(id)anItem
{
    if (!anItem.customHeight)
        anItem.customHeight = 20 + RAND() * 190;

    return anItem.customHeight;
}

@end
