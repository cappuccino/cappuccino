/*
 * AppController.j
 * CPCollectionViewNibTest
 *
 * Created by You on November 28, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
//@import "CPCollectionView.j"

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet     CPCollectionView     collectionView;
    @outlet     CPCollectionView     emptyCollectionView;
    @outlet     InternalProtoypeItem prototypeItemInternal;
    @outlet     ExternalProtoypeItem prototypeItemExternal;
    @outlet     CPTableView          tableView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [self willChangeValueForKey:@"minItemWidth"];
    [self willChangeValueForKey:@"minItemHeight"];
    [collectionView setMinItemSize:CGSizeMake(100, 100)];
    [self didChangeValueForKey:@"minItemWidth"];
    [self didChangeValueForKey:@"minItemHeight"];

    [self willChangeValueForKey:@"maxItemWidth"];
    [self willChangeValueForKey:@"maxItemHeight"];
    [collectionView setMaxItemSize:CGSizeMake(200, 150)];
    [self didChangeValueForKey:@"maxItemWidth"];
    [self didChangeValueForKey:@"maxItemHeight"];

    [collectionView registerForDraggedTypes:[@"DragType"]];
    [emptyCollectionView registerForDraggedTypes:[@"DragType"]];
    //[theWindow setFullPlatformWindow:YES];
}

- (IBAction)setPrototypeItem:(id)sender
{
    var prototypeItem = [[sender selectedItem] tag] ? prototypeItemExternal : prototypeItemInternal;

    [collectionView setItemPrototype:prototypeItem];
}

- (void)setMinItemWidth:(CPInteger)aWidth
{
    var size = CGSizeMakeCopy([collectionView minItemSize]);
    size.width = aWidth;
    [collectionView setMinItemSize:size];
}

- (CPInteger)minItemWidth
{
    return [collectionView minItemSize].width;
}

- (void)setMinItemHeight:(CPInteger)aHeight
{
    var size = CGSizeMakeCopy([collectionView minItemSize]);
    size.height = aHeight;
    [collectionView setMinItemSize:size];
}

- (CPInteger)minItemHeight
{
    return [collectionView minItemSize].height;
}

- (void)setMaxItemWidth:(CPInteger)aWidth
{
    var size = CGSizeMakeCopy([collectionView maxItemSize]);
    size.width = aWidth;
    [collectionView setMaxItemSize:size];
}

- (CPInteger)maxItemWidth
{
    return [collectionView maxItemSize].width;
}

- (void)setMaxItemHeight:(CPInteger)aHeight
{
    var size = CGSizeMakeCopy([collectionView maxItemSize]);
    size.height = aHeight;
    [collectionView setMaxItemSize:size];
}

- (CPInteger)maxItemHeight
{
    return [collectionView maxItemSize].height;
}

/*
    DELEGATE METHODS
*/

- (CPData)collectionView:(CPCollectionView)aCollectionView dataForItemsAtIndexes:(CPIndexSet)indices forType:(CPString)aType
{
    return indices;
}

- (CPView)collectionView:(CPCollectionView)aCollectionView draggingViewForItemsAtIndexes:(CPIndexSet)indexes withEvent:(CPEvent)event offset:(CGPoint)dragImageOffset
{
    return [aCollectionView draggingViewForItemsAtIndexes:indexes withEvent:event offset:dragImageOffset];
}

- (CPArray)collectionView:(CPCollectionView)aCollectionView dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
    return [@"DragType"];
}

- (BOOL)collectionView:(CPCollectionView)aCollectionView canDragItemsAtIndexes:(CPIndexSet)indexes withEvent:(CPEvent)anEvent
{
    return YES;
}
/*
- (BOOL)collectionView:(CPCollectionView)aCollectionView writeItemsAtIndexes:(CPIndexSet)indexes toPasteboard:(CPPasteboard)pboard
{
    return YES;
}
*/
- (CPDragOperation)collectionView:(CPCollectionView)aCollectionView validateDrop:(id)draggingInfo proposedIndex:(Function)proposedIndexRef dropOperation:(CPInteger)collectionViewDropOperation
{
    var pboard = [draggingInfo draggingPasteboard],
        draggingSource = [draggingInfo draggingSource],
        dragIndex = [[pboard dataForType:@"DragType"] firstIndex],
        proposedIndex = proposedIndexRef();

    if (aCollectionView !== draggingSource)
    {
        [[CPCursor dragCopyCursor] set];
        return CPDragOperationCopy;
    }
    else if (proposedIndex == dragIndex || proposedIndex == dragIndex + 1)
        return CPDragOperationNone;

    return CPDragOperationMove;
}

- (BOOL)collectionView:(CPCollectionView)aCollectionView acceptDrop:(id)draggingInfo index:(CPInteger)proposedIndex dropOperation:(CPInteger)collectionViewDropOperation
{
    var pboard = [draggingInfo draggingPasteboard],
        dragIndexes = [pboard dataForType:@"DragType"],
        draggingSource = [draggingInfo draggingSource];

    if (aCollectionView == draggingSource)
        [[aCollectionView content] moveIndexes:dragIndexes toIndex:proposedIndex];
    else
    {
        var sourceObjects = [[draggingSource content] objectsAtIndexes:dragIndexes]; // copy ?
        [[aCollectionView content] insertObjects:sourceObjects atIndexes:[CPIndexSet indexSetWithIndex:proposedIndex]];
    }

    [aCollectionView reloadContent];
    [tableView reloadData];

    [CPCursor pop];

    return YES;
}

@end

@implementation InternalProtoypeItem: CPCollectionViewItem
{
    @outlet CPTextField textField;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    textField = [aCoder decodeObjectForKey:@"TextField"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:textField forKey:@"TextField"];
}

- (void)setRepresentedObject:(id)anObject
{
    [super setRepresentedObject:anObject];
    [textField setStringValue:[anObject objectForKey:@"value"]];
    [[self view] setColor:[anObject objectForKey:@"color"]];
}

@end

@implementation ExternalProtoypeItem: CPCollectionViewItem
{
}

- (void)setRepresentedObject:(id)anObject
{
    [super setRepresentedObject:anObject];
    [[self view] setColor:[anObject objectForKey:@"color"]];
}

@end


var keyCode = 0;
@implementation ArrayController : CPArrayController
{
}

- (void)newObject
{
    return [CPDictionary dictionaryWithObjectsAndKeys:(String.fromCharCode(65 + keyCode++)), @"value", [CPColor randomColor], @"color"];
}

@end

@implementation ColorView : CPView
{
    CPColor color @accessors;
}

- (void)setColor:(CPColor)aColor
{
    color = aColor;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    if (!color)
        color = [CPColor grayColor];

    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(context, color);
    CGContextFillRect(context, aRect);
}

@end

@implementation CPArray (MoveIndexes)

- (void)moveIndexes:(CPIndexSet)indexes toIndex:(int)insertIndex
{
    var aboveCount = 0,
        object,
        removeIndex;

    var index = [indexes lastIndex];

    while (index != CPNotFound)
    {
        if (index >= insertIndex)
        {
            removeIndex = index + aboveCount;
            aboveCount ++;
        }
        else
        {
            removeIndex = index;
            insertIndex --;
        }

        object = [self objectAtIndex:removeIndex];
        [self removeObjectAtIndex:removeIndex];
        [self insertObject:object atIndex:insertIndex];

        index = [indexes indexLessThanIndex:index];
    }
}

@end
