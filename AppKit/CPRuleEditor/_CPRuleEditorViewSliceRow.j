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
    //[_addButton setToolTip:[_ruleEditor _toolTipForAddSimpleRowButton]];
    //[_subtractButton setToolTip:[_ruleEditor _toolTipForDeleteRowButton]];
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
    var mItem = [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    return mItem;
}

- (CPPopUpButton)_createPopUpButtonWithItems:(CPArray)itemsArray selectedItemIndex:(int)index
{
    var title = [[itemsArray objectAtIndex:index] title];
    var font = [_ruleEditor font],
        width = [title sizeWithFont:font].width + 20,
        rect = CGRectMake(0, 0, (width - width % 40) + 80, CONTROL_HEIGHT);

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
        indexInCriteria = [layoutdict objectForKey:@"indexInCriteria"],
        oldItem = [_correspondingRuleItems objectAtIndex:indexInCriteria];

    if (![newItem isEqual:oldItem])
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
    var ruleItems,
        criteria,
        repObject,
        menuItem,
        ruleView,
        criterion,
        parent,
        numberOfCriteria,
        numberOfChildren,
        firstResponderIndex;

    var ruleItems = [CPMutableArray array];

    [self _emptyRulePartSubviews];

    criteria = [_ruleEditor criteriaForRow:_rowIndex];
    numberOfCriteria = [criteria count];

    firstResponderIndex = numberOfCriteria - 1;
    var responder = [[self window] firstResponder];
    if (responder)
        firstResponderIndex = [_ruleOptionViews indexOfObjectIdenticalTo:responder];

    for (var i = 0; i < numberOfCriteria; i++)
    {
        ruleView = nil;
        parent = nil;
        criterion = [criteria objectAtIndex:i];

        if (i > 0)
            parent = [criteria objectAtIndex:i - 1];

        var childItems = [],
            childValues = [];

        [_ruleEditor _getAllAvailableItems:childItems values:childValues asChildrenOfItem:parent inRow:_rowIndex];

        numberOfChildren = [childItems count];
        if (numberOfChildren > 1)
        {
            var menuItems = [CPMutableArray arrayWithCapacity:numberOfChildren];

            var selectedIndex = [childItems indexOfObject:criterion];
            if (selectedIndex == CPNotFound)
                break;

            for (var j = 0; j < numberOfChildren; ++j)
            {
                var childItem = [childItems objectAtIndex:j];
                var childValue = [childValues objectAtIndex:j];

                if ([childValue isKindOfClass:[CPMenuItem class]])
                {
                    [[childValue menu] removeItem:childValue];
                    menuItem = childValue;
                }
                else
                {
                    if ([childValue isEqualToString:@""])
                        menuItem = [self _createMenuSeparatorItem];
                    else
                    {
                        menuItem = [self _createMenuItemWithTitle:childValue];
                        [menuItem setTarget:self];
                        [menuItem setAction:@selector(_ruleOptionPopupChangedAction:)];
                    }
                }

                repObject = [CPDictionary dictionaryWithObjectsAndKeys:childItem, @"item", childValue, @"value", i, @"indexInCriteria"];
                [menuItem setRepresentedObject:repObject];
                [menuItems addObject:menuItem];
            }

            ruleView = [self _createPopUpButtonWithItems:menuItems selectedItemIndex:selectedIndex];
        }
        else
        {
            var value = [childValues objectAtIndex:0];
            var type = [value valueType];

            if (type === 0)
                ruleView = [self _createStaticTextFieldWithStringValue:value];
            else
            {
                if (type !== 1)
                {
                    [CPException raise:CPInternalInconsistencyException reason:@"Display value must be a string or a menu item"];
                    continue;
                }

                ruleView = value;
                [ruleView setTarget:self];
                [ruleView setAction:@selector(_sendRuleAction:)];
                if ([ruleView respondsToSelector:@selector(setDelegate:)])
                    [ruleView setDelegate:self];
            }
        }

        if (ruleView != nil)
        {
            [_ruleOptionViews addObject:ruleView];
            var frame = [ruleView frame];
            [_ruleOptionInitialViewFrames addObject:frame];
            [_ruleOptionFrames addObject:frame];

            if (!criterion)
                criterion = [CPNull null];

            [ruleItems addObject:criterion];
        }
    }

    [_correspondingRuleItems setArray:ruleItems];

    if (!editable)
        [self _updateEnabledStateForSubviews];

    [self _relayoutSubviewsWidthChanged:YES];

    if (firstResponderIndex != CPNotFound)
    {
        var aView = [_ruleOptionViews objectAtIndex:firstResponderIndex];
        [[self window] makeFirstResponder:aView]; // This is not working. bug in CPPopUpButton firstResponder ?
    }

    //[self setNeedsDisplay:YES];
}

- (void)_updateEnabledStateForSubviews
{
    [_ruleOptionViews makeObjectsPerformSelector:@selector(setEnabled:) withObject:NO];
}

- (void)layoutSubviews
{
    // CPLogConsole(_cmd);
    [self _relayoutSubviewsWidthChanged:YES];
}

- (void)_relayoutSubviewsWidthChanged:(BOOL)widthChanged
{
    var optionViewOriginX,
        leftHorizontalPadding,
        leftButtonMinX,
        rowHeight = [_ruleEditor rowHeight],
        count = [_ruleOptionViews count],
        sliceFrame = [self frame];

    var buttonFrame = CGRectMake(CGRectGetWidth(sliceFrame) - BUTTON_HEIGHT - [self _rowButtonsRightHorizontalPadding], ([_ruleEditor rowHeight] - BUTTON_HEIGHT)/2 - 2, BUTTON_HEIGHT, BUTTON_HEIGHT);
    [_addButton setFrame:buttonFrame];

    buttonFrame.origin.x -= BUTTON_HEIGHT + [self _rowButtonsInterviewHorizontalPadding];
    [_subtractButton setFrame:buttonFrame];

    if (widthChanged)
    {
        optionViewOriginX = [self _leftmostViewFixedHorizontalPadding] + [self _indentationHorizontalPadding] * _indentation;
        leftHorizontalPadding = [self _rowButtonsLeftHorizontalPadding];
        leftButtonMinX = CGRectGetMinX(buttonFrame);
    }

    for (var i = 0; i < count; i++)
    {
        var ruleOptionView = _ruleOptionViews[i],
            optionFrame = _ruleOptionFrames[i];

        optionFrame.origin.y = (rowHeight - CGRectGetHeight(optionFrame))/2 - 2;
        if (widthChanged)
        {
            optionFrame.origin.x = optionViewOriginX;
            if (i == count - 1 && ![self _isRulePopup:ruleOptionView])
            {
                var initialFrame = _ruleOptionInitialViewFrames[i];
                optionFrame.size.width = MIN(CGRectGetWidth(initialFrame), leftButtonMinX - leftHorizontalPadding - optionViewOriginX);
            }
        }

        [ruleOptionView setFrame:optionFrame];
        [self addSubview:ruleOptionView];

        if (widthChanged)
            optionViewOriginX += CGRectGetWidth(optionFrame) + [self _interviewHorizontalPadding];
    }
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
    if ([[aNotif object] superview] == self && [_ruleEditor _sendsActionOnIncompleteTextChange])
        [_ruleEditor _sendRuleAction];
}

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
