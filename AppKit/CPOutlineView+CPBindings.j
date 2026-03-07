/*
 * CPOutlineView+CPBindings.j
 * AppKit
 *
 * Adds Cocoa Bindings support to CPOutlineView.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPIndexPath.j>
@import "CPKeyValueBinding.j"
@import "CPTreeNode.j"

@class CPOutlineView;

@implementation CPOutlineView (CPBindings)

+ (void)initialize
{
    if (self !== [CPOutlineView class])
        return;

    [self exposeBinding:@"content"];
    [self exposeBinding:@"selectionIndexPaths"];
    [self exposeBinding:@"sortDescriptors"];
}

/*!
    Returns the currently selected index paths. 
    This allows the outline view to be KVC-compliant for `selectionIndexPaths`.
*/
- (CPArray)selectionIndexPaths
{
    var indexes = [self selectedRowIndexes],
        paths = [CPMutableArray array],
        index = [indexes firstIndex];
        
    while (index !== CPNotFound)
    {
        var item = [self itemAtRow:index];
        
        // Check if the item is a CPTreeNode proxy (which it will be when bound to CPTreeController)
        if ([item respondsToSelector:@selector(indexPath)])
            [paths addObject:[item indexPath]];
            
        index = [indexes indexGreaterThanIndex:index];
    }
    
    return paths;
}

@end


@implementation CPOutlineView (CPBinder)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === @"content")
        return [_CPOutlineViewContentBinder class];
        
    if (aBinding === @"selectionIndexPaths")
        return [_CPOutlineViewSelectionIndexPathsBinder class];
        
    return [super _binderClassForBinding:aBinding];
}

@end


// --- Content Binder ---

/*!
    _CPOutlineViewContentBinder acts as the CPOutlineViewDataSource when the outline view 
    is bound to a CPTreeController's arrangedObjects.
*/
@implementation _CPOutlineViewContentBinder : CPBinder
{
    CPTreeNode _rootNode;
}

- (void)bind
{
    [super bind];
    [_source setDataSource:self];
}

- (void)unbind
{
    if ([_source dataSource] === self)
        [_source setDataSource:nil];
        
    [super unbind];
}

- (void)updateSource
{
    var value = [self valueForBinding:CPObservedKeyPathKey];
    
    if (!value || ![value isKindOfClass:[CPTreeNode class]])
        _rootNode = [[CPTreeNode alloc] initWithRepresentedObject:nil];
    else
        _rootNode = value;
        
    [_source reloadData];
}

- (CPTreeNode)rootNode
{
    return _rootNode;
}

// -- CPOutlineViewDataSource implementation --

- (id)outlineView:(CPOutlineView)outlineView child:(CPInteger)index ofItem:(id)item
{
    var node = item || _rootNode;
    return [[node childNodes] objectAtIndex:index];
}

- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item
{
    var node = item || _rootNode;
    return ![node isLeaf];
}

- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item
{
    var node = item || _rootNode;
    return [[node childNodes] count];
}

- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    // Normally column values are resolved via the table column's own bindings, 
    // but we return the represented object here as a standard fallback for cell-based tables.
    if ([item respondsToSelector:@selector(representedObject)])
        return [item representedObject];
        
    return item;
}

@end


// --- Selection Index Paths Binder ---

/*!
    _CPOutlineViewSelectionIndexPathsBinder listens for selection changes on the CPOutlineView 
    and translates the selected rows into CPIndexPaths to push to the CPTreeController.
    It also intercepts changes from the CPTreeController and auto-expands the tree to highlight them.
*/
@implementation _CPOutlineViewSelectionIndexPathsBinder : CPBinder

- (void)bind
{
    [super bind];
    
    // Observe selection changes originating from the user clicking the outline view
    [[CPNotificationCenter defaultCenter] 
        addObserver:self 
           selector:@selector(outlineViewSelectionDidChange:) 
               name:CPOutlineViewSelectionDidChangeNotification 
             object:_source];
}

- (void)unbind
{
    [[CPNotificationCenter defaultCenter] 
        removeObserver:self 
                  name:CPOutlineViewSelectionDidChangeNotification 
                object:_source];
                
    [super unbind];
}

- (void)updateSource
{
    var indexPaths = [self valueForBinding:CPObservedKeyPathKey] || [],
        indexes = [CPMutableIndexSet indexSet],
        contentBinder = [CPBinder getBinding:@"content" forObject:_source];
        
    var rootNode = [contentBinder respondsToSelector:@selector(rootNode)] ? [contentBinder rootNode] : nil;
    
    if (rootNode)
    {
        for (var i = 0, count = [indexPaths count]; i < count; i++)
        {
            var item = [rootNode descendantNodeAtIndexPath:[indexPaths objectAtIndex:i]];
            if (item)
            {
                // Auto-expand all parents so the selection becomes visible
                var parentsToExpand = [CPMutableArray array],
                    parent = [item parentNode];
                    
                while (parent && parent !== rootNode)
                {
                    [parentsToExpand insertObject:parent atIndex:0]; // Top-down
                    parent = [parent parentNode];
                }
                
                for (var j = 0; j < [parentsToExpand count]; j++)
                    [_source expandItem:parentsToExpand[j]];
                
                var row = [_source rowForItem:item];
                if (row !== CPNotFound && row >= 0)
                    [indexes addIndex:row];
            }
        }
    }
    
    // Suppress KVO while we programmatically adjust the CPOutlineView selection[self suppressSpecificNotificationFromObject:_source keyPath:@"selectionIndexPaths"];
    [_source selectRowIndexes:indexes byExtendingSelection:NO];
    [self unsuppressSpecificNotificationFromObject:_source keyPath:@"selectionIndexPaths"];
}

- (void)outlineViewSelectionDidChange:(CPNotification)note
{
    // We only want to push the change back if we aren't currently syncing down from the model
    if ([self isSpecificNotificationSuppressedFromObject:_source keyPath:@"selectionIndexPaths"])
        return;
        
    var paths = [_source selectionIndexPaths];
    
    // Reverse-set the value to push it up to the CPTreeController's selectionIndexPaths[self reverseSetValueFor:CPObservedKeyPathKey value:paths];
}

@end
