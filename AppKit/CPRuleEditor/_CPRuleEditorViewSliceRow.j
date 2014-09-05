/*
 * Created by cacaodev@gmail.com.
 * Copyright (c) 2011 Pear, Inc. All rights reserved.
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

@import "CPRuleEditor_Constants.j"
@import "_CPRuleEditorViewSlice.j"

@import "CPButton.j"
@import "CPDatePicker.j"
@import "CPPopUpButton.j"

@global CPApp
@global CPMiniControlSize
@global CPSmallControlSize

@implementation _CPRuleEditorViewSliceRow : _CPRuleEditorViewSlice
{
    CPButton                _addButton;
    CPButton                _subtractButton;
    CPMutableArray          _correspondingRuleItems;
    CPMutableArray          _ruleOptionFrames;
    CPMutableArray          _ruleOptionInitialViewFrames;
    CPMutableArray          _ruleOptionViews;


    CPRuleEditorRowType     _rowType @accessors;
    CPRuleEditorRowType     _plusButtonRowType;
}

- (id)initWithFrame:(CGRect)frame ruleEditorView:(id)editor
{
    if (self = [super initWithFrame:frame ruleEditorView:editor])
        [self _initShared];

    return self;
}

- (void)_initShared
{
    _correspondingRuleItems         = [[CPMutableArray alloc] init];
    _ruleOptionFrames               = [[CPMutableArray alloc] init];
    _ruleOptionInitialViewFrames    = [[CPMutableArray alloc] init];
    _ruleOptionViews                = [[CPMutableArray alloc] init];
    _editable                       = [_ruleEditor isEditable];

    _addButton                      = [self _createAddRowButton];
    _subtractButton                 = [self _createDeleteRowButton];

    [self addSubview:_addButton];
    [self addSubview:_subtractButton];

    [self setAutoresizingMask:CPViewWidthSizable];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_textDidChange:) name:CPControlTextDidChangeNotification object:nil];
}

- (CPButton)_createRowButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    [button setFont:[_ruleEditor font]];
    [button setTextColor:[_ruleEditor _fontColor]];

    [button setAlignment:CPCenterTextAlignment];
    [button setAutoresizingMask:CPViewMinXMargin];
    [button setButtonType:CPMomentaryChangeButton];
    [button setBordered:NO];
    [button setHidden:!_editable];
    [button setImagePosition:CPImageOnly];

    return button;
}

- (CPButton)_createAddRowButton
{
    var button = [self _createRowButton];

    [button setToolTip:[_ruleEditor _toolTipForAddSimpleRowButton]];
    [button setValue:[_ruleEditor _imageAdd] forThemeAttribute:@"image" inState:CPThemeStateNormal];
    [button setValue:[_ruleEditor _imageAddHighlighted] forThemeAttribute:@"image" inState:CPThemeStateHighlighted];

    [button setAction:@selector(_addOption:)];
    [button setTarget:self];

    return button;
}

- (CPButton)_createDeleteRowButton
{
    var button = [self _createRowButton];

    [button setToolTip:[_ruleEditor _toolTipForDeleteRowButton]];
    [button setValue:[_ruleEditor _imageRemove] forThemeAttribute:@"image" inState:CPThemeStateNormal];
    [button setValue:[_ruleEditor _imageRemoveHighlighted] forThemeAttribute:@"image" inState:CPThemeStateHighlighted];

    [button setAction:@selector(_deleteOption:)];
    [button setTarget:self];

    return button;
}

- (CPMenuItem)_createMenuItemWithTitle:(CPString )title
{
    title = [[_ruleEditor standardLocalizer] localizedStringForString:title];
    return [[CPMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
}

- (CPPopUpButton)_createPopUpButtonWithItems:(CPArray)itemsArray selectedItemIndex:(int)index
{
    var title   = [[itemsArray objectAtIndex:index] title],
        font    = [_ruleEditor font],
        width   = [title sizeWithFont:font].width + 20,
        rect    = CGRectMake(0, 0, (width - width % 40) + 80, [_ruleEditor rowHeight]),
        popup   = [[CPPopUpButton alloc] initWithFrame:rect];

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

- (CPTextField)_createStaticTextFieldWithStringValue:(CPString)text
{
    var textField       = [[CPTextField alloc] initWithFrame:CGRectMakeZero()],
        ruleEditorFont  = [_ruleEditor font],
        font            = [CPFont fontWithName:[ruleEditorFont familyName] size:[ruleEditorFont size] + 2],
        localizedText   = [[_ruleEditor standardLocalizer] localizedStringForString:text],
        size            = [localizedText sizeWithFont:font];

    [textField setFrameSize:CGSizeMake(size.width + 4, [_ruleEditor rowHeight])];
    [textField setValue:font forThemeAttribute:@"font"];
    [textField setValue:[_ruleEditor _verticalAlignment] forThemeAttribute:@"vertical-alignment"];
    [textField setStringValue:localizedText];

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

- (void)_ruleOptionPopupChangedAction:(CPMenuItem)sender
{
    var layoutdict      = [sender representedObject],
        newItem         = [layoutdict objectForKey:@"item"],
        indexInCriteria = [layoutdict objectForKey:@"indexInCriteria"],
        oldItem         = [_correspondingRuleItems objectAtIndex:indexInCriteria];

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
        firstResponderIndex,

        ruleItems = [CPMutableArray array],
        responder = [[self window] firstResponder];

    [self _emptyRulePartSubviews];

    criteria = [_ruleEditor criteriaForRow:_rowIndex];
    numberOfCriteria = [criteria count];

    firstResponderIndex = numberOfCriteria - 1;
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
            var menuItems = [CPMutableArray arrayWithCapacity:numberOfChildren],
                selectedIndex = [childItems indexOfObject:criterion];

            if (selectedIndex == CPNotFound)
                break;

            for (var j = 0; j < numberOfChildren; ++j)
            {
                var childItem = [childItems objectAtIndex:j],
                    childValue = [childValues objectAtIndex:j];

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

                repObject = @{
                        @"item": childItem,
                        @"value": childValue,
                        @"indexInCriteria": i
                    };
                [menuItem setRepresentedObject:repObject];
                [menuItems addObject:menuItem];
            }

            ruleView = [self _createPopUpButtonWithItems:menuItems selectedItemIndex:selectedIndex];
        }
        else
        {
            var value = [childValues objectAtIndex:0],
                type = [value valueType];

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
            [ruleView setControlSize:CPSmallControlSize];

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

    if (!_editable)
        [self _updateEnabledStateForSubviews];

    [self _relayoutSubviewsWidthChanged:YES];

    if (firstResponderIndex != CPNotFound)
    {
        var aView = [_ruleOptionViews objectAtIndex:firstResponderIndex];
        [[self window] makeFirstResponder:aView]; // This is not working. bug in CPPopUpButton firstResponder ?
    }
}

- (void)_updateEnabledStateForSubviews
{
    [_ruleOptionViews makeObjectsPerformSelector:@selector(setEnabled:) withObject:NO];
}

- (void)layoutSubviews
{
    [self _relayoutSubviewsWidthChanged:YES];
}

- (void)_relayoutSubviewsWidthChanged:(BOOL)widthChanged
{
    var optionViewOriginX,
        leftHorizontalPadding,
        leftButtonMinX,
        rowHeight   = [_ruleEditor rowHeight],
        count       = [_ruleOptionViews count],
        sliceFrame  = [self frame],
        image       = [_ruleEditor _imageAdd],

        buttonFrame = CGRectMake(CGRectGetWidth(sliceFrame) - [image size].width - [self _rowButtonsRightHorizontalPadding], ([_ruleEditor rowHeight] - [image size].height) / 2 - 1, [image size].width, [image size].height);

    [_addButton setFrame:buttonFrame];
    buttonFrame.origin.x -= [image size].width + [self _rowButtonsInterviewHorizontalPadding];
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

        // Use a pixel correction to align controls
        optionFrame.origin.y = (rowHeight - CGRectGetHeight(optionFrame)) / 2;

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

- (void)setEditable:(BOOL)value
{
    [super setEditable:value]
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
    return ([[_ruleEditor superview] isKindOfClass:[CPClipView class]]) ? 18. : 10.;
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

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (BOOL)_isRulePopup:(CPView)view
{
    if ([view isKindOfClass:[CPPopUpButton class]])
        return YES;

    return NO;
}

- (void)_sendRuleAction:(id)sender
{
    [_ruleEditor _updatePredicate];
    [_ruleEditor _sendRuleAction];
}

- (void)_textDidChange:(CPNotification)aNotif
{
    if ([[aNotif object] superview] == self && [_ruleEditor _sendsActionOnIncompleteTextChange])
        [self _sendRuleAction:nil];
}

@end