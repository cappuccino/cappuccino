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
    return [[CPButtonBar _sharedDummyButtonBar] plusButton];
}

+ (id)minusButton
{
    return [[CPButtonBar _sharedDummyButtonBar] minusButton];
}

+ (id)actionPopupButton
{
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
        alternateImage = [self valueForThemeAttribute:attributeName inState:CPThemeStateHighlighted],
        button         = [self buttonWithImage:image alternateImage:alternateImage];

    // Track that this button was created from a template (e.g. Plus/Minus).
    // This allows us to reload the image later if the ButtonBar becomes HUD.
    if ([button respondsToSelector:@selector(setTemplateImageName:)])
        [button setTemplateImageName:templateImage];

    return button;
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
        alternateImage = [self valueForThemeAttribute:attributeName inState:CPThemeStateHighlighted],
        button         = [self pulldownButtonWithImage:image alternateImage:alternateImage];

    // Track that this button was created from a template.
    if ([button respondsToSelector:@selector(setTemplateImageName:)])
        [button setTemplateImageName:templateImage];

    return button;
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

// Helper to refresh button images based on the CURRENT state of the bar.
// This is called by setButtons: and viewDidMoveToWindow.
- (void)_reloadButtonImages
{
    var count = [_buttons count],
        // The magic happens here: [self themeState] will include CPThemeStateHUD 
        // if this bar was manually set to HUD or is inside a HUD window.
        // We OR it with Normal/Highlighted to look up the correct image variant.
        currentState = [self themeState],
        normalState  = currentState.and(CPThemeStateNormal),
        highlightedState = currentState.and(CPThemeStateHighlighted);

    for (var i = 0; i < count; i++)
    {
        var button = _buttons[i];
        
        // Only update buttons that we know are based on a template (Plus/Minus/Action)
        if ([button respondsToSelector:@selector(templateImageName)] && [button templateImageName])
        {
            var templateName = [button templateImageName],
                attributeName = [_templateImageMap valueForKey:templateName];
            
            if (attributeName)
            {
                // Fetch the image from the ButtonBar's theme using the ButtonBar's current state
                var image = [self valueForThemeAttribute:attributeName inState:normalState],
                    altImage = [self valueForThemeAttribute:attributeName inState:highlightedState];
                
                // Apply the new images to the button
                if ([button isKindOfClass:[_CPButtonBarPopUpButton class]])
                {
                    [button setButtonImage:image];
                    [button setAlternateImage:altImage];
                }
                else if ([button isKindOfClass:[CPButton class]])
                {
                    [button setImage:image];
                    [button setAlternateImage:altImage];
                }
            }
        }
    }
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

    // Reload images whenever theme values load (e.g. state change)
    [self _reloadButtonImages];

    _needsToLoadThemeValues    = NO;
    _needsToComputeNeededSpace = YES;
}

// Ensure we update appearances when added to a window (which might be HUD)
- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    _needsToLoadThemeValues = YES;
    [self setNeedsLayout:YES];
}

// Ensure we update if the HUD state is toggled manually
- (void)setThemeState:(CPThemeState)aState
{
    var oldState = [self themeState];
    [super setThemeState:aState];
    if (oldState !== aState) {
        _needsToLoadThemeValues = YES;
        [self setNeedsLayout:YES];
    }
}

- (void)unsetThemeState:(CPThemeState)aState
{
    var oldState = [self themeState];
    [super unsetThemeState:aState];
    if (oldState !== [self themeState]) {
        _needsToLoadThemeValues = YES;
        [self setNeedsLayout:YES];
    }
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

    if ([_buttons count] > 0)
    {
        [self setButtons:@[]]; 
        [self _sendDelegatePopulateButtonBar];
    }

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

    // When buttons are set, we immediately force them to match the Button Bar's current state.
    // If the bar was manually set to CPThemeStateHUD before calling setButtons:, this ensures
    // the buttons (which might have been created as black icons) are swapped to white icons.
    [self _reloadButtonImages];

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

    var newDivider = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [_dividers addObject:newDivider];
    [newDivider setBackgroundColor:_dividerColor];
    [self addSubview:newDivider];

    if ([button isKindOfClass:_CPButtonBarFlexibleSpace])
        _flexibleSpacesCount++;
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

    for (var i = 0, count = [_buttons count]; i < count; i++)
    {
        [_buttons[i] setBordered:_buttonsAreBordered];
        [_buttons[i] _initThemedValues];
    }

    var useDividers = _buttonsAreBordered && !!_dividerColor;

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
    [self setAutomaticResizeControl:shouldHaveResizeControl];
}

- (BOOL)hasResizeControl
{
    return [self automaticResizeControl];
}

- (void)setResizeControlIsLeftAligned:(BOOL)shouldBeLeftAligned
{
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

        if ([button isHidden] || (_buttonsAreBordered && [button isKindOfClass:_CPButtonBarSeparator]))
            continue;

        if ([button isFlexible])
        {
            width = [button minWidth];

            if (width > 0)
            {
                if ([button maxWidth] != -1)
                    _flexibleDelta += (delta = [button maxWidth] - width);
                else
                    delta = availableWidth;

                [_flexibleDeltas addObject:delta];
                _flexibleCount++;
            }
        }
        else
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

    if (useDividers && (remainingSpace < _flexibleDelta))
    {
        nbDividersToRemove = MIN(_flexibleSpacesCount, _flexibleDelta - remainingSpace);
        remainingSpace    += nbDividersToRemove;
    }

    if (remainingSpace > 0)
    {
        if (_flexibleCount > 0)
        {
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

        if (_flexibleSpacesCount > 0)
            flexibleSpaceWidth = (remainingSpace > 0) ? remainingSpace / _flexibleSpacesCount : 0;
    }

    for (var i = 0, count = _buttons.length, button, width, extraSpace, buttonHeight; i < count; i++)
    {
        button = _buttons[i];

        if ([button isKindOfClass:_CPButtonBarSeparator])
            [button setHidden:_buttonsAreBordered];

        if ([button isHidden])
        {
            [_dividers[i] setHidden:YES];
            continue;
        }

        width        = ([button isKindOfClass:_CPButtonBarFlexibleSpace]) ? flexibleSpaceWidth : [button frame].size.width;
        extraSpace   = [button extraSpacing];
        buttonHeight = [button frame].size.height;

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
{
    CPString _templateImageName @accessors(property=templateImageName);
}

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
{
    CPImage _image;
    BOOL    _isLocallyHighlighted;
    
    CPString _templateImageName @accessors(property=templateImageName);
}

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
        [self addItemWithTitle:@""];
        [self setControlSize:CPSmallControlSize];
        
        _image = image;
        _isLocallyHighlighted = NO;

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

// Helper to update the main image from CPButtonBar logic
- (void)setButtonImage:(CPImage)anImage
{
    if (_image === anImage)
        return;
    
    _image = anImage;
    [self setNeedsLayout];
}

// Track the highlight state
- (void)highlight:(BOOL)shouldHighlight
{
    if (_isLocallyHighlighted === shouldHighlight)
        return;

    _isLocallyHighlighted = shouldHighlight;
    
    // Call super to ensure internal CPButton state updates
    [super highlight:shouldHighlight];

    // Trigger layout to update the image
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    var bezelColor = [self currentValueForThemeAttribute:@"bezel-color"],
        contentView;

    // 1. Handle Background Color
    if ([bezelColor isCSSBased])
    {
        [self setBackgroundColor:bezelColor];
        contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:nil];
    }
    else if (bezelColor)
    {
        var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:@"content-view"];

        [bezelView setBackgroundColor:bezelColor];

        contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];
    }
    else
    {
        contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:nil];
    }

    if (contentView)
    {
        var imageToShow = _image;

        // Image swapping logic
        if (_isLocallyHighlighted)
        {
            if ([self alternateImage])
            {
                // 1. If an alternate image exists (like plus/minus buttons), use it.
                imageToShow = [self alternateImage];
                [contentView setAlphaValue:1.0];
            }
            else
            {
                // 2. Fallback: If no alternate image exists (like the gear button),
                // reduce opacity to 0.5 to simulate a "pressed" state visually.
                [contentView setAlphaValue:0.5];
            }
        }
        else
        {
            // Normal state
            [contentView setAlphaValue:1.0];
        }
            
        [contentView setImage:imageToShow];

        [contentView setFrameSize:CGSizeMake(16,16)];
        [contentView setImagePosition:CPImageLeft];
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
