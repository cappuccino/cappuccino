/*
 * CPButtonBar.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * Adapted by Didier Korthoudt
 * Copyright 2019, Cappuccino Project.
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

@import "CPView.j"
@import "CPWindow_Constants.j"
@import "CPButton.j"
@import "CPPopUpButton.j"
@import "CPSearchField.j"

@class CPSplitView

@global CPPopUpButtonStatePullsDown
@global CPKeyValueChangeOldKey
@global CPKeyValueChangeNewKey
@global CPKeyValueObservingOptionNew
@global CPKeyValueObservingOptionOld

var SharedDummyButtonBar = nil;

@typedef CPButtonBarStyle
CPButtonBarLegacyStyle = 1;
CPButtonBarModernStyle = 2;
CPButtonBarSmoothStyle = 3;

@typedef CPTemplateImage
CPAddTemplateImage    = @"CPAddTemplate";
CPRemoveTemplateImage = @"CPRemoveTemplate";
CPActionTemplateImage = @"CPActionTemplate";

var _templateImageMap = @{
                          CPAddTemplateImage:    @"button-image-plus",
                          CPRemoveTemplateImage: @"button-image-minus",
                          CPActionTemplateImage: @"button-image-action"
                          };

var CPButtonBarPopulateButtonBarSelector           = 1 << 1;

@protocol CPButtonBarDelegate <CPObject>

@optional
- (void)populateButtonBar:(CPButtonBar)buttonBar;

@end

#pragma mark -

@implementation CPButtonBar : CPView
{
    CPArray             _buttons;
    CPMutableArray      _dividers;
    CPMutableArray      _flexibles;
    CPButtonBarStyle    _style;

    BOOL                _buttonsAreBordered;
    BOOL                _drawsSeparator;
    BOOL                _isTransparent;
    BOOL                _needsToLoadThemeValues;
    BOOL                _needsToComputeNeededSpace;
    CGSize              _buttonsSize;
    int                 _spacing;
    CPInteger           _buttonVerticalOffset;
    CPColor             _dividerColor;
    CPColor             _bezelColor;
    int                 _flexibleSpacesCount;
    int                 _neededWidth;
    int                 _flexibleCount;
    int                 _flexibleDelta;
    CPMutableArray      _flexibleDeltas;
    CGSize              _resizeControlViewSize;
    CGInset             _resizeControlViewInset;
    CPColor             _resizeControlViewBackground;

    BOOL                _automaticResizeControl;
    BOOL                _hasLeftResizeControl;
    BOOL                _hasRightResizeControl;

    id <CPButtonBarDelegate>    _delegate;
    unsigned                    _delegateSelectors;
}

#pragma mark -
#pragma mark Class methods

+ (CPString)defaultThemeClass
{
    return @"button-bar";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"resize-control-inset": CGInsetMake(0.0, 0.0, 0.0, 0.0),
             @"resize-control-size": CGSizeMakeZero(),
             @"resize-control-color": [CPNull null],
             @"bezel-color": [CPNull null],
             @"button-bezel-color": [CPNull null],
             @"button-text-color": [CPNull null],
             @"button-image-plus": [CPNull null],
             @"button-image-minus": [CPNull null],
             @"button-image-action": [CPNull null],

             // For compatibility with Aristo2
             @"button-vertical-offset": 1,
             @"bordered-buttons": YES,
             @"button-size": CGSizeMake(35.0, 25.0),
             @"spacing-size": CGSizeMake(0.0, 25.0),
             @"divider-color": [CPNull null],
             @"draws-separator": YES,
             @"is-transparent": NO,
             @"min-size": CGSizeMake(0, 0),
             @"max-size": CGSizeMake(-1, -1),
             @"auto-resize-control": YES
             };
}

+ (CPButtonBar)_sharedDummyButtonBar
{
    if (!SharedDummyButtonBar)
    {
        SharedDummyButtonBar = [[CPButtonBar alloc] initWithFrame:CGRectMakeZero()];

        [SharedDummyButtonBar setTheme:[CPTheme defaultTheme]];
    }

    return SharedDummyButtonBar;
}

+ (id)plusButton
{
    CPLog.warn("[CPButtonBar plusButton] is deprecated, use -(id)plusButton instance method instead.");

    return [[CPButtonBar _sharedDummyButtonBar] plusButton];
}

+ (id)minusButton
{
    CPLog.warn("[CPButtonBar minusButton] is deprecated, use -(id)minusButton instance method instead.");

    return [[CPButtonBar _sharedDummyButtonBar] minusButton];
}

+ (id)actionPopupButton
{
    CPLog.warn("[CPButtonBar actionPopupButton] is deprecated, use -(id)actionPopupButton instance method instead.");

    return [[CPButtonBar _sharedDummyButtonBar] actionPopupButton];
}

#pragma mark -
#pragma mark Buttons constructors

- (id)buttonWithImage:(CPImage)image alternateImage:(CPImage)alternateImage
{
    return [[_CPButtonBarButton alloc] initWithImage:image alternateImage:alternateImage bordered:_buttonsAreBordered];
}

- (id)buttonWithTemplateImage:(CPTemplateImage)templateImage
{
    var attributeName  = [_templateImageMap valueForKey:templateImage],
        image          = [self valueForThemeAttribute:attributeName inState:CPThemeStateNormal],
        alternateImage = [self valueForThemeAttribute:attributeName inState:CPThemeStateHighlighted];

    return [self buttonWithImage:image alternateImage:alternateImage];
}

- (id)buttonWithMaterialIconNamed:(CPString)iconName
{
    var image          = [CPImage imageWithMaterialIconNamed:iconName size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,0.75)"]],
        alternateImage = [CPImage imageWithMaterialIconNamed:iconName size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,1.00)"]];

    return [self buttonWithImage:image alternateImage:alternateImage];
}

- (id)pulldownButtonWithImage:(CPImage)image alternateImage:(CPImage)alternateImage
{
    return [[_CPButtonBarPopUpButton alloc] initWithImage:image alternateImage:alternateImage];
}

- (id)pulldownButtonWithTemplateImage:(CPTemplateImage)templateImage
{
    var attributeName  = [_templateImageMap valueForKey:templateImage],
        image          = [self valueForThemeAttribute:attributeName inState:CPThemeStateNormal],
        alternateImage = [self valueForThemeAttribute:attributeName inState:CPThemeStateHighlighted];

    return [self pulldownButtonWithImage:image alternateImage:alternateImage];
}

- (id)pulldownButtonWithMaterialIconNamed:(CPString)iconName
{
    var image          = [CPImage imageWithMaterialIconNamed:iconName size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,0.75)"]],
        alternateImage = [CPImage imageWithMaterialIconNamed:iconName size:CGSizeMake(16,16) color:[CPColor colorWithCSSString:@"rgba(0,0,0,1.00)"]];

    return [self pulldownButtonWithImage:image alternateImage:alternateImage];
}

- (id)pulldownButtonWithTitle:(CPString)aTitle
{
    return [[_CPButtonBarAdaptativePullDownButton alloc] initWithTitle:aTitle];
}

- (id)popUpButton
{
    return [[_CPButtonBarAdaptativePopUpButton alloc] initWithFrame:CGRectMakeZero()];
}

- (id)searchFieldWithPlaceholder:(CPString)placeholder minWidth:(int)minWidth maxWidth:(int)maxWidth
{
    return [[_CPButtonBarSearchField alloc] initWithPlaceholder:placeholder minWidth:minWidth maxWidth:maxWidth];
}

- (id)separator
{
    return [[_CPButtonBarSeparator alloc] initWithBordered:_drawsSeparator];
}

- (id)flexibleSpace
{
    return [[_CPButtonBarFlexibleSpace alloc] initWithFrame:CGRectMakeZero()];
}

- (id)labelWithTitle:(CPString)aTitle
{
    return [[_CPButtonBarLabel alloc] initWithTitle:aTitle];
}

- (id)labelWithTitle:(CPString)aTitle width:(int)aWidth
{
    return [[_CPButtonBarLabel alloc] initWithTitle:aTitle width:aWidth];
}

- (id)adaptativeLabelWithTitle:(CPString)aTitle
{
    return [[_CPButtonBarAdaptativeLabel alloc] initWithTitle:aTitle];
}

#pragma mark -
#pragma mark Backward compatibility

- (id)plusButton
{
    return [self buttonWithTemplateImage:CPAddTemplateImage];
}

- (id)minusButton
{
    return [self buttonWithTemplateImage:CPRemoveTemplateImage];
}

- (id)actionPopupButton
{
    return [self pulldownButtonWithTemplateImage:CPActionTemplateImage];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _buttons               = @[];
        _dividers              = @[];
        _flexibles             = @[];
        _flexibleSpacesCount   = 0;
        _neededWidth           = 0;
        _flexibleCount         = 0;
        _flexibleDelta         = 0;
        _flexibleDeltas        = @[];
        _hasLeftResizeControl  = NO;
        _hasRightResizeControl = NO;

        // Get default layout attributes
        [self setButtonsAreBordered:    [self currentValueForThemeAttribute:@"bordered-buttons"]];
        [self setDrawsSeparator:        [self currentValueForThemeAttribute:@"draws-separator"]];
        [self setIsTransparent:         [self currentValueForThemeAttribute:@"is-transparent"]];
        [self setAutomaticResizeControl:[self currentValueForThemeAttribute:@"auto-resize-control"]]

        // Adapt the height of the button bar if needed
        var minSize   = [self currentValueForThemeAttribute:@"min-size"],
            maxSize   = [self currentValueForThemeAttribute:@"max-size"],
            frameSize = aFrame.size;

        if (minSize.height > 0)
        {
            frameSize.height = MAX(minSize.height, frameSize.height);

            if (maxSize.height > 0)
                frameSize.height = MIN(maxSize.height, frameSize.height);
        }

        [self setFrameSize:frameSize];
        [self setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

        // This is needed when compiling themes
        [self _loadThemeValues];

        [self setNeedsLayout:YES];
    }

    return self;
}

- (void)_loadThemeValues
{
    _bezelColor                  = [self currentValueForThemeAttribute:@"bezel-color"];
    _spacing                     = [self currentValueForThemeAttribute:@"spacing-size"].width;
    _dividerColor                = [self currentValueForThemeAttribute:@"divider-color"];
    _buttonVerticalOffset        = [self currentValueForThemeAttribute:@"button-vertical-offset"];
    _resizeControlViewBackground = [self currentValueForThemeAttribute:@"resize-control-color"];
    _resizeControlViewSize       = [self currentValueForThemeAttribute:@"resize-control-size"];
    _resizeControlViewInset      = [self currentValueForThemeAttribute:@"resize-control-inset"];

    [self setBackgroundColor:_bezelColor];

    _needsToLoadThemeValues    = NO;
    _needsToComputeNeededSpace = YES;
}

- (void)awakeFromCib
{
    [super awakeFromCib];
    [self _connectToSplitView];
}

- (void)_connectToSplitView
{
    var view = [self superview],
        subview = self;

    while (view)
    {
        if ([view isKindOfClass:[CPSplitView class]])
        {
//            // ATTENTION !
//            // If the button bar is created via IB, at this moment, the split view may not be ready : subviews are OK but
//            // not arrangedSubviews. We can then assume that all subviews will be arranged subviews (as subviews declared
//            // in IB are, in fact, arranged subviews).
//            // BUT if the split view is ready, when must work on arranged subviews.
//            //
//            // To determine if the split view is ready, we have to make an hypothesis :
//            //      if the number of subviews > 0 and the number of arranged subviews = 0, then the split view is not ready
//            //
//            // This hypothesis could be false if the split view doesn't arrange all subviews and if all subviews are not
//            // arranged subviews. BUT this would mean that the split view has no real panes. And this should never happen
//            // in real life.
//
//            var arrangedSubviews      = [view arrangedSubviews],
//                arrangedSubviewsCount = [arrangedSubviews count],
//                subviews              = [view subviews],
//                subviewsCount         = [subviews count],
//                splitViewIsNotReady   = (subviewsCount > 0) && (arrangedSubviewsCount == 0),
//                viewIndex             = [(splitViewIsNotReady ? subviews : arrangedSubviews) indexOfObject:subview],
//                dividerIndex          = (viewIndex < (splitViewIsNotReady ? subviewsCount : arrangedSubviewsCount) - 1) ? viewIndex : MAX(viewIndex - 1, 0);
//
//            [view setButtonBar:self forDividerAtIndex:dividerIndex addResizeControl:_automaticResizeControl];

            [view attachButtonBar:self];
            break;
        }

        subview = view;
        view = [view superview];
    }
}

#pragma mark -
#pragma mark Properties

- (void)setStyle:(CPButtonBarStyle)style
{
    if (_style == style)
        return;

    switch (style) {
        case CPButtonBarLegacyStyle:
            [self setButtonsAreBordered:YES];
            [self setDrawsSeparator:YES];
            [self setIsTransparent:NO];
            break;

        case CPButtonBarModernStyle:
            [self setButtonsAreBordered:NO];
            [self setDrawsSeparator:YES];
            [self setIsTransparent:NO];
            break;

        case CPButtonBarSmoothStyle:
            [self setButtonsAreBordered:NO];
            [self setDrawsSeparator:NO];
            [self setIsTransparent:YES];
            break;

        default:
            break;
    }

    _style = style;

    // If we already have buttons (surely a live style change), we have to
    // reload them in order to have correct behaviors
    if ([_buttons count] > 0)
        [self _sendDelegatePopulateButtonBar];

    [self setNeedsRelayout:YES];
}

- (void)setButtons:(CPArray)buttons
{
    for (var i = [_buttons count] - 1; i >= 0; i--)
    {
        [_buttons[i] removeFromSuperview];
        [_buttons[i] removeObserver:self forKeyPath:@"hidden"];
        [_dividers[i] removeFromSuperview];
    }

    _buttons             = @[];
    _dividers            = @[];
    _flexibles           = @[];
    _flexibleSpacesCount = 0;

    for (var i = 0, count = [buttons count]; i < count; i++)
        [self addButton:buttons[i]];

    [self setNeedsRelayout:YES];
}

- (void)addButton:(id)button
{
    if (![button respondsToSelector:@selector(isButtonBarItem)])
    {
        CPLog.error("CPButtonBar: Only regular CPButtonBar items are allowed (trying to add "+[button class]+")");
        return;
    }

    [_buttons addObject:button];
    [button addObserver:self forKeyPath:@"hidden" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:nil];
    [button setBordered:_buttonsAreBordered];
    [self addSubview:button];

    // Add a corresponding divider
    var newDivider = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [_dividers addObject:newDivider];
    [newDivider setBackgroundColor:_dividerColor];
    [self addSubview:newDivider];

    // Is this a flexible space ?
    if ([button isKindOfClass:_CPButtonBarFlexibleSpace])
        _flexibleSpacesCount++;

    // Is this a flexible item (other than space)
    else if ([button isFlexible])
        [_flexibles addObject:button];

    [self setNeedsRelayout:YES];
}

- (CPArray)buttons
{
    return [CPArray arrayWithArray:_buttons];
}

- (void)setButtonsAreBordered:(BOOL)shouldBeBordered
{
    if (_buttonsAreBordered === shouldBeBordered)
        return;

    _buttonsAreBordered = !!shouldBeBordered;

    if (_buttonsAreBordered)
        [self setThemeState:CPThemeStateBezeled];
    else
        [self unsetThemeState:CPThemeStateBezeled];

    [self _loadThemeValues];

    // Update buttons
    for (var i = 0, count = [_buttons count]; i < count; i++)
    {
        [_buttons[i] setBordered:_buttonsAreBordered];
        [_buttons[i] _initThemedValues];
    }

    var useDividers = _buttonsAreBordered && !!_dividerColor;

    // Adapt dividers
    for (var i = 0, count = [_dividers count]; i < count; i++)
    {
        [_dividers[i] setBackgroundColor:_dividerColor];
        [_dividers[i] setHidden:!useDividers];
    }

    [self setNeedsRelayout:YES];
}

- (BOOL)buttonsAreBordered
{
    return _buttonsAreBordered;
}

- (void)setButtonsSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_buttonsSize, aSize))
        return;

    CPLog.warn("-setButtonsSize is deprecated, please avoid using it.");

    _buttonsSize = aSize;

    // Update existing buttons size
    for (var i = 0, count = [_buttons count]; i < count; i++)
        if ([_buttons[i] isKindOfClass:_CPButtonBarButton])
            [_buttons[i] setFrameSize:_buttonsSize];

    [self setNeedsRelayout:YES];
}

- (CGSize)buttonsSize
{
    return _buttonsSize
}

- (void)setDrawsSeparator:(BOOL)shouldDrawSeparator
{
    if (_drawsSeparator === shouldDrawSeparator)
        return;

    _drawsSeparator = !!shouldDrawSeparator;

    if (_drawsSeparator)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];

    _needsToLoadThemeValues = YES;
    [self setNeedsLayout:YES];
}

- (BOOL)drawsSeparator
{
    return _drawsSeparator;
}

- (void)setIsTransparent:(BOOL)shouldBeTransparent
{
    if (_isTransparent === shouldBeTransparent)
        return;

    _isTransparent = !!shouldBeTransparent;

    if (_isTransparent)
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];

    _needsToLoadThemeValues = YES;
    [self setNeedsLayout:YES];
}

- (BOOL)isTransparent
{
    return _isTransparent;
}

- (void)setHasResizeControl:(BOOL)shouldHaveResizeControl
{
    // For compatibility with previous implementation
    [self setAutomaticResizeControl:shouldHaveResizeControl];
}

- (BOOL)hasResizeControl
{
    return [self automaticResizeControl];
}

- (void)setResizeControlIsLeftAligned:(BOOL)shouldBeLeftAligned
{
    // For compatibility with previous implementation
    [self setHasLeftResizeControl:shouldBeLeftAligned];
    [self setHasRightResizeControl:!shouldBeLeftAligned];
}

- (BOOL)resizeControlIsLeftAligned
{
    return [self hasLeftResizeControl];
}

- (void)setAutomaticResizeControl:(BOOL)shouldAutomaticallyAddResizeControl
{
    if (_automaticResizeControl === shouldAutomaticallyAddResizeControl)
        return;

    _automaticResizeControl = !!shouldAutomaticallyAddResizeControl;

    if (_automaticResizeControl)
        [self _connectToSplitView];
}

- (BOOL)automaticResizeControl
{
    return _automaticResizeControl;
}

- (void)setHasLeftResizeControl:(BOOL)shouldHaveLeftResizeControl
{
    if (_hasLeftResizeControl == shouldHaveLeftResizeControl)
        return;

    _hasLeftResizeControl = shouldHaveLeftResizeControl;

    [self setNeedsRelayout:YES];
}

- (BOOL)hasLeftResizeControl
{
    return _hasLeftResizeControl;
}

- (void)setHasRightResizeControl:(BOOL)shouldHaveRightResizeControl
{
    if (_hasRightResizeControl == shouldHaveRightResizeControl)
        return;

    _hasRightResizeControl = shouldHaveRightResizeControl;

    [self setNeedsRelayout:YES];
}

- (BOOL)hasRightResizeControl
{
    return _hasRightResizeControl;
}

#pragma mark -
#pragma mark Layout

- (CGRect)leftResizeControlFrame
{
    if (!_hasLeftResizeControl)
        return CGRectMakeZero();

    return CGRectMake(0, 0, _resizeControlViewSize.width + _resizeControlViewInset.left + _resizeControlViewInset.right, _resizeControlViewSize.height + _resizeControlViewInset.top + _resizeControlViewInset.bottom);
}

- (CGRect)rightResizeControlFrame
{
    if (!_hasRightResizeControl)
        return CGRectMakeZero();

    var bounds = [self bounds];

    return CGRectMake(bounds.size.width - _resizeControlViewSize.width - _resizeControlViewInset.right - _resizeControlViewInset.left, 0, _resizeControlViewSize.width + _resizeControlViewInset.left + _resizeControlViewInset.right, _resizeControlViewSize.height + _resizeControlViewInset.top + _resizeControlViewInset.bottom);
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === @"left-resize-control-view")
    {
        return CGRectMake(_resizeControlViewInset.left, _resizeControlViewInset.top, _resizeControlViewSize.width, _resizeControlViewSize.height);
    }
    else if (aName === @"right-resize-control-view")
    {
        var bounds = [self bounds];

        return CGRectMake(bounds.size.width - _resizeControlViewSize.width - _resizeControlViewInset.right, _resizeControlViewInset.top, _resizeControlViewSize.width, _resizeControlViewSize.height);
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if ((aName === @"left-resize-control-view") || (aName === @"right-resize-control-view"))
        return [[CPView alloc] initWithFrame:CGRectMakeZero()];

    return [super createEphemeralSubviewNamed:aName];
}

- (void)setNeedsRelayout:(BOOL)needsRelayout
{
    _needsToComputeNeededSpace = needsRelayout;
    [self setNeedsLayout:needsRelayout];
}

- (void)_computeNeededSpace
{
    var useDividers            = _buttonsAreBordered && !!_dividerColor,
        buttonHorizontalOffset = (useDividers ? 0 : 1),
        bounds                 = [self bounds],
        frameWidth             = bounds.size.width,
        leftResizeRect         = _hasLeftResizeControl  ? [self leftResizeControlFrame]  : CGRectMakeZero(),
        rightResizeRect        = _hasRightResizeControl ? [self rightResizeControlFrame] : CGRectMakeZero(),
        leftResizeWidth        = leftResizeRect.size.width,
        rightResizeWidth       = rightResizeRect.size.width,
        currentButtonOffset    = _spacing - buttonHorizontalOffset,
        availableWidth         = frameWidth + 1 + buttonHorizontalOffset - leftResizeWidth - rightResizeWidth;

    _neededWidth    = currentButtonOffset;
    _flexibleDelta  = 0;
    _flexibleDeltas = @[];
    _flexibleCount  = 0;

    for (var i = 0, count = _buttons.length, button, width, delta; i < count; i++)
    {
        button = _buttons[i];

        // Skip hidden buttons and separators if buttons are bordered
        if ([button isHidden] || (_buttonsAreBordered && [button isKindOfClass:_CPButtonBarSeparator]))
            continue;

        if ([button isFlexible])
        {
            // This is a flexible item (space, search field, ...)
            width = [button minWidth];

            if (width > 0) // not a _CPButtonBarFlexibleSpace
            {
                // If maxWidth == -1, the item wants all the remaining space
                if ([button maxWidth] != -1)
                    _flexibleDelta += (delta = [button maxWidth] - width);
                else
                    delta = availableWidth;

                [_flexibleDeltas addObject:delta];
                _flexibleCount++;
            }
        }
        else
            // This is a fixed size item
            width = [button frame].size.width;

        _neededWidth += width + _spacing - buttonHorizontalOffset + 2 * [button extraSpacing];

        if (useDividers)
            _neededWidth += _spacing + 1;
    }

    _needsToComputeNeededSpace = NO;
}

- (void)layoutSubviews
{
    if (_needsToLoadThemeValues)
        [self _loadThemeValues];

    if (_needsToComputeNeededSpace)
        [self _computeNeededSpace];

    var useDividers            = _buttonsAreBordered && !!_dividerColor,
        buttonHorizontalOffset = (useDividers ? 0 : 1),
        bounds                 = [self bounds],
        height                 = bounds.size.height - 1,
        frameWidth             = bounds.size.width,
        leftResizeRect         = _hasLeftResizeControl  ? [self leftResizeControlFrame]  : CGRectMakeZero(),
        rightResizeRect        = _hasRightResizeControl ? [self rightResizeControlFrame] : CGRectMakeZero(),
        leftResizeWidth        = leftResizeRect.size.width,
        rightResizeWidth       = rightResizeRect.size.width,
        currentButtonOffset    = leftResizeWidth + _spacing - buttonHorizontalOffset,
        availableWidth         = frameWidth + 1 + buttonHorizontalOffset - leftResizeWidth - rightResizeWidth,
        flexibleSpaceWidth     = 0,
        remainingSpace         = availableWidth - _neededWidth,
        nbDividersToRemove     = 0;

    // If we can collapse dividers (avoiding double dividers), get back freed space
    if (useDividers && (remainingSpace < _flexibleDelta))
    {
        nbDividersToRemove = MIN(_flexibleSpacesCount, _flexibleDelta - remainingSpace);
        remainingSpace    += nbDividersToRemove;
    }

    if (remainingSpace > 0)
    {
        // Some space remains.

        // If we have flexible items (other than spaces), distribute remaining space
        if (_flexibleCount > 0)
        {
            // We first distribute to non "all space" items
            // flexibleDelta is the total needed extra space for non "all space" items

            var distributionRatio  = (_flexibleDelta > remainingSpace) ? remainingSpace / _flexibleDelta : 1.0,
                allSpaceItemsCount = 0;

            for (var i = 0, count = _flexibles.length, item, itemSize; i < count; i++)
            {
                item = _flexibles[i];

                if ([item maxWidth] != -1)
                    [item setFrameSize:CGSizeMake([item minWidth] + _flexibleDeltas[i] * distributionRatio, [item frameSize].height)];
                else
                    allSpaceItemsCount++;
            }

            remainingSpace -= _flexibleDelta;

            if ((remainingSpace > 0) && (allSpaceItemsCount > 0))
            {
                // Some space remains.
                // We now distribute it evenly to "all space" items

                var evenSpace = remainingSpace / allSpaceItemsCount;

                for (var i = 0, count = _flexibles.length, item; i < count; i++)
                {
                    item = _flexibles[i];

                    if ([item maxWidth] == -1)
                        [item setFrameSize:CGSizeMake([item minWidth] + evenSpace, [item frameSize].height)];
                }

                remainingSpace = 0;
            }
        }

        // If we have flexible space(s), distribute remaining space evenly
        if (_flexibleSpacesCount > 0)
            flexibleSpaceWidth = (remainingSpace > 0) ? remainingSpace / _flexibleSpacesCount : 0;
    }

    for (var i = 0, count = _buttons.length, button, width, extraSpace, buttonHeight; i < count; i++)
    {
        button = _buttons[i];

        // Skip separators if buttons are bordered
        if ([button isKindOfClass:_CPButtonBarSeparator])
            [button setHidden:_buttonsAreBordered];

        // Skip hidden buttons
        if ([button isHidden])
        {
            // We mask the related divider
            [_dividers[i] setHidden:YES];
            continue;
        }

        width        = ([button isKindOfClass:_CPButtonBarFlexibleSpace]) ? flexibleSpaceWidth : [button frame].size.width;
        extraSpace   = [button extraSpacing];
        buttonHeight = [button frame].size.height;

        // Avoid double separators if width = 0
        if ((width == 0) && (nbDividersToRemove > 0))
        {
            [_dividers[i] setHidden:YES];

            nbDividersToRemove--;
            continue;
        }

        currentButtonOffset += extraSpace;
        [button setFrame:CGRectMake(currentButtonOffset, _buttonVerticalOffset + (height - buttonHeight)/2, width, buttonHeight)];
        currentButtonOffset += width + _spacing - buttonHorizontalOffset + extraSpace;

        if (useDividers)
        {
            [_dividers[i] setFrame:CGRectMake(currentButtonOffset, 0, 1, height)];
            currentButtonOffset += _spacing + 1;
            [_dividers[i] setHidden:NO];
        }
    }

    if (_hasLeftResizeControl)
    {
        var resizeControlView = [self layoutEphemeralSubviewNamed:@"left-resize-control-view"
                                                       positioned:CPWindowAbove
                                  relativeToEphemeralSubviewNamed:nil];

        [resizeControlView setAutoresizingMask:CPViewMaxXMargin];
        [resizeControlView setBackgroundColor:_resizeControlViewBackground];
    }

    if (_hasRightResizeControl)
    {
        var resizeControlView = [self layoutEphemeralSubviewNamed:@"right-resize-control-view"
                                                       positioned:CPWindowAbove
                                  relativeToEphemeralSubviewNamed:nil];

        [resizeControlView setAutoresizingMask:CPViewMinXMargin];
        [resizeControlView setBackgroundColor:_resizeControlViewBackground];
    }
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if ([change objectForKey:CPKeyValueChangeOldKey] == [change objectForKey:CPKeyValueChangeNewKey])
        return;

    [self setNeedsRelayout:YES];
}

#pragma mark -
#pragma mark Delegate

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id <CPButtonBarDelegate>)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateSelectors = 0;

    if ([_delegate respondsToSelector:@selector(populateButtonBar:)])
    {
        _delegateSelectors |= CPButtonBarPopulateButtonBarSelector;

        if ([_buttons count] == 0)
            [_delegate populateButtonBar:self];
    }
}

- (void)_sendDelegatePopulateButtonBar
{
    if (_delegateSelectors & CPButtonBarPopulateButtonBarSelector)
        [_delegate populateButtonBar:self];
}

@end

#pragma mark -
#pragma mark CPCoding

var CPButtonBarHasLeftResizeControlKey       = @"CPButtonBarHasLeftResizeControlKey",
    CPButtonBarHasRightResizeControlKey      = @"CPButtonBarHasRightResizeControlKey",
    CPButtonBarAutomaticResizeControlKey     = @"CPButtonBarAutomaticResizeControlKey",
    CPButtonBarButtonsAreBorderedKey         = @"CPButtonBarButtonsAreBorderedKey",
    CPButtonBarDrawsSeparatorKey             = @"CPButtonBarDrawsSeparatorKey",
    CPButtonBarIsTransparentKey              = @"CPButtonBarIsTransparentKey",
    CPButtonBarButtonsKey                    = @"CPButtonBarButtonsKey",
    CPButtonBarDividersKey                   = @"CPButtonBarDividersKey",
    CPButtonBarFlexiblesKey                  = @"CPButtonBarFlexiblesKey",
    CPButtonBarFlexibleSpacesCountKey        = @"CPButtonBarFlexibleSpacesCountKey",
    CPButtonBarDelegateKey                   = @"CPButtonBarDelegateKey";

@implementation CPButtonBar (CPCoding)

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:  _hasLeftResizeControl       forKey:CPButtonBarHasLeftResizeControlKey];
    [aCoder encodeBool:  _hasRightResizeControl      forKey:CPButtonBarHasRightResizeControlKey];
    [aCoder encodeBool:  _automaticResizeControl     forKey:CPButtonBarAutomaticResizeControlKey];
    [aCoder encodeBool:  _buttonsAreBordered         forKey:CPButtonBarButtonsAreBorderedKey];
    [aCoder encodeBool:  _drawsSeparator             forKey:CPButtonBarDrawsSeparatorKey];
    [aCoder encodeBool:  _isTransparent              forKey:CPButtonBarIsTransparentKey];
    [aCoder encodeObject:_buttons                    forKey:CPButtonBarButtonsKey];
    [aCoder encodeObject:_dividers                   forKey:CPButtonBarDividersKey];
    [aCoder encodeObject:_flexibles                  forKey:CPButtonBarFlexiblesKey];
    [aCoder encodeInt:   _flexibleSpacesCount        forKey:CPButtonBarFlexibleSpacesCountKey];

    [aCoder encodeConditionalObject:_delegate        forKey:CPButtonBarDelegateKey];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _hasLeftResizeControl   = [aCoder decodeBoolForKey:CPButtonBarHasLeftResizeControlKey];
        _hasRightResizeControl  = [aCoder decodeBoolForKey:CPButtonBarHasRightResizeControlKey];
        _automaticResizeControl = [aCoder decodeBoolForKey:CPButtonBarAutomaticResizeControlKey];

        [self setButtonsAreBordered:!![aCoder decodeBoolForKey:CPButtonBarButtonsAreBorderedKey]];
        [self setDrawsSeparator:    !![aCoder decodeBoolForKey:CPButtonBarDrawsSeparatorKey]];
        [self setIsTransparent:     !![aCoder decodeBoolForKey:CPButtonBarIsTransparentKey]];

        _buttons                    = [aCoder decodeObjectForKey:CPButtonBarButtonsKey] || @[];
        _dividers                   = [aCoder decodeObjectForKey:CPButtonBarDividersKey] || @[];
        _flexibles                  = [aCoder decodeObjectForKey:CPButtonBarFlexiblesKey] || @[];
        _flexibleSpacesCount        = [aCoder decodeIntForKey:CPButtonBarFlexibleSpacesCountKey];

        [self setDelegate:[aCoder decodeObjectForKey:CPButtonBarDelegateKey]];

        [self setNeedsRelayout:YES];
    }

    return self;
}

@end

#pragma mark -
#pragma mark Adaptative Popup button

@implementation _CPButtonBarAdaptativePopUpButton : CPPopUpButton
{
    int     _extraSpacing       @accessors(readonly, property=extraSpacing);
}

+ (CPString)defaultThemeClass
{
    return "button-bar-adaptative-popup";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"extra-spacing": 0
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setBezelStyle:CPRegularSquareBezelStyle];
        [self setControlSize:CPSmallControlSize];

        [self _initThemedValues];
    }

    return self;
}

- (void)_initThemedValues
{
    // Get extra-spacing
    _extraSpacing = [self currentValueForThemeAttribute:@"extra-spacing"];
}

- (void)synchronizeTitleAndSelectedItem
{
    var item = [self selectedItem];

    [self _setImage:[item image]];
    [self _setTitle:([item isKindOfClass:_CPAdaptativeMenuItem] && [item shortTitle] ? [item shortTitle] : [item title])];

    // Adapt the width of the popup
    [self sizeToFit];
    [[self superview] setNeedsRelayout:YES];
}

- (void)_setImage:(CPImage)anImage
{
    var grannyMethod         = class_getInstanceMethod([[self superclass] superclass], @selector(setImage:)),
        grannyImplementation = method_getImplementation(grannyMethod);

    grannyImplementation(self, @selector(setImage:), anImage);
}

- (void)_setTitle:(CPString)aTitle
{
    var grannyMethod         = class_getInstanceMethod([[self superclass] superclass], @selector(setTitle:)),
        grannyImplementation = method_getImplementation(grannyMethod);

    grannyImplementation(self, @selector(setTitle:), aTitle);
}

- (CPMenuItem)addItemWithTitle:(CPString)aTitle shortTitle:(CPString)aShortTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    var item = [[_CPAdaptativeMenuItem alloc] initWithTitle:aTitle shortTitle:aShortTitle action:anAction keyEquivalent:aKeyEquivalent];

    [self addItem:item];

    return item;
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    [super setBordered:shouldBeBordered];

    [self _initThemedValues];
}

@end

#pragma mark -
#pragma mark Adaptative PullDown button

@implementation _CPButtonBarAdaptativePullDownButton : CPPopUpButton
{
    int     _extraSpacing       @accessors(readonly, property=extraSpacing);
    int     _minHeight;
}

+ (CPString)defaultThemeClass
{
    return "button-bar-adaptative-pulldown";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"extra-spacing": 0
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (id)initWithTitle:(CPString)aTitle
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        [self setBezelStyle:CPRegularSquareBezelStyle];
        [self setControlSize:CPSmallControlSize];
        [self setPullsDown:YES];

        [self _initThemedValues];

        [self setTitle:aTitle];
    }

    return self;
}

- (void)_initThemedValues
{
    _extraSpacing = [self currentValueForThemeAttribute:@"extra-spacing"];
    var minSize   = [self currentValueForThemeAttribute:@"min-size"] || CGSizeMakeZero();
    _minHeight    = minSize.height;
}

- (void)synchronizeTitleAndSelectedItem
{
    var item  = nil,
        items = [[self menu] itemArray];

    if ([items count] > 0)
        item = items[0];

    [self _setImage:[item image]];
    [self _setTitle:([item isKindOfClass:_CPAdaptativeMenuItem] && [item shortTitle] ? [item shortTitle] : [item title])];

    // Adapt the width of the popup
    [self sizeToFit];
    [[self superview] setNeedsRelayout:YES];
}

- (void)_setImage:(CPImage)anImage
{
    var grannyMethod         = class_getInstanceMethod([[self superclass] superclass], @selector(setImage:)),
        grannyImplementation = method_getImplementation(grannyMethod);

    grannyImplementation(self, @selector(setImage:), anImage);
}

- (void)_setTitle:(CPString)aTitle
{
    var grannyMethod         = class_getInstanceMethod([[self superclass] superclass], @selector(setTitle:)),
        grannyImplementation = method_getImplementation(grannyMethod);

    grannyImplementation(self, @selector(setTitle:), aTitle);
}

- (CPMenuItem)addItemWithTitle:(CPString)aTitle shortTitle:(CPString)aShortTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    var item = [[_CPAdaptativeMenuItem alloc] initWithTitle:aTitle shortTitle:aShortTitle action:anAction keyEquivalent:aKeyEquivalent];

    [self addItem:item];

    return item;
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    [super setBordered:shouldBeBordered];

    [self _initThemedValues];
}

- (void)sizeToFit
{
    // We have to adapt our width but keep our height
    [super sizeToFit];
    [self setFrameSize:CGSizeMake([self frameSize].width, _minHeight)];
}

@end

#pragma mark -
#pragma mark Menu item

@implementation _CPAdaptativeMenuItem : CPMenuItem
{
    CPString    _shortTitle     @accessors(property=shortTitle);
}

- (id)initWithTitle:(CPString)aTitle shortTitle:(CPString)aShortTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    self = [super initWithTitle:aTitle action:anAction keyEquivalent:aKeyEquivalent];

    if (self)
        _shortTitle = aShortTitle;

    return self;
}

@end

#pragma mark -
#pragma mark Separator

@implementation _CPButtonBarSeparator : _CPImageAndTextView

+ (CPString)defaultThemeClass
{
    return "button-bar-separator";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"image": [CPNull null]
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (int)extraSpacing
{
    return 0;
}

- (id)initWithBordered:(BOOL)isBordered
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        [self setBordered:isBordered];
        [self setImagePosition:CPImageOnly];

        [self _initThemedValues];
    }

    return self;
}

- (void)_initThemedValues
{
    var image = [self currentValueForThemeAttribute:@"image"],
        size  = image ? [image size] : CGSizeMakeZero();

    [self setFrameSize:size];
    [self setImage:image];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];
}

- (BOOL)isBordered
{
    return [self hasThemeState:CPThemeStateBordered];
}

@end

#pragma mark -
#pragma mark Flexible space

@implementation _CPButtonBarFlexibleSpace : CPView

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return YES;
}

- (int)extraSpacing
{
    return 0;
}

- (BOOL)isHidden
{
    return NO;
}

- (int)minWidth
{
    return 0;
}

- (int)maxWidth
{
    return -1;
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];
}

- (BOOL)isBordered
{
    return [self hasThemeState:CPThemeStateBordered];
}

- (void)_initThemedValues
{
    // Just for compatibility...
}

@end

#pragma mark -
#pragma mark Search field

@implementation _CPButtonBarSearchField : CPSearchField
{
    int     _minWidth           @accessors(property=minWidth);
    int     _maxWidth           @accessors(property=maxWidth);
    int     _extraSpacing       @accessors(readonly, property=extraSpacing);

    BOOL    _skipInitialFirstResponderCall;
}

+ (CPString)defaultThemeClass
{
    return "button-bar-searchfield";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"extra-spacing": 0
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return (_minWidth !== _maxWidth);
}

- (id)initWithPlaceholder:(CPString)placeholder minWidth:(int)minWidth maxWidth:(int)maxWidth
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        _minWidth = minWidth;
        _maxWidth = maxWidth;

        [self _initThemedValues];

        [self setPlaceholderString:placeholder];

        _skipInitialFirstResponderCall = YES;
    }

    return self;
}

- (void)_initThemedValues
{
    // Set height to the default height from theme
    [self setFrameSize:CGSizeMake(_minWidth, [self currentValueForThemeAttribute:@"min-size"].height)];

    // Disable the not editing / editing difference in layouts
    [self setValue:[self valueForThemeAttribute:@"search-button-rect-function" inStates:[CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]] forThemeAttribute:@"search-button-rect-function" inStates:[CPTextFieldStateRounded, CPThemeStateBezeled]];

    // Get extra-spacing
    _extraSpacing = [self currentValueForThemeAttribute:@"extra-spacing"];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    [super setBordered:shouldBeBordered];

    [self _initThemedValues];
}

- (BOOL)acceptsFirstResponder
{
    // When this search field is the first text field inserted in the view hierarchy of the window, it will be asked to be the first responder
    // of the window, and we don't want that. So we skip the first acceptsFirstResponder call.
    return _skipInitialFirstResponderCall ? (_skipInitialFirstResponderCall = NO) : [super acceptsFirstResponder];
}

- (void)mouseDown:(CPEvent)anEvent
{
    _skipInitialFirstResponderCall = NO;

    [super mouseDown:anEvent];
}

@end

#pragma mark -
#pragma mark Button

@implementation _CPButtonBarButton : CPButton

+ (CPString)defaultThemeClass
{
    return "button-bar-button";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"highlights-by": [CPNull null]
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (int)extraSpacing
{
    return 0;
}

- (id)initWithImage:(CPImage)image alternateImage:(CPImage)alternateImage bordered:(BOOL)isBordered
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        [self setBordered:isBordered];

        [self setImage:image];
        [self setAlternateImage:alternateImage];
        [self setImagePosition:CPImageOnly];

        [self _initThemedValues];
    }

    return self;
}

- (void)_initThemedValues
{
    var size         = [self currentValueForThemeAttribute:@"min-size"],
        highlightsBy = [self currentValueForThemeAttribute:@"highlights-by"];

    if (size)
        [self setFrameSize:size];

    if (highlightsBy)
        [self setHighlightsBy:highlightsBy];
}

@end

#pragma mark -
#pragma mark Popup

@implementation _CPButtonBarPopUpButton : CPPopUpButton

+ (CPString)defaultThemeClass
{
    return "button-bar-popup";
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (int)extraSpacing
{
    return 0;
}

- (id)initWithImage:(CPImage)image alternateImage:(CPImage)alternateImage
{
    self = [super initWithFrame:CGRectMakeZero() pullsDown:YES];

    if (self)
    {
        [self setControlSize:CPSmallControlSize];
        [self addItemWithTitle:nil];
        [[self lastItem] setImage:image];
        [self setImagePosition:CPImageOnly];
        [self setAlternateImage:alternateImage];
        [self setBezelStyle:CPRegularSquareBezelStyle];
        [self setShowsStateBy:CPContentsCellMask];

        [self _initThemedValues];
    }

    return self;
}

- (void)_initThemedValues
{
    [self setFrameSize:[self currentValueForThemeAttribute:@"min-size"]];
}

// We override CPButton layoutSubviews in order to display an alternate image when mouse is done on the button.
// This is needed as CPPopUpButton overrides setObjectValue, blocking setting the state of the button.
- (void)layoutSubviews
{
    var bezelColor = [self currentValueForThemeAttribute:@"bezel-color"];

    if ([bezelColor isCSSBased])
    {
        // CSS Styling
        // We don't need bezelView as we apply CSS styling directly on the button view itself

        [self setBackgroundColor:bezelColor];

        var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                                 positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:nil];
    }
    else if (bezelColor)
    {
        var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:@"content-view"];

        [bezelView setBackgroundColor:bezelColor];

        var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                                 positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:@"bezel-view"];
    }
    else
    {
        // As we have no bezelColor, we only need a contentView

        var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                                 positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:nil];
    }

    if (contentView)
    {
        var title = nil,
            image = nil;

        title = _title;
        image = [self currentValueForThemeAttribute:@"image"];

        [contentView setText:title];
        [contentView setImage:image];
        [contentView setImageOffset:[self currentValueForThemeAttribute:@"image-offset"]];

        [contentView setFont:[self font]]; //[self currentValueForThemeAttribute:@"font"]];
        [contentView setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
        [contentView setAlignment:[self currentValueForThemeAttribute:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemeAttribute:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemeAttribute:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
        [contentView setImagePosition:[self currentValueForThemeAttribute:@"image-position"]];
        [contentView setImageScaling:[self currentValueForThemeAttribute:@"image-scaling"]];
        [contentView setDimsImage:[self hasThemeState:CPThemeStateDisabled] && _imageDimsWhenDisabled];
    }
}

@end

#pragma mark -
#pragma mark Adaptative Label

@implementation _CPButtonBarAdaptativeLabel : CPTextField
{
    int     _extraSpacing       @accessors(readonly, property=extraSpacing);
}

+ (CPString)defaultThemeClass
{
    return "button-bar-adaptative-label";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"extra-spacing": 0
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (id)initWithTitle:(CPString)aTitle
{
    self = [_CPButtonBarAdaptativeLabel labelWithTitle:aTitle];

    if (self)
    {
        [self setControlSize:CPSmallControlSize];

        [self _initThemedValues];
        [self sizeToFit];
    }

    return self;
}

- (void)_initThemedValues
{
    // Get extra-spacing
    _extraSpacing = [self currentValueForThemeAttribute:@"extra-spacing"];
}

- (void)setStringValue:(CPString)aString
{
    [super setStringValue:aString];

    // Adapt the width of the label
    [self sizeToFit];
    [[self superview] setNeedsRelayout:YES];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    [super setBordered:shouldBeBordered];

    [self _initThemedValues];
}

@end

#pragma mark -
#pragma mark Label

@implementation _CPButtonBarLabel : CPTextField
{
    int     _extraSpacing       @accessors(readonly, property=extraSpacing);
}

+ (CPString)defaultThemeClass
{
    return "button-bar-label";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"extra-spacing": 0
             };
}

- (BOOL)isButtonBarItem
{
    return YES;
}

- (BOOL)isFlexible
{
    return NO;
}

- (id)initWithTitle:(CPString)aTitle
{
    self = [_CPButtonBarLabel labelWithTitle:aTitle];

    if (self)
    {
        [self setControlSize:CPSmallControlSize];
        [self setVerticalAlignment:CPCenterVerticalTextAlignment];

        [self _initThemedValues];
    }

    return self;
}

- (id)initWithTitle:(CPString)aTitle width:(int)aWidth
{
    self = [self labelWithTitle:aTitle];

    if (self)
        [self setFrameSize:CGSizeMake(aWidth, [self bounds].size.height)];

    return self;
}

- (void)_initThemedValues
{
    // Get extra-spacing
    _extraSpacing = [self currentValueForThemeAttribute:@"extra-spacing"];
}

- (void)setStringValue:(CPString)aString
{
    [super setStringValue:aString];

    [[self superview] setNeedsRelayout:YES];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    [super setBordered:shouldBeBordered];

    [self _initThemedValues];
}

@end

