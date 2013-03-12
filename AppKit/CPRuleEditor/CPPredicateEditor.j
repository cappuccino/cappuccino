/*
 * CPPredicateEditor.j
 * AppKit
 *
 * Created by cacaodev.
 * Copyright 2011, cacaodev.
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

@import "CPRuleEditor.j"
@import "_CPPredicateEditorTree.j"
@import "_CPPredicateEditorRowNode.j"
@import "CPPredicateEditorRowTemplate.j"

@implementation CPPredicateEditor : CPRuleEditor
{
    CPArray _allTemplates;
    CPArray _rootTrees;
    CPArray _rootHeaderTrees;
    id      _predicateTarget @accessors(property=target);
    SEL     _predicateAction @accessors(property=action);
}

#pragma mark public methods
/*!
    @ingroup appkit
    @class CPPredicateEditor

    @brief CPPredicateEditor is a subclass of CPRuleEditor that is specialized for editing CPPredicate objects.

    CPPredicateEditor provides a CPPredicate property—objectValue (inherited from CPControl)—that you can get and set directly, and that you can bind using bindings (you typically configure a predicate editor in Interface Builder). CPPredicateEditor depends on another class, CPPredicateEditorRowTemplate, that describes the available predicates and how to display them.

    Unlike CPRuleEditor, CPPredicateEditor does not depend on its delegate to populate its rows (and does not call the populating delegate methods). Instead, its rows are populated from its objectValue property (an instance of CPPredicate). CPPredicateEditor relies on instances CPPredicateEditorRowTemplate, which are responsible for mapping back and forth between the displayed view values and various predicates.

    CPPredicateEditor exposes one property, rowTemplates, which is an array of CPPredicateEditorRowTemplate objects.
*/

/*!
    @brief Returns the row templates for the receiver.
    @return The row templates for the receiver.
    @discussion Until otherwise set, this contains a single compound CPPredicateEditorRowTemplate object.
    @see setRowTemplates:
*/
- (CPArray)rowTemplates
{
    return _allTemplates;
}

/*!
    @brief Sets the row templates for the receiver.
    @param rowTemplates An array of CPPredicateEditorRowTemplate objects.
    @see rowTemplates
*/
- (void)setRowTemplates:(id)rowTemplates
{
    if (_allTemplates == rowTemplates)
        return;

    _allTemplates = rowTemplates;

    [self _updateItemsByCompoundTemplates];
    [self _updateItemsBySimpleTemplates];

    if ([self numberOfRows] > 0)
    {
        var predicate = [super predicate];
        [self _reflectPredicate:predicate];
    }
}

/*! @cond */
+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return [CPPredicateEditorValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return @"predicate";

    return [super _replacementKeyPathForBinding:aBinding];
}

- (void)_initRuleEditorShared
{
    [super _initRuleEditorShared];

    _rootTrees = [CPArray array];
    _rootHeaderTrees = [CPArray array];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self != nil)
    {
        var initialTemplate = [[CPPredicateEditorRowTemplate alloc] initWithCompoundTypes:[CPAndPredicateType, CPOrPredicateType]];
        _allTemplates = [CPArray arrayWithObject:initialTemplate];
    }

    return self;
}

- (id)objectValue
{
    return [super predicate];
}

- (void)_updateItemsBySimpleTemplates
{
    var templates = [CPMutableArray array],
        count = [_allTemplates count],
        t;

    while (count--)
    {
        var t = _allTemplates[count];
        if ([t _rowType] == CPRuleEditorRowTypeSimple)
            [templates insertObject:t atIndex:0];
    }

    var trees = [self _constructTreesForTemplates:templates];
    if ([trees count] > 0)
        _rootTrees = [self _mergeTree:trees];
}

- (void)_updateItemsByCompoundTemplates
{
    var templates = [CPMutableArray array],
        count = [_allTemplates count],
        t;

    while (count--)
    {
        var t = _allTemplates[count];
        if ([t _rowType] == CPRuleEditorRowTypeCompound)
            [templates insertObject:t atIndex:0];
    }

    var trees = [self _constructTreesForTemplates:templates];
    if ([trees count] > 0)
        _rootHeaderTrees = [self _mergeTree:trees];
}

- (CPArray)_constructTreesForTemplates:(id)templates
{
    var trees = [CPMutableArray array],
        count = [templates count];

    for (var i = 0; i < count; i++)
    {
        var tree = [self _constructTreeForTemplate:templates[i]];
        [trees addObjectsFromArray:tree];
    }

    return trees;
}

- (CPMutableArray)_mergeTree:(CPArray)aTree
{
    var mergedTree = [CPMutableArray array];
    if (aTree == nil)
        return mergedTree;

    var icount = [aTree count];
    for (var i = 0; i < icount; i++)
    {
        var anode = [aTree objectAtIndex:i],
            jcount = [mergedTree count],
            merged = NO;

        for (var j = 0; j < jcount; j++)
        {
            var mergednode = [mergedTree objectAtIndex:j];

            if ([[mergednode title] isEqualToString:[anode title]])
            {
                var children1 = [mergednode children],
                    children2 = [anode children],
                    children12 = [children1 arrayByAddingObjectsFromArray:children2],
                    mergedChildren = [self _mergeTree:children12];

                [mergednode setChildren:mergedChildren];
                merged = YES;
            }
        }

        if (!merged)
            [mergedTree addObject:anode];
    }

    return mergedTree;
}

- (id)_constructTreeForTemplate:(CPPredicateEditorRowTemplate)aTemplate
{
    var tree = [CPArray array],
        templateViews = [aTemplate templateViews],
        count = [templateViews count];

    while (count--)
    {
        var children = [CPArray array],
            itemsCount = 0,
            menuIndex = -1,
            itemArray,

            templateView = [templateViews objectAtIndex:count],
            isPopup = [templateView isKindOfClass:[CPPopUpButton class]];

        if (isPopup)
        {
            itemArray = [[templateView itemArray] valueForKey:@"title"];
            itemsCount = [itemArray count];
            menuIndex = 0;
        }

        for (; menuIndex < itemsCount; menuIndex++)
        {
            var item = [_CPPredicateEditorTree new];
            [item setIndexIntoTemplate:count];
            [item setTemplate:aTemplate];
            [item setMenuItemIndex:menuIndex];
            if (isPopup)
                [item setTitle:[itemArray objectAtIndex:menuIndex]];

            [children addObject:item];
        }

        [children makeObjectsPerformSelector:@selector(setChildren:) withObject:tree];
        tree = children;
    }

    return tree;
}

#pragma mark Set the Predicate

- (void)setObjectValue:(id)objectValue
{
    var ov = [self objectValue];
    if ((ov == nil) != (objectValue == nil) || ![ov isEqual:objectValue])
    {
        [self _setPredicate:objectValue];
        [self _reflectPredicate:objectValue];
    }
}

- (void)_reflectPredicate:(id)predicate
{
    var animation = _currentAnimation;
    _currentAnimation = nil;
    _sendAction = NO;

    if (predicate != nil)
    {
        if ((_nestingMode == CPRuleEditorNestingModeSimple || _nestingMode == CPRuleEditorNestingModeCompound)
            && [predicate isKindOfClass:[CPComparisonPredicate class]])
            predicate = [[CPCompoundPredicate alloc] initWithType:[self _compoundPredicateTypeForRootRows] subpredicates:[CPArray arrayWithObject:predicate]];

        var row = [self _rowObjectFromPredicate:predicate];
        if (row != nil)
            [_boundArrayOwner setValue:[CPArray arrayWithObject:row] forKey:_boundArrayKeyPath];
    }

    [self setAnimation:animation];
}

- (id)_rowObjectFromPredicate:(CPPredicate)predicate
{
    var quality, // TODO: We should use this ref somewhere !
        type,
        matchedTemplate = [CPPredicateEditorRowTemplate _bestMatchForPredicate:predicate inTemplates:[self rowTemplates] quality:quality];

    if (matchedTemplate == nil)
        return nil;

    var copyTemplate = [matchedTemplate copy],
        subpredicates = [matchedTemplate displayableSubpredicatesOfPredicate:predicate];

    if (subpredicates == nil)
    {
        [copyTemplate _setComparisonPredicate:predicate];
        type = CPRuleEditorRowTypeSimple;
    }
    else
    {
        [copyTemplate _setCompoundPredicate:predicate];
        type = CPRuleEditorRowTypeCompound;
    }

    var row = [self _rowFromTemplate:copyTemplate originalTemplate:matchedTemplate withRowType:type];

    if (subpredicates == nil)
        return row;

    var count = [subpredicates count],
        subrows = [CPMutableArray array];

    for (var i = 0; i < count; i++)
    {
        var subrow = [self _rowObjectFromPredicate:subpredicates[i]];
        if (subrow != nil)
            [subrows addObject:subrow];
    }

    [row setValue:subrows forKey:[super subrowsKeyPath]];

    return row;
}

- (id)_rowFromTemplate:(CPPredicateEditorRowTemplate)aTemplate originalTemplate:(CPPredicateEditorRowTemplate)originalTemplate withRowType:(CPRuleEditorRowType)rowType
{
    var criteria = [CPArray array],
        values = [CPArray array],
        templateViews = [aTemplate templateViews],
        rootItems,
        count;

    rootItems = (rowType == CPRuleEditorRowTypeSimple) ? _rootTrees : _rootHeaderTrees;

    while ((count = [rootItems count]) > 0)
    {
        var treeChild;
        for (var i = 0; i < count; i++)
        {
            treeChild = [rootItems objectAtIndex:i];

            var currentView = [templateViews objectAtIndex:[treeChild indexIntoTemplate]],
                title = [treeChild title];

            if (title == nil || [title isEqual:[currentView titleOfSelectedItem]])
            {
                var node = [_CPPredicateEditorRowNode rowNodeFromTree:treeChild];
                [node applyTemplate:aTemplate withViews:templateViews forOriginalTemplate:originalTemplate];

                [criteria addObject:node];
                [values addObject:[node displayValue]];
                break;
            }
        }

        rootItems = [treeChild children];
    }

    var row = @{
            @"criteria": criteria,
            @"displayValues": values,
            @"rowType": rowType,
        };

    return row;
}

#pragma mark Get the predicate

- (void)_updatePredicate
{
    [self _updatePredicateFromRows];
}

- (void)_updatePredicateFromRows
{
    var rootRowsArray = [super _rootRowsArray],
        subpredicates = [CPMutableArray array],
        count,
        count2 = count = [rootRowsArray count],
        predicate;

    while (count--)
    {
        var item = [rootRowsArray objectAtIndex:count],
            subpredicate = [self _predicateFromRowItem:item];

        if (subpredicate != nil)
            [subpredicates insertObject:subpredicate atIndex:0];
    }

    if (_nestingMode != CPRuleEditorNestingModeList && count2 == 1)
        predicate = [subpredicates lastObject];
    else
        predicate = [[CPCompoundPredicate alloc] initWithType:[self _compoundPredicateTypeForRootRows] subpredicates:subpredicates];

    [self _setPredicate:predicate];
}

- (id)_predicateFromRowItem:(id)rowItem
{
    var subpredicates = [CPArray array],
        rowType = [rowItem valueForKey:_typeKeyPath];

    if (rowType == CPRuleEditorRowTypeCompound)
    {
        var subrows = [rowItem valueForKey:_subrowsArrayKeyPath],
            count = [subrows count];

        for (var i = 0; i < count; i++)
        {
            var subrow = [subrows objectAtIndex:i],
                predicate = [self _predicateFromRowItem:subrow];

            [subpredicates addObject:predicate];
        }
    }

    var criteria = [rowItem valueForKey:_itemsKeyPath],
        displayValues = [rowItem valueForKey:_valuesKeyPath],
        count = [criteria count],
        lastItem = [criteria lastObject],
        template = [lastItem templateForRow],
        templateViews = [template templateViews];

    for (var j = 0; j < count; j++)
    {
        var view = [templateViews objectAtIndex:j],
            value = [displayValues objectAtIndex:j];
        [[criteria objectAtIndex:j] setTemplateViews:templateViews];

        if ([view isKindOfClass:[CPPopUpButton class]])
            [view selectItemWithTitle:value];
        else if ([view respondsToSelector:@selector(setObjectValue:)])
            [view setObjectValue:[value objectValue]];
    }

    return [template predicateWithSubpredicates:subpredicates];
}

- (CPCompoundPredicateType)_compoundPredicateTypeForRootRows
{
    return CPAndPredicateType;
}

#pragma mark Control delegate

- (void)_sendRuleAction
{
    [super _sendRuleAction];
}

- (BOOL)_sendsActionOnIncompleteTextChange
{
    return NO;
}

/*
- (void)_setDefaultTargetAndActionOnView:(CPView)view
{
    if ([view isKindOfClass:[CPControl class]])
    {
        [view setTarget:self];
        [view setAction:@selector(_templateControlValueDidChange:)];
    }
}
- (void)_templateControlValueDidChange:(id)sender
{
}
- (void)controlTextDidBeginEditing:(CPNotification)notification
{
}
- (void)controlTextDidEndEditing:(CPNotification)notification
{
}
- (void)controlTextDidChange:(CPNotification)notification
{
}
*/

#pragma mark RuleEditor delegate methods

- (int)_queryNumberOfChildrenOfItem:(id)rowItem withRowType:(int)type
{
    if (rowItem == nil)
    {
        var trees = (type == CPRuleEditorRowTypeSimple) ? _rootTrees : _rootHeaderTrees;
        return [trees count];
    }
    return [[rowItem children] count];
}

- (id)_queryChild:(int)childIndex ofItem:(id)rowItem withRowType:(int)type
{
    if (rowItem == nil)
    {
        var trees = (type == CPRuleEditorRowTypeSimple) ? _rootTrees : _rootHeaderTrees;
        return [_CPPredicateEditorRowNode rowNodeFromTree:trees[childIndex]];
    }

    return [[rowItem children] objectAtIndex:childIndex];
}

- (id)_queryValueForItem:(id)rowItem inRow:(int)rowIndex
{
    return [rowItem displayValue];
}

@end

var CPPredicateTemplatesKey = @"CPPredicateTemplates";

@implementation CPPredicateEditor (CPCoding)

- (id)initWithCoder:(id)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self != nil)
    {
        var nibTemplates = [aCoder decodeObjectForKey:CPPredicateTemplatesKey];

        if (nibTemplates != nil)
            [self setRowTemplates:nibTemplates];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_allTemplates forKey:CPPredicateTemplatesKey];
}

@end

@implementation CPPredicateEditorValueBinder : CPBinder
{
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source _reflectPredicate:nil];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source _reflectPredicate:aValue];
}

@end
/*! @endcond */
