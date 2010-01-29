/*
 * AppController.j
 * outlineview
 *
 * Created by You on January 22, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "AppKit/CPOutlineView.j"

CPLogRegister(CPLogConsole);

@implementation Menu : CPObject
{
	CPString		_title @accessors(property=title);
	CPArray			_children @accessors(property=children);
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
		_children = theChildren;
	}
	
	return self;
}

- (CPString)description
{
	var description = [super description] + @" " + [self title];
	
	// if ([[self children] count] > 0)
	// 	description = @"\n" + [description stringByAppendingFormat:@": %@", [self children]];

	return description;
}

- (id)initWithCoder:(CPCoder)theCoder
{
	if (self = [super init])
	{
		_title = [theCoder decodeObjectForKey:@"MenuTitleKey"];
		_children = [theCoder decodeObjectForKey:@"MenuChildrenKey"];
	}
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
	[aCoder encodeObject:_title forKey:@"MenuTitleKey"];
	[aCoder encodeObject:_children forKey:@"MenuChildrenKey"];
}

@end

@implementation AppController : CPObject
{
	Menu			_menu @accessors(property=menu);
	CPOutlineView	_outlineView;
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
				[Menu menuWithTitle:@"1.2.1"],
				[Menu menuWithTitle:@"1.2.2"],
				[Menu menuWithTitle:@"1.2.3"]
			]]
		]],
		[Menu menuWithTitle:@"2" children:[
			[Menu menuWithTitle:@"2.1" children:[
				[Menu menuWithTitle:@"2.1.1"],
				[Menu menuWithTitle:@"2.1.2"],
				[Menu menuWithTitle:@"2.1.3"],
			]],
			[Menu menuWithTitle:@"2.2" children:[
				[Menu menuWithTitle:@"2.2.1"],
				[Menu menuWithTitle:@"2.2.2"],
			]]
		]],
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
	[theWindow setContentView:scrollView];
	
	_outlineView = [[CPOutlineView alloc] initWithFrame:[contentView bounds]];
	
	var column = [[CPTableColumn alloc] initWithIdentifier:@""];
	[_outlineView addTableColumn:column];
	[_outlineView setOutlineTableColumn:column];
	[_outlineView registerForDraggedTypes:[@"CustomType"]];
	
	[_outlineView setDataSource:self];
	[_outlineView setAllowsMultipleSelection:YES];
	// [_outlineView setIntercellSpacing:CPSizeMake(0.0, 0.0)]
	
	[scrollView setDocumentView:_outlineView];

	[self expandItem:[self menu]];

    [theWindow orderFront:self];
}

- (void)expandItem:(Menu)item
{
	var children = [item children],
		childIndex = [children count];
	
	while (childIndex--)	
		[self expandItem:[children objectAtIndex:childIndex]];
		
	[_outlineView expandItem:item];
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
	if (theItem === nil)
		theItem = [self menu];
		
	// CPLog.debug(@"objectValueForTableColumn:%@ byItem:%@ : %@", theColumn, theItem, [theItem title]);
	
	return [theItem title];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteBoard)thePasteBoard
{
	[thePasteBoard declareTypes:[@"CustomType"] owner:self];
	[thePasteBoard setData:[CPKeyedArchiver archivedDataWithRootObject:theItems] forType:@"CustomType"];
	return YES;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id < CPDraggingInfo >)theInfo proposedItem:(id)theItem proposedChildIndex:(int)theIndex
{
	CPLog.debug(@"validate drop at index: %i item: %@", theIndex, theItem);
	return CPDragOperationEvery;
}

- (BOOL)outlineView:(CPOutlineView)outlineView acceptDrop:(id < CPDraggingInfo >)theInfo item:(id)theItem childIndex:(int)theIndex
{
	CPLog.debug(@"accept drop at index: %i item: %@", theIndex, theItem);
	return YES;
}

@end
