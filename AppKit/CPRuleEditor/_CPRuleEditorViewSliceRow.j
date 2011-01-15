/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

@import "_CPRuleEditorViewSlice.j"
@import "_CPRuleEditorPopUpButton.j"
@import "CPRuleEditor.j"

var CONTROL_HEIGHT = 16.,
    BUTTON_HEIGHT = 16.;

@implementation _CPRuleEditorViewSliceRow : _CPRuleEditorViewSlice
{
    CPMutableArray  _ruleOptionViews;
    CPMutableArray  _ruleOptionFrames;
    CPMutableArray  _correspondingRuleItems;
    CPMutableArray  _ruleOptionInitialViewFrames;
    CPButton        _addButton;
    CPButton        _subtractButton;
    BOOL            editable;
    CPRuleEditorRowType _rowType @accessors;
    CPRuleEditorRowType _plusButtonRowType;
}

- (id)initWithFrame:(CGRect)frame ruleEditorView:(id)editor
{
    if (self = [super initWithFrame:frame ruleEditorView:editor])
        [self _initShared];

    return self;
}

- (void)_initShared
{
    _correspondingRuleItems = [[CPMutableArray alloc] init];
    _ruleOptionFrames = [[CPMutableArray alloc] init];
    _ruleOptionInitialViewFrames = [[CPMutableArray alloc] init];
    _ruleOptionViews = [[CPMutableArray alloc] init];
     editable = [_ruleEditor isEditable];

    _addButton = [self _createAddRowButton];
    _subtractButton = [self _createDeleteRowButton];
    [_addButton setToolTip:[_ruleEditor _toolTipForAddSimpleRowButton]];
    [_subtractButton setToolTip:[_ruleEditor _toolTipForDeleteRowButton]];
    [_addButton setHidden:!editable];
    [_subtractButton setHidden:!editable];
    [self addSubview:_addButton];
    [self addSubview:_subtractButton];

    [self setAutoresizingMask:CPViewWidthSizable];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_textDidChange:) name:CPControlTextDidChangeNotification object:nil];
}

- (CPButton)_createAddRowButton
{
    var button = [[_CPRuleEditorButton alloc] initWithFrame:CGRectMakeZero()];
    [button setImage:[_ruleEditor _addImage]];

    [button setAction:@selector(_addOption:)];
    [button setTarget:self];
    [button setAutoresizingMask:CPViewMinXMargin];

    return button;
}

- (CPButton)_createDeleteRowButton
{
    var button = [[_CPRuleEditorButton alloc] initWithFrame:CGRectMakeZero()];
    [button setImage:[_ruleEditor _removeImage]];

    [button setAction:@selector(_deleteOption:)];
    [button setTarget:self];
    [button setAutoresizingMask:CPViewMinXMargin];

    return button;
}

- (CPMenuItem)_createMenuItemWithTitle:(CPString )title
{
    title = [[_ruleEditor standardLocalizer] localizedStringForString:title];
    return [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
}

- (CPPopUpButton)_createPopUpButtonWithItems:(CPArray)itemsArray selectedItemIndex:(int)index
{
    var title = [[itemsArray objectAtIndex:index] title],
        font = [_ruleEditor font],
        width = [title sizeWithFont:font].width + 20,
        rect = CGRectMake(0, ([_ruleEditor rowHeight] - CONTROL_HEIGHT)/2, (width - width % 40) + 80, CONTROL_HEIGHT);

    var popup = [[_CPRuleEditorPopUpButton alloc] initWithFrame:rect];
    [popup setValue:font forThemeAttribute:@"font"];

    var count = [itemsArray count];
    for (var i = 0; i < count; i++)
        [popup addItem:[itemsArray objectAtIndex:i]];

    [popup selectItemAtIndex:index];

    return popup;
}

- (CPMenuItem)_createMenuSeparatorItem
{
    return [CPMenuItem separatorItem];
}

- (_CPRuleEditorTextField)_createStaticTextFieldWithStringValue:(CPString )text
{
    text = [[_ruleEditor standardLocalizer] localizedStringForString:text];

    var textField = [[_CPRuleEditorTextField alloc] initWithFrame:CPMakeRect(0, 0, 200, CONTROL_HEIGHT)];
    var font = [_ruleEditor font];
    font = [CPFont fontWithName:font._name size:font._size + 2];
    [textField setValue:font forThemeAttribute:@"font"];
    [textField setStringValue:text];
    [textField sizeToFit];

    return textField;
}

- (void)_addOption:(id)sender
{
    if (_rowIndex == [_ruleEditor numberOfRows] - 1)
        [self setNeedsDisplay:YES];

    var type = _plusButtonRowType;
    if ([_ruleEditor nestingMode] == CPRuleEditorNestingModeCompound && ([[CPApp currentEvent] modifierFlags] & CPAlternateKeyMask))
        type = CPRuleEditorRowTypeCompound;

    [_ruleEditor _addOptionFromSlice:self ofRowType:type];
}

- (void)_deleteOption:(id)sender
{
    [_ruleEditor _deleteSlice:self];
}

- (void)_ruleOptionPopupChangedAction:(CPMenuItem )sender
{
    var layoutdict = [sender representedObject],
        newItem = [layoutdict objectForKey:@"item"],
        indexInCriteria = [[layoutdict objectForKey:@"indexInCriteria"] intValue],
        oldItem = [_correspondingRuleItems objectAtIndex:indexInCriteria];

    if (newItem != oldItem)
    {
        [_correspondingRuleItems replaceObjectAtIndex:indexInCriteria withObject:newItem];
        [_ruleEditor _changedItem:oldItem toItem:newItem inRow:_rowIndex atCriteriaIndex:indexInCriteria];
    }
}

- (BOOL)validateMenuItem:(CPMenuItem )menuItem
{
    return [_ruleEditor _validateItem:menuItem value:[[menuItem representedObject] valueForKey:@"item"] inRow:_rowIndex];
}

- (void)_emptyRulePartSubviews
{
    var count = [_ruleOptionViews count];

    while (count--)
        [_ruleOptionViews[count] removeFromSuperview];

    [_ruleOptionViews removeAllObjects];
    [_ruleOptionFrames removeAllObjects];
    [_ruleOptionInitialViewFrames removeAllObjects];
}

- (void)_reconfigureSubviews
{
    var numItems;
        currentItem = nil,
        optionView = nil,
        indexInCriteria = 0,

        rowtype = [_ruleEditor rowTypeForRow:_rowIndex],
        displayValues = [_ruleEditor displayValuesForRow:_rowIndex];

    [self _emptyRulePartSubviews];
    [_correspondingRuleItems removeAllObjects];

    while ((numItems = [_ruleEditor _queryNumberOfChildrenOfItem:currentItem withRowType:rowtype]) > 0)
    {
        var isCustomRightControl = NO;
            isStaticTextField = NO,
            isPopupMenu = NO,
            isMultiValue = numItems > 1,
            selectedMenuItemIndex = 0,
            selectedItem = nil,
            current_display_value = nil,

            itemsArray = [CPMutableArray array],
            display_value_cached = [displayValues objectAtIndex:indexInCriteria];

        for (var childIndex = 0; childIndex < numItems; childIndex++)
        {
            var childItem = [_ruleEditor _queryChild:childIndex ofItem:currentItem withRowType:rowtype];
            current_display_value = [_ruleEditor _queryValueForItem:childItem inRow:_rowIndex];

            if (isMultiValue)
            {
                var menuItem;

                if ([current_display_value isKindOfClass:[CPString class]])
                    menuItem = [self _createMenuItemWithTitle:current_display_value];
                else if ([current_display_value isKindOfClass:[CPMenuItem class]])
                    menuItem = current_display_value;
                else
                    [CPException raise:CPInternalInconsistencyException reason:@"Display value must be a string or a menu item"];

                var layoutDictionary = [CPDictionary dictionaryWithObjectsAndKeys:childItem, @"item", indexInCriteria, @"indexInCriteria"];

                [menuItem setAction:@selector(_ruleOptionPopupChangedAction:)];
                [menuItem setTarget:self];
                [menuItem setRepresentedObject:layoutDictionary];
                [menuItem setTag:indexInCriteria];

                [itemsArray addObject:menuItem];
                isPopupMenu = YES;

                if ((childIndex == numItems - 1 && selectedItem == nil)
                   || ([current_display_value isEqual:display_value_cached])
                   || ([current_display_value isKindOfClass:[CPView class]]
                       && [[current_display_value objectValue] isEqualTo:[display_value_cached objectValue]]))
                {
                    selectedItem = childItem;
                    selectedMenuItemIndex = childIndex;
                }
            }
            else if ([current_display_value isKindOfClass:[CPString class]])
            {
                isStaticTextField = YES;
                selectedItem = childItem;
                selectedMenuItemIndex =0;
            }
            else if ([current_display_value isKindOfClass:[CPView class]])
            {
                isCustomRightControl = YES;
                selectedItem = childItem;
                selectedMenuItemIndex = 0;
            } else
                [CPException raise:CPInternalInconsistencyException reason:@"Display value must be a string or a custom control"];
        }

        if (isPopupMenu)
        {
            optionView = [self _createPopUpButtonWithItems:itemsArray selectedItemIndex:selectedMenuItemIndex];
        }
        else if (isStaticTextField)
        {
            optionView = [self _createStaticTextFieldWithStringValue:[current_display_value description]];
        }
        else if (isCustomRightControl)
        {
            optionView = display_value_cached; //display_value_cached
            [optionView setTarget:self];
            [optionView setAction:@selector(_sendRuleAction:)];
            if ([optionView respondsToSelector:@selector(setEditable:)])
                [optionView setEditable:editable];
        }

        if (optionView)
        {
            [_ruleOptionViews addObject:optionView];
            [_ruleOptionInitialViewFrames addObject:[optionView frame]];
            [_ruleOptionFrames addObject:[optionView frame]];
        }

        [_correspondingRuleItems addObject:selectedItem];
        currentItem = selectedItem;
        indexInCriteria++;
    }

     [self _relayoutSubviewsWidthChanged:(CGRectGetWidth([self frame]) != [_ruleEditor rowHeight])];
}

- (void)layoutSubviews
{
    [self _relayoutSubviewsWidthChanged:YES];
}

- (void)_relayoutSubviewsWidthChanged:(BOOL)widthChanged
{
    var optionViewOriginX,
        rowHeight = [_ruleEditor rowHeight],
        count = [_ruleOptionViews count],
        sliceFrame = [self frame];

    if (widthChanged)
        optionViewOriginX = [self _leftmostViewFixedHorizontalPadding] + [self _indentationHorizontalPadding]*[self indentation];
    for (var i = 0; i < count; i++)
    {
        var ruleOptionView = _ruleOptionViews[i],
            optionFrame = _ruleOptionFrames[i],
            initialFrame = _ruleOptionInitialViewFrames[i];

        optionFrame.origin.y = (rowHeight - CGRectGetHeight(optionFrame))/2 - 2;
        if (widthChanged)
        {
            optionFrame.origin.x = optionViewOriginX;
            optionFrame.size.width = MIN(CGRectGetMinX(optionFrame) + CGRectGetWidth(initialFrame), CGRectGetMinX([_subtractButton frame]) - [self _rowButtonsLeftHorizontalPadding]) - CGRectGetMinX(optionFrame);
        }

        [ruleOptionView setFrame:optionFrame];
        [self addSubview:ruleOptionView];
        if (widthChanged)
            optionViewOriginX += CGRectGetWidth(optionFrame) + [self _interviewHorizontalPadding];
    }

    var buttonFrame = CGRectMake(CGRectGetWidth(sliceFrame) - BUTTON_HEIGHT - [self _rowButtonsRightHorizontalPadding], ([_ruleEditor rowHeight] - BUTTON_HEIGHT)/2 - 2, BUTTON_HEIGHT, BUTTON_HEIGHT);
    [_addButton setFrame:buttonFrame];

    buttonFrame.origin.x -= BUTTON_HEIGHT + [self _rowButtonsInterviewHorizontalPadding];
    [_subtractButton setFrame:buttonFrame];
}

- (void)_updateButtonVisibilities
{
    [_addButton setHidden:[_ruleEditor _shouldHideAddButtonForSlice:self]];
    [_subtractButton setHidden:[_ruleEditor _shouldHideSubtractButtonForSlice:self]];
}

- (void)_configurePlusButtonByRowType:(CPRuleEditorRowType)type
{
    [self _setRowTypeToAddFromPlusButton:type];
}

- (BOOL)isEditable
{
    return editable;
}

- (void)setEditable:(BOOL)value
{
    editable = value;
//  [self _updateEnabledStateForSubviews];
    [self _updateButtonVisibilities];
}

- (float)_alignmentGridWidth
{
    return [_ruleEditor _alignmentGridWidth];
}

- (float)_indentationHorizontalPadding
{
    return 30.;
}

- (float)_interviewHorizontalPadding
{
    return 6.;
}

- (float)_leftmostViewFixedHorizontalPadding
{
    return 7.;
}

- (float)_minimumVerticalPopupPadding
{
    return 2.;
}

- (float)_rowButtonsInterviewHorizontalPadding
{
    return 6.;
}

- (float)_rowButtonsLeftHorizontalPadding
{
    return 10.;
}

- (float)_rowButtonsRightHorizontalPadding
{
    return 10.;
}

- (void)_setRowTypeToAddFromPlusButton:(int)type
{
    _plusButtonRowType = type;
}

- (void)setNeedsDisplay:(BOOL)flag
{
    [super setNeedsDisplay:flag];
}

- (BOOL)_nestingModeShouldHideAddButton
{
    return [_ruleEditor _applicableNestingMode] == CPRuleEditorNestingModeSingle;
}

- (BOOL)_nestingModeShouldHideSubtractButton
{
    return [_ruleEditor _applicableNestingMode] == CPRuleEditorNestingModeSingle;
}

- (BOOL)containsDisplayValue:(id)value
{
    return [[_ruleEditor displayValuesForRow:_rowIndex] containsObject:value];
    // Ou alors avec _correspondingRuleItems
}

- (void)viewDidMoveToWindow
{
    [self layoutSubviews];
}

- (void)drawRect:(CPRect)rect
{
    [super drawRect:rect];
}

- (BOOL)_isRulePopup:(CPView)view
{
    if ([view isKindOfClass:[_CPRuleEditorPopUpButton class]])
        return YES;
    return NO;
}

- (BOOL)_isRuleStaticTextField:(CPView)view
{
    if ([view isKindOfClass:[_CPRuleEditorTextField class]])
        return YES;
    return NO;
}

- (void)_sendRuleAction:(id)sender
{
    [_ruleEditor _sendRuleAction];
}

- (void)_textDidChange:(CPNotification)aNotif
{
    if ([[aNotif object] superview] == self)
        [_ruleEditor _sendRuleAction];
}

/*
- (BOOL)_dropsIndentWhenImmediatelyBelow
{
}
- (double)_minWidthForPass:(int)pass forView:(id)view withProposedMinWidth:(double)minWidth
{
}
- (id)_sortOptionDictionariesByLayoutOrder:(id)fp8
{
}
- (void)_setHideNonPartDrawing:(BOOL)value
{
}
- (void)_tightenResizables:(id)fp8 intoGivenWidth:(double)fp12
{
}
- (void)_updateEnabledStateForSubviews
{
}
*/

@end

@implementation _CPRuleEditorTextField : CPTextField
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        [self setBordered:NO];
        [self setEditable:NO];
        [self setDrawsBackground:NO];
    }

    return self;
}

- (id)hitTest:(CPPoint)point
{
    if (!CPRectContainsPoint([self frame], point))
        return nil;

    return [self superview];
}

@end