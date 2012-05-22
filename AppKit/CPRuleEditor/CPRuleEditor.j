/*
 * CPRuleEditor.j
 * AppKit
 *
 * Created by JC Bordes [jcbordes at gmail dot com] Copyright 2012 JC Bordes
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

@import <Foundation/CPPredicate.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPIndexSet.j>
@import <AppKit/CPViewAnimation.j>
@import <AppKit/CPView.j>

@import "CPRuleEditorModel.j"
@import "CPRuleEditorView.j"
@import "CPRuleEditorCriterion.j"

CPRuleEditorPredicateLeftExpression     = @"CPRuleEditorPredicateLeftExpression";
CPRuleEditorPredicateRightExpression    = @"CPRuleEditorPredicateRightExpression";
CPRuleEditorPredicateComparisonModifier = @"CPRuleEditorPredicateComparisonModifier";
CPRuleEditorPredicateOptions            = @"CPRuleEditorPredicateOptions";
CPRuleEditorPredicateOperatorType       = @"CPRuleEditorPredicateOperatorType";
CPRuleEditorPredicateCustomSelector     = @"CPRuleEditorPredicateCustomSelector";
CPRuleEditorPredicateCompoundType       = @"CPRuleEditorPredicateCompoundType";

CPRuleEditorRowsDidChangeNotification   = @"CPRuleEditorRowsDidChangeNotification";

CPRuleEditorItemPBoardType  = @"CPRuleEditorItemPBoardType";

/*!
    @ingroup appkit
    @class CPRuleEditor

    @brief A view for creating and configuring criteria.

    A CPRuleEditor object is a view that allows the user to visually create and configure a list of options which are expressed by the rule editor as a predicate (see Predicate documentation). The view has a delegate which offers a tree of choices to the view. The choices are presented by the view to the user as a row of popup buttons, static text fields, and custom views. Each row in the list represents a particular path down the tree of choices.

    CPRuleEditor exposes one binding, rows. You can bind rows to an ordered collection (such as an instance of CPMutableArray). Each object in the collection should have the following properties:
    @n @n
    @c @@"rowType"
    @n      An integer representing the type of the row (CPRuleEditorRowType).
    @n@n @c @@"subrows"
    @n      An ordered to-many relation (such as an instance of CPMutableArray) containing the directly nested subrows for the given row.
    @n@n @c @@"displayValues"
    @n      An ordered to-many relation containing the display values for the row.
    @n@n @c @@"criteria"
    @n      An ordered to-many relation containing the criteria for the row.
*/

@implementation CPRuleEditor : CPControl
{
    CPRuleEditorModel   _model @accessors(readonly,property=model);

    id              	_delegate @accessors(property=delegate);
    CPPredicate     	_predicate @accessors(readonly,property=predicate);

    CPString        	_rowClass @accessors(property=rowClass);
    CPString        	_rowTypeKeyPath @accessors(property=rowTypeKeyPath);
    CPString        	_subrowsKeyPath @accessors(property=subrowsKeyPath);
    CPString        	_criteriaKeyPath @accessors(property=criteriaKeyPath);
    CPString        	_displayValuesKeyPath @accessors(property=displayValuesKeyPath);

    CPString        	_stringsFilename;
    id              	_standardLocalizer @accessors(property=standardLocalizer);
    
    CPRuleEditorView	_contentView;
}

/*! @cond */

+ (CPString)defaultThemeClass
{
    return @"rule-editor";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[@"alternating-row-colors", @"selected-color", @"slice-top-border-color", @"slice-bottom-border-color", @"slice-last-bottom-border-color", @"font", @"add-image", @"remove-image"]];
}

- (id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if(!self)
    	return self;
    
    [self _build];
    
    return self;
}

-(void)_build
{
	_model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[_model setCanRemoveAllRows:NO];

    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPRuleEditorItemPBoardType,nil]];
    
    _contentView=[[CPRuleEditorView alloc] initWithFrame:[self bounds]];
    [_contentView setAutoresizingMask:CPViewWidthSizable];
	[self addSubview:_contentView];    

    var notificationCenter=[CPNotificationCenter defaultCenter];

    [notificationCenter addObserver:self selector:@selector(_contentFrameChanged:) name:CPViewFrameDidChangeNotification object:_contentView];

	[notificationCenter addObserver:self selector:@selector(notifyRowAdded:) name:CPRuleEditorModelRowAdded object:_model];
	[notificationCenter addObserver:self selector:@selector(notifyRowRemoved:) name:CPRuleEditorModelRowRemoved object:_model];
	[notificationCenter addObserver:self selector:@selector(notifyRowModified:) name:CPRuleEditorModelRowModified object:_model];

    [_contentView setDelegate:self];
    [_contentView setModel:_model];
}

- (void)removeFromSuperview
{
	if([self superview])	
		[[CPNotificationCenter defaultCenter] removeObserver:self];
	[[CPNotificationCenter defaultCenter] removeObserver:self];
}

-(void)_contentFrameChanged:(CPNotification)notification
{
	var contentSize=[_contentView frameSize];
	if(CGSizeEqualToSize(contentSize,[self frameSize]))
		return;
	
    [_contentView setPostsFrameChangedNotifications:NO];
	[self setFrameSize:contentSize];
    [_contentView setPostsFrameChangedNotifications:YES];
}

-(void)viewDidMoveToSuperview
{
	[super viewDidMoveToSuperview];
	var ua=window.navigator.userAgent;
	var isChrome=ua.indexOf("Chrome")!=-1;
	
	if(isChrome&&[[self superview] isKindOfClass:CPClipView])
	{
	    [[self superview] setPostsBoundsChangedNotifications:YES];
	    [[CPNotificationCenter defaultCenter] addObserver:self 
	    	selector:@selector(_wasScrolled:) name:CPViewBoundsDidChangeNotification object:[self superview]];
	}
}

-(void)_wasScrolled:(CPNotification)notification
{
	[_contentView forceRedrawForChromeBug];
}

/*! @endcond */

/*!
    @name Configuring a Rule Editor
*/

/*!
    @brief Returns the receiver’s delegate.
    @return The receiver’s delegate.
    @see setDelegate:
*/

- (id)delegate
{
     return _delegate;
}

/*!
    @brief Sets the receiver’s delegate.
    @param aDelegate The delegate for the receiver.
    @discussion CPRuleEditor requires a delegate that implements the required delegate methods to function.
    @see delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if(_delegate==aDelegate)
        return;
    
    if(aDelegate
    	&&(	![aDelegate respondsToSelector:@selector(ruleEditor:numberOfChildrenForCriterion:withRowType:)]
    		||![aDelegate respondsToSelector:@selector(ruleEditor:displayValueForCriterion:inRow:)]
    		||![aDelegate respondsToSelector:@selector(ruleEditor:child:forCriterion:withRowType:)]	) )
			[CPException raise:CPInvalidArgumentException reason:_cmd+@" : missing required delegate methods"];

    _delegate=aDelegate;
}

/*!
    @brief Returns a Boolean value that indicates whether the receiver is editable.
    @return @c YES if the receiver is editable, otherwise @c NO.
    @discussion The default is @c YES.
    @see setEditable:
*/

- (BOOL)isEditable
{
    return [_contentView editable];
}

/*!
    @brief Sets whether the receiver is editable.
    @param editable @c YES if the receiver is editable, otherwise @c NO.
    @see isEditable:
*/
- (void)setEditable:(BOOL)editable
{
	[_contentView setEditable:editable];
}

/*!
    @brief Returns the nesting mode for the receiver.
    @return The nesting mode for the receiver.
    @see setNestingMode:
*/
- (CPRuleEditorNestingMode)nestingMode
{
     return [_model nestingMode];
}

/*!
    @brief Sets the nesting mode for the receiver.
    @param mode The nesting mode for the receiver.
    @discussion You typically set the nesting mode at view creation time and do not subsequently modify it. The default is @c CPRuleEditorNestingModeSimple.
    @see nestingMode
    @note Currently CPRuleEditorNestingModeCompound is experimental.
*/
- (void)setNestingMode:(CPRuleEditorNestingMode)nestingMode
{
	[_model setNestingMode:nestingMode];
}

/*!
    @brief Returns a Boolean value that indicates whether all the rows can be removed.
    @return @c YES if all the rows can be removed, otherwise @c NO.
    @see setCanRemoveAllRows:
*/
- (BOOL)canRemoveAllRows
{
    return [_model canRemoveAllRows];
}

/*!
    @brief Sets whether all the rows can be removed.
    @param canRemove @c YES if all the rows can be removed, otherwise @c NO.
    @see canRemoveAllRows
*/
- (void)setCanRemoveAllRows:(BOOL)canRemoveAllRows
{
    [_model setCanRemoveAllRows:canRemoveAllRows];
}


/*!
    @brief Returns the row height for the receiver.
    @return The row height for the receiver.
    @see setRowHeight:
*/
- (CGFloat)rowHeight
{
	return [_contentView rowHeight];
}

/*!
    @brief Sets the row height for the receiver.
    @param height The row height for the receiver.
    @see rowHeight
*/
- (void)setRowHeight:(CGFloat)rowHeight
{
	[_contentView setRowHeight:rowHeight];
}

/*!
    @name Working with Formatting
*/

/*!
    @brief Returns the formatting dictionary for the receiver.
    @return The formatting dictionary for the receiver.
    @see setFormattingDictionary:
    @see setFormattingStringsFilename:
*/
- (CPDictionary)formattingDictionary
{
    return [_standardLocalizer dictionary];
}

/*!
    @brief Sets the formatting dictionary for the receiver.
    @param dictionary The formatting dictionary for the receiver.
    @discussion If you set the formatting dictionary with this method, it sets the current formatting strings file name to @c nil.
    @see formattingDictionary
    @see formattingStringsFilename
*/
- (void)setFormattingDictionary:(CPDictionary)dictionary
{
    [_standardLocalizer setDictionary:dictionary];
    _stringsFilename = nil;
}

/*!
    @brief Returns the name of the strings file for the receiver.
    @return The name of the strings file for the receiver.
    @see setFormattingStringsFilename:
*/
- (CPString)formattingStringsFilename
{
    return _stringsFilename;
}

/*!
    @brief Sets the name of the strings file used for formatting.
    @param stringsFilename The name of the strings file for the receiver.
    @discussion CPRuleEditor looks for a strings file with the given name in the main bundle and (if appropriate) the bundle containing the nib file from which it was loaded. If it finds a strings file resource with the given name, CPRuleEditor loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using formattingDictionary.
        If you set the formatting dictionary with -#setFormattingDictionary:, it sets the current formatting strings file name nil.
    @see formattingStringsFilename
*/
- (void)setFormattingStringsFilename:(CPString)stringsFilename
{
    // Can we set _stringsFilename to nil in cocoa ?
    if (_standardLocalizer == nil)
        _standardLocalizer = [CPRuleEditorLocalizer new];

    if (_stringsFilename != stringsFilename)
    {
        _stringsFilename = stringsFilename;

        if (stringsFilename !== nil)
        {
            if (![stringsFilename hasSuffix:@".strings"])
                stringsFilename = stringsFilename + @".strings";
            var path = [[CPBundle mainBundle] pathForResource:stringsFilename];
            if (path !=nil)
                [_standardLocalizer loadContentOfURL:[CPURL URLWithString:path]];
        }
    }
}

/*!
    @name Providing Data
*/

/*!
    @brief Instructs the receiver to refetch criteria from its delegate.
    @discussion You can use this method to indicate that the available criteria may have changed and should be refetched from the delegate and the popups recalculated.
*/
- (void)reloadCriteria
{
}

/*!
    @brief Modifies the row at a given index to contain the given items and values.
    @param criteria The array of criteria for the row at @a rowIndex. Pass an empty array to force the receiver to query its delegate. This value must not be nil.
    @param values The array of values for the row at @a rowIndex. Pass an empty array to force the receiver to query its delegate. This value must not be @c nil.
    @param rowIndex The index of a row in the receiver.

    @discussion It is your responsibility to ensure that each item in the array is a child of the previous item, and that the first item is a root item for the row type. If the last item has child items, then the items array will be extended by querying the delegate for child items until a childless item is reached.
*/
- (void)setCriteria:(CPArray)criteria andDisplayValues:(CPArray)values forRowAtIndex:(int)rowIndex
{
	if(!criteria||!values)
		return;
	
	var row=[_model rowAtIndex:rowIndex];
	if(!row)
		return;

	var cCount=[criteria count];
	if(!cCount)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid criterion array, must not be empty"];
	
	var items;
	var value;
	var criterion;
	var vCount=[values count];
	var res=[CPArray initWithCapacity:cCount];

	for(var i=0;i<cCount;i++)
	{
		items=[criteria objectAtIndex:i];
		if(!items||![items isKindOfClass:CPArray])
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid criteria : criteria must be an array of arrays"];
		value=(i<vCount)?values[i]:nil;
		criterion=[[CPRuleEditorCriterion alloc] initWithItems:items displayValue:value];
		[res addObject:criterion];
	}
	
	[row setCriteria:res];
}

/*!
    @brief Returns the currently chosen items for a given row.
    @param rowIndex The index of a row in the receiver.
    @return The currently chosen items for row @a row.
*/
- (id)criteriaForRow:(int)rowIndex
{
	var row=[_model rowAtIndex:rowIndex];
	if(!row)
		return nil;
	return [row criteriaItems];
}

/*!
    @name Working with the Selection
*/

/*!
    @brief Returns the chosen values for a given row.
    @param row The index of a row in the receiver.
    @return The chosen values (strings, views, or menu items) for row row.
    @discussion The values returned are the same as those returned from the delegate method -#ruleEditor:displayValueForCriterion:inRow:
*/
- (CPMutableArray)displayValuesForRow:(int)rowIndex
{
	var row=[_model rowAtIndex:rowIndex];
	if(!row)
		return nil;
	return [row criteriaDisplayValues];
}

/*!
    @brief Returns the number of rows in the receiver.
    @return The number of rows in the receiver.
*/
- (int)numberOfRows
{
	return [_model flatRowsCount];
}

/*!
    @brief Returns the index of the parent of a given row.
    @param rowIndex The index of a row in the receiver.
    @return The index of the parent of the row at @a rowIndex. If the row at @a rowIndex is a root row, returns @c -1.
*/
- (int)parentRowForRow:(int)rowIndex
{
	var row=[_model rowAtIndex:rowIndex];
	if(!row)
		return nil;
	return [row parent];
}

/*
    Returns the index of the row containing a given value.

    displayValue The display value (string, view, or menu item) of an item in the receiver. This value must not be nil.

    The index of the row containing displayValue, or CPNotFound.

    This method searches each row via objects equality for the given display value, which may be present as an alternative in a popup menu for that row.
*/

- (CPInteger)rowForDisplayValue:(id)displayValue
{
	return [_model rowWithDisplayValue:displayValue];
}

/*!
    @brief Returns the type of a given row.
    @param rowIndex The index of a row in the receiver.
    @return The type of the row at @a rowIndex.
    @warning Raises a @c CPRangeException if rowIndex is less than @c 0 or greater than or equal to the number of rows.
*/
- (CPRuleEditorRowType)rowTypeForRow:(int)rowIndex
{
	var row=[_model rowAtIndex:rowIndex];
	if(!row)
		return nil;
	return [row rowType];
}

/*!
    @brief Returns the immediate subrows of a given row.
    @param rowIndex The index of a row in the receiver, or @c -1 to get the top-level rows.
    @return The immediate subrows of the row at @a rowIndex.
    @discussion Rows are numbered starting at @c 0.
*/
- (CPIndexSet)subrowIndexesForRow:(int)rowIndex
{
	return [_model immediateSubrowsIndexesOfRowAtIndex:rowIndex];
}

/*!
    @brief Returns the indexes of the receiver’s selected rows.
    @return The indexes of the receiver’s selected rows.
*/
- (CPIndexSet)selectedRowIndexes
{
	return nil;
// Not implemented
}

/*!
    @brief Sets in the receiver the indexes of rows that are selected.
    @param indexes The indexes of rows in the receiver to select.
    @param extend If @c NO, the selected rows are specified by indexes. If @c YES, the rows indicated by indexes are added to the collection of already selected rows, providing multiple selection.
*/
- (void)selectRowIndexes:(CPIndexSet)indexes byExtendingSelection:(BOOL)extend
{
// Not implemented
}

/*!
    @name Manipulating Rows
*/

/*!
    @brief Adds a row to the receiver.
    @param sender Typically the object that sent the message.
    @see insertRowAtIndex:withType:asSubrowOfRow:animate:
*/
- (void)addRow:(id)sender
{
	var rowType=[_model defaultRowType];
	var index=[_model lastRowIndex]+1;
	var criteria=[self refreshCriteriaForNewRowOfType:rowType atIndex:index];

	criteria=[self willInsertNewRowWithCriteria:criteria atIndex:index];
	if(!criteria)
		return;

	[_model addNewRowOfType:rowType criteria:criteria];
}

/*!
    @brief Adds a new row of a given type at a given location.
    @param rowIndex The index at which the new row should be inserted. @a rowIndex must be greater than @a parentRow, and much specify a row that does not fall amongst the children of some other parent.
    @param rowType The type of the new row.
    @param parentRow The index of the row of which the new row is a child. Pass -1 to indicate that the new row should be a root row.
    @param shouldAnimate @c YES if creation of the new row should be animated, otherwise @c NO.
    @note Currently, @a shouldAnimate has no effect, rows are always animated when calling this method.
    @see addRow:
*/
- (void)insertRowAtIndex:(int)rowIndex withType:(unsigned int)rowType asSubrowOfRow:(int)parentRow animate:(BOOL)shouldAnimate
{
	var criteria=[self refreshCriteriaForNewRowOfType:rowType atIndex:rowIndex];

	criteria=[self willInsertNewRowWithCriteria:criteria atIndex:rowIndex];
	if(!criteria)
		return;

	[_model insertNewRowAtIndex:rowIndex ofType:rowType withParentRowIndex:parentRow criteria:criteria data:nil];
}

/*!
    @brief Removes the row at a given index.
    @param rowIndex The index of a row in the receiver.
    @warning Raises a @c CPRangeException if @a rowIndex is less than @c 0 or greater than or equal to the number of rows.
    @see removeRowsAtIndexes:includeSubrows:
*/
- (void)removeRowAtIndex:(int)rowIndex
{
	[_model removeRowAtIndex:rowIndex includeSubrows:NO];
}

/*!
    @brief Removes the rows at a given index.
    @param rowIndexes Indexes of one or more rows in the receiver.
    @param includeSubrows If @c YES, then sub-rows of deleted rows are also deleted; if @c NO, then each sub-row is adopted by its first non-deleted ancestor, or becomes a root row.
    @warning Raises a @c CPRangeException if any index in @a rowIndexes is less than 0 or greater than or equal to the number of rows.
    @see removeRowAtIndex:
*/
- (void)removeRowsAtIndexes:(CPIndexSet)rowIndexes includeSubrows:(BOOL)includeSubrows
{
	[_model removeRowsAtIndexes:rowIndex includeSubrows:includeSubrows];
}

/*!
    @name Supporting Bindings
*/

/*!
    @brief Returns the class used to create a new row in the “rows” binding.
    @return The class used to create a new row in the "rows" binding.
    @see setRowClass:
*/
- (Class)rowClass
{
	return _rowClass;
}

/*!
    @brief Sets the class to use to create a new row in the "rows” binding.
    @param rowClass The class to use to create a new row in the "rows” binding.
    @see rowClass
*/
- (void)setRowClass:(Class)rowClass
{
	if(_rowClass!==rowClass)
		_rowClass=rowClass;
}

/*!
    @brief Returns the key path for the row type.
    @return The key path for the row type.
    @discussion The default value is @c @"rowType".
    The key path is used to get the row type in the “rows” binding. The corresponding property should be a number that specifies an @c CPRuleEditorRowType value.
    @see setRowTypeKeyPath:
*/
- (CPString)rowTypeKeyPath
{
    return _rowTypeKeyPath;
}

/*!
    @brief Sets the key path for the row type.
    @param keyPath The key path for the row type.
    @see rowTypeKeyPath
*/
- (void)setRowTypeKeyPath:(CPString)keyPath
{
    if(_rowTypeKeyPath!==keyPath)
       _rowTypeKeyPath=keyPath;
}

/*!
    @brief Returns the key path for the subrows.
    @return The key path for the subrows.
    @discussion The default value is @"subrows".
    The key path is used to get the nested rows in the “rows” binding. The corresponding property should be an ordered to-many relationship containing additional bound row objects.
    @see setSubrowsKeyPath:
*/
- (CPString)subrowsKeyPath
{
    return _subrowsKeyPath;
}

/*!
    @brief Sets the key path for the subrows.
    @param keyPath The key path for the subrows.
    @see subrowsKeyPath
*/
- (void)setSubrowsKeyPath:(CPString)keyPath
{
    if(_subrowsKeyPath!==keyPath)
        _subrowsKeyPath=keyPath;
}

/*!
    @brief Returns the criteria key path.
    @return The criteria key path.
    @discussion The default value is @"criteria".
    The key path is used to get the criteria for a row in the "rows" binding. The criteria objects are what the delegate returns from -#ruleEditor:child:forCriterion:withRowType: . The corresponding property should be an ordered to-many relationship.
    @see setCriteriaKeyPath:
*/
- (CPString)criteriaKeyPath
{
    return _criteriaKeyPath;
}

/*!
    @brief Sets the key path for the criteria.
    @param keyPath The key path for the criteria.
    @see criteriaKeyPath
*/
- (void)setCriteriaKeyPath:(CPString)keyPath
{
    if(_criteriaKeyPath!==keyPath)
        _criteriaKeyPath=keyPath;
}

/*!
    @brief Returns the display values key path.
    @return The display values key path.
    @discussion The default is @"displayValues".
    The key path is used to get the display values for a row in the "rows" binding. The display values are what the delegate returns from -#ruleEditor:displayValueForCriterion:inRow: The corresponding property should be an ordered to-many relationship.
    @see setDisplayValuesKeyPath:
*/
- (CPString)displayValuesKeyPath
{
    return _displayValuesKeyPath;
}

/*!
    @brief Sets the key path for the display values.
    @param keyPath The key path for the the display values.
    @see displayValuesKeyPath
*/
- (void)setDisplayValuesKeyPath:(CPString)keyPath
{
    if(_displayValuesKeyPath!==keyPath)
        _displayValuesKeyPath=keyPath;
}

/*!
    @name Configuring Rows Animation
*/

/*!
    @brief Returns the current animation for the receiver.
    @return The current animation for the receiver.
    @see setAnimation:
*/
- (id)animation
{
//Not implemented	
    return nil;
}

/*!
    @brief Sets the current animation for the receiver.
    @param animation A CPViewAnimation object used to animate rows.
    @discussion The default is a CPViewAnimation with a @c 0.5s duration and a @c CPAnimationEaseInOut curve.
    @see animation
*/
- (void)setAnimation:(CPViewAnimation)animation
{
//Not implemented	
}

/*!
    @name Delegate Methods
*/

/*!
    @param editor The rule editor that sent the message.
    @param index The index of the requested child criterion. This value must be in the range from 0 up to (but not including) the number of children, as reported by the delegate in ruleEditor:numberOfChildrenForCriterion:withRowType:.
    @param criterion The parent of the requested child, or nil if the rule editor is requesting a root criterion.
    @param rowType The type of the row.
    @return An object representing the requested child (or root) criterion. This object is used by the delegate to represent that position in the tree, and is passed as a parameter in subsequent calls to the delegate.
    @discussion This method is required.

    - (id)ruleEditor:(CPRuleEditor)editor child:(CPInteger)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the value is required.
    @param row The row number of criterion.
    @return The value for criterion.
    @discussion The value should be an instance of CPString, CPView, or CPMenuItem. If the value is a CPView or CPMenuItem, you must ensure it is unique for every invocation of this method; that is, do not return a particular instance of CPView or CPMenuItem more than once.

    - (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(CPInteger)row
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the number of children is required.
    @param rowType The type of row of criterion.
    @return The number of child items of criterion. If criterion is nil, return the number of root criteria for the row type rowType.

    - (CPInteger)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the predicate parts are required.
    @param value The display value.
    @param row The row number of criterion.
    @return A dictionary representing the parts of the predicate determined by the given criterion and value. The keys of the dictionary should be the string constants specified in Predicate Part Keys with corresponding appropriate values.

    - (CPDictionary)ruleEditor:(CPRuleEditor)editor predicatePartsForCriterion:(id)criterion withDisplayValue:(id)value inRow:(CPInteger)row
*/

/*! @cond */


#pragma mark Refresh criteria from delegate

-(CPArray)refreshCriteriaForNewRowOfType:(CPInteger)rowType atIndex:rowIndex
{
	return [self refreshCriteriaForRow:nil rowIndex:rowIndex rowType:rowType startingAtIndex:0 currentValueIndex:0 currentValue:nil];
}

-(CPArray)refreshCriteriaForRow:(CPRuleEditorModelItem)aRow rowIndex:(CPInteger)rowIndex rowType:(CPInteger)rowType startingAtIndex:(CPInteger)index currentValueIndex:valueIndex currentValue:(id)currentValue
{
	if(!aRow&&index>0)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : startingIndex must be 0 when refreshing criteria from delegate when row is not yet created"];
	if(aRow&&valueIndex<0)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : parentValueIndex must be >= 0"];

	var criteria;	
	var currentCriterion=nil;
	var currentCriterionItem=nil;
	
	if(aRow&&index>=0)
	{
		var criteria=[aRow criteria];
		var count=[criteria count];
		
		for(var i=index;i<count;i++)
			[criteria removeObjectAtIndex:index];

		count=[criteria count];
		if(count)
		{
			currentCriterion=criteria[count-1];
			[currentCriterion setDisplayValue:currentValue];
		}
	}
	else
		criteria=[[CPMutableArray alloc] init];
	
	if(currentCriterion)
	{
		var items=[currentCriterion items]
		var count=items?[items count]:0;
		if(!count)
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid internal criterion object"];
		if(valueIndex>=count)
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid internal criterion object"];
		currentCriterionItem=items[valueIndex];
		[currentCriterion setCurrentIndex:valueIndex];
	}
	
	var newCriterion;
	var criterionItem;
	var criterionDisplayValue=nil;
	var nb;
	var first=YES;

	while((nb=[_delegate ruleEditor:self numberOfChildrenForCriterion:currentCriterionItem withRowType:rowType])>0)
	{
		var items=[CPMutableArray arrayWithCapacity:nb];
		for(var i=0;i<nb;i++)
		{
			criterionItem=[_delegate ruleEditor:self child:i forCriterion:currentCriterionItem withRowType:rowType];
			if(!criterionItem)
				[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : delegate must return not null criterion children"];
			[items addObject:criterionItem];
		}
		
		if(currentCriterionItem==[items objectAtIndex:0])
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : infinite loop detected"];

		if(first)
		{
			first=NO;
			
			var value;
			for(var i=0;i<nb;i++)
			{
				criterionItem=[items objectAtIndex:i];
				value=[_delegate ruleEditor:self displayValueForCriterion:criterionItem inRow:rowIndex];
				
				if([value isKindOfClass:CPMenuItem]&&[value isSeparatorItem])
					continue;

				if(![self rowForDisplayValue:value])
				{
					currentCriterionItem=criterionItem;
					criterionDisplayValue=value;
					break;
				}
			}
			if(!criterionDisplayValue)
			{
				do
				{
					var useCeil=(new Date().getTime()%2)==0;
					var rand=Math.random()*(nb-1);
					var idx=useCeil?Math.ceil(rand):Math.floor(rand);
					idx=Math.min(idx,nb-1);
					currentCriterionItem=[items objectAtIndex:idx];
					criterionDisplayValue=[_delegate ruleEditor:self displayValueForCriterion:currentCriterionItem inRow:rowIndex];
				}
				while([criterionDisplayValue isKindOfClass:CPMenuItem]&&[criterionDisplayValue isSeparatorItem]);
			}
		}
		else
		{
			currentCriterionItem=[items objectAtIndex:0];
			criterionDisplayValue=[_delegate ruleEditor:self displayValueForCriterion:currentCriterionItem inRow:rowIndex];
		}
		
		[criteria addObject:[[CPRuleEditorCriterion alloc] initWithItems:items displayValue:criterionDisplayValue]];
	}
	return criteria;
}

#pragma mark Predicate management

/*!
    @name Working with Predicates
*/

/*!
    @brief Returns the predicate for the receiver.
    @return If the delegate implements -#ruleEditor:predicatePartsForCriterion:withDisplayValue:inRow:, the predicate for the receiver. If not, or if the delegate does not return enough parts to construct a full predicate, returns @c nil.
    @see predicateForRow:
*/
- (CPPredicate)predicate
{
	if(_predicate)
	    return _predicate;
	[self reloadPredicate];
	return _predicate;
}

/*!
    @brief Instructs the receiver to regenerate its predicate by invoking the corresponding delegate method.
    @discussion You typically invoke this method because something has changed (for example, a view's value).
*/
- (void)reloadPredicate
{
    var count=[_model rowsCount];
    if(!count)
    	return;

	var row;
	var subpredicate;    
    var subpredicates=[CPMutableArray array];
	var indexes=[self subrowIndexesForRow:-1];
	var index=indexes?[indexes firstIndex]:CPNotFound;

	while(index!=CPNotFound)
    {
    	row=[_model rowAtIndex:index];
    	subpredicate=[self predicateForRow:index];
    	if(subpredicate)
	    	[subpredicates addObject:subpredicate];
    	index=[indexes indexGreaterThanIndex:index];
    }
    
    if([subpredicates count]==1&&[[subpredicates objectAtIndex:0] isKindOfClass:CPCompoundPredicate])
    {
    	_predicate=[subpredicates objectAtIndex:0];
    	return;
    }

    _predicate=[[CPCompoundPredicate alloc] initWithType:CPAndPredicateType subpredicates:subpredicates];
}

/*!
    @brief Returns the predicate for a given row.
    @param aRow The index of a row in the receiver.
    @return The predicate for the row at @a aRow.
    @discussion You should rarely have a need to call this directly, but you can override this method in a subclass to perform specialized predicate handling for certain criteria or display values.
*/

- (CPPredicate)predicateForRow:(CPInteger)aRowIndex
{
	if(!_delegate||![_delegate respondsToSelector:@selector(ruleEditor:predicatePartsForCriterion:withDisplayValue:inRow:)])
		return nil;
		
    var row=[_model rowAtIndex:aRowIndex];
    if(!row)
    	return nil;
    	
    var predicate;
    var criteria=[row criteria];
    var count=[criteria count];

	var criterion;
	var criterionItem;
	var displayValue;
	var predicateInfo;
    var predicateParts=[CPDictionary dictionary];
	
    for(var i=0;i<count;i++)
    {
        criterion=[criteria objectAtIndex:i];
        criterionItem=[criterion currentItem];
        if(!criterionItem)
        	continue;
        	
        displayValue=[criterion displayValue];
        predicateInfo=[_delegate ruleEditor:self predicatePartsForCriterion:criterionItem withDisplayValue:displayValue inRow:aRowIndex];
        if(predicateInfo)
            [predicateParts addEntriesFromDictionary:predicateInfo];
    }

    if([row rowType]==CPRuleEditorRowTypeCompound)
    {
	    var compoundType=[predicateParts objectForKey:CPRuleEditorPredicateCompoundType];
		return [self compoundPredicateForRow:row compoundType:compoundType];
    }

    var options=[predicateParts objectForKey:CPRuleEditorPredicateOptions];
    var modifier=[predicateParts objectForKey:CPRuleEditorPredicateComparisonModifier];
    var selector=CPSelectorFromString([predicateParts objectForKey:CPRuleEditorPredicateCustomSelector]);

    try
    {
        if(selector)
        {
            return [CPComparisonPredicate
                         predicateWithLeftExpression:[predicateParts objectForKey:CPRuleEditorPredicateLeftExpression]
                         rightExpression:[predicateParts objectForKey:CPRuleEditorPredicateRightExpression]
                         customSelector:selector];
        }
        
        return [CPComparisonPredicate
                         predicateWithLeftExpression:[predicateParts objectForKey:CPRuleEditorPredicateLeftExpression]
                         rightExpression:[predicateParts objectForKey:CPRuleEditorPredicateRightExpression]
                         modifier:(modifier||CPDirectPredicateModifier)
                         type:[predicateParts objectForKey:CPRuleEditorPredicateOperatorType]
                         options:(options||CPCaseInsensitivePredicateOption)];
    }
    catch(error)
    {
        CPLog.debug(@"predicate error: ["+[error description]+"] for row "+aRow);
        return nil;
    }
}

-(CPPredicate)compoundPredicateForRow:(CPRuleEditorModelItem)row compoundType:(CPInteger)compoundType
{
	if(!row)
		return nil;
		
	var subrow;
    var subpredicate;
    var subpredicates=[CPMutableArray array];
    
    var count=[row subrowsCount];
    for(var i=0;i<count;i++)
    {
    	subrow=[row childAtIndex:i];
    	subpredicate=[self predicateForRow:[_model indexOfRow:subrow]];
    	if(!subpredicate)
    		continue;
    	[subpredicates addObject:subpredicate];
    }

    if(![subpredicates count])
        return nil;

    try
    {
        return [[CPCompoundPredicate alloc] initWithType:compoundType subpredicates:subpredicates];
    }
    catch(error)
    {
        CPLog.debug(@"predicate error"+[error description]);
        return nil;
    }
}

#pragma mark Overridable methods

-(CPArray)willInsertNewRowWithCriteria:(CPArray)criteria atIndex:(CPInteger)index
{
	return criteria;
}

-(void)didAddRow:(CPRuleEditorModelItem)row
{
}

-(void)willModifyRow:(CPRuleEditorModelItem)row
{
}

-(void)didModifyRow:(CPRuleEditorModelItem)row
{
}

-(void)didRemoveRow:(CPRuleEditorModelItem)row
{
}

@end

@implementation CPRuleEditor(CPRuleEditorModelObserver)

-(void)notifyRowAdded:(CPNotification)notification
{
	if(!notification)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : null notification"];

	var userInfo=[notification userInfo];
	if(!userInfo)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is null"];
	
	var row=[userInfo valueForKey:@"row"];
	if(!row)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is missing row"];

	[self didAddRow:row];
	[self notifyRowsDidChange:notification];
}

-(void)notifyRowRemoved:(CPNotification)notification
{
	if(!notification)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : null notification"];

	var userInfo=[notification userInfo];
	if(!userInfo)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is null"];
	
	var row=[userInfo valueForKey:@"row"];
	if(!row)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is missing row"];

	[self didRemoveRow:row];
	[self notifyRowsDidChange:notification];
}

-(void)notifyRowModified:(CPNotification)notification
{
	if(!notification)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : null notification"];

	var userInfo=[notification userInfo];
	if(!userInfo)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is null"];
	
	var row=[userInfo valueForKey:@"row"];
	if(!row)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : notification userInfo is missing row"];

	[self didModifyRow:row];
	[self notifyRowsDidChange:notification];
}

-(void)notifyRowsDidChange:(CPNotification)notification
{
	[[CPNotificationCenter defaultCenter] postNotificationName:CPRuleEditorRowsDidChangeNotification object:self];
	if(!_delegate||![_delegate respondsToSelector:@selector(ruleEditorRowsDidChange:)])
		return;

	var notif=[CPNotification notificationWithName:CPRuleEditorRowsDidChangeNotification object:self];
	[_delegate ruleEditorRowsDidChange:notif];
}

@end

@implementation CPRuleEditor(CPRuleEditorViewDelegate)

-(CPString)localizedString:(CPString)text
{
	if(![self standardLocalizer])
		return text;
	var res=[[self standardLocalizer] localizedStringForString:text];
	return res!=nil?res:text;
}

-(BOOL)canMoveRow:(CPRuleEditorModelItem)aRow afterRow:(CPRuleEditorModelItem)anotherRow
{
	if(aRow==anotherRow||[anotherRow hasAncestor:aRow])
		return NO;
	
	if(![_model isRowRemoveable:aRow includeSubrows:YES])
		return NO;
	
	if([anotherRow rowType]==CPRuleEditorRowTypeCompound)
		return [_model allowNewRowInsertOfType:[aRow rowType] withParent:anotherRow];
	else
		return [_model allowNewRowInsertOfType:[aRow rowType] withParent:[anotherRow parent]];
}

-(void)moveRow:(CPRuleEditorModelItem)aRow afterRow:(CPRuleEditorModelItem)anotherRow
{
	if(![self canMoveRow:aRow afterRow:anotherRow])
		return;
		
	var index=[_model indexOfRow:aRow];
	var removedRow=[_model removeRowAtIndex:index includeSubrows:YES];
	if(!removedRow)
		return;

	index=[_model indexOfRow:anotherRow]+1;
	var parentIndex=[anotherRow rowType]==CPRuleEditorRowTypeCompound?index-1:[_model indexOfRow:[anotherRow parent]];
	
	[_model insertRow:removedRow atIndex:index withParentRowIndex:parentIndex];
}

-(void)insertNewRowOfType:(CPInteger)rowType afterRow:(CPRuleEditorModelItem)aRow
{
	if(!aRow)
		return;

	var index=[_model indexOfRow:aRow];
	if(index==CPNotFound)
		return;
	
	var originalRowType=[aRow rowType];
	
	if(originalRowType==CPRuleEditorRowTypeCompound)
	{
		rowType=[_model allowNewRowInsertOfType:rowType withParent:aRow]?rowType:CPRuleEditorRowTypeSimple;
		[self insertRowAtIndex:index+1 withType:rowType asSubrowOfRow:index animate:YES];
		return;
	}
	
	var parent=[aRow parent];
	var parentIndex=parent?[_model indexOfRow:parent]:-1;

	index++;
	
	[self insertRowAtIndex:index withType:rowType asSubrowOfRow:parentIndex animate:YES];
	
}

-(BOOL)isRowRemoveable:(CPRuleEditorModelItem)aRow
{
	return [_model isRowRemoveable:aRow includeSubrows:NO];
}

-(void)removeRow:(CPRuleEditorModelItem)aRow
{
	if(!aRow)
		return;

	var index=[_model indexOfRow:aRow];
	if(index==CPNotFound)
		return;
		
	[self removeRowAtIndex:index];
}

-(void)valueChanged:(id)value criterionIndex:(CPInteger)index valueIndex:valueIndex inRow:(CPRuleEditorModelItem)aRow
{
	if(!aRow)
		return;
	
	var rowIndex=[_model indexOfRow:aRow];
	if(rowIndex==CPNotFound)
		return;
		
	var criteria=[self refreshCriteriaForRow:aRow rowIndex:rowIndex rowType:CPRuleEditorRowTypeSimple 
		startingAtIndex:index+1 currentValueIndex:valueIndex currentValue:value];

	[self willModifyRow:aRow];
	[_model setCriteria:criteria forRow:aRow];	
}

-(id)criterionItemCopy:(id)item
{
	return [item copy];
}

@end

@implementation CPRuleEditor (CPCoding)

//TODO

- (id)initWithCoder:(CPCoder)coder
{
    self = [super initWithCoder:coder];
    if (self != nil)
    {
    	[self _build];
    }

    return self;
}

- (void)encodeWithCoder:(id)coder
{
    [super encodeWithCoder:coder];
}

@end

/*! @endcond */