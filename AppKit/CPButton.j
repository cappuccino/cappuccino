/*
 * CPButton.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "_CPImageAndTextView.j"
@import "CGGeometry.j"

@import "CPControl.j"
@import "CPStringDrawing.j"
@import "CPText.j"
@import "CPWindow_Constants.j"

/* @group CPBezelStyle */

                                       // IB style
CPRoundedBezelStyle             = 1;   // Push
CPRegularSquareBezelStyle       = 2;   // Bevel
CPThickSquareBezelStyle         = 3;
CPThickerSquareBezelStyle       = 4;
CPDisclosureBezelStyle          = 5;   // Disclosure triangle
CPShadowlessSquareBezelStyle    = 6;   // Square
CPCircularBezelStyle            = 7;   // Round
CPTexturedSquareBezelStyle      = 8;   // Textured
CPHelpButtonBezelStyle          = 9;   // Help
CPSmallSquareBezelStyle         = 10;  // Gradient
CPTexturedRoundedBezelStyle     = 11;  // Round Textured
CPRoundRectBezelStyle           = 12;  // Round Rect
CPRecessedBezelStyle            = 13;  // Recessed
CPRoundedDisclosureBezelStyle   = 14;  // Disclosure
CPHUDBezelStyle                 = -1;


/* @group CPButtonType */
CPMomentaryLightButton  = 0;
CPPushOnPushOffButton   = 1;
CPToggleButton          = 2;
CPSwitchButton          = 3; // Deprecated, use CPCheckBox instead.
CPRadioButton           = 4; // Deprecated, use CPRadio instead.
CPMomentaryChangeButton = 5;
CPOnOffButton           = 6;
CPMomentaryPushInButton = 7;
CPMomentaryPushButton   = 0;
CPMomentaryLight        = 7;

CPNoButtonMask          = 0;
CPContentsButtonMask    = 1;
CPPushInButtonMask      = 2;
CPGrayButtonMask        = 4;
CPBackgroundButtonMask  = 8;

CPNoCellMask                = CPNoButtonMask;
CPContentsCellMask          = CPContentsButtonMask;
CPPushInCellMask            = CPPushInButtonMask;
CPChangeGrayCellMask        = CPGrayButtonMask;
CPChangeBackgroundCellMask  = CPBackgroundButtonMask;

CPButtonStateMixed             = CPThemeState("mixed");
CPButtonStateBezelStyleRounded = CPThemeState("rounded");

// add all future correspondance between bezel styles and theme state here.
var CPButtonBezelStyleStateMap = @{
        CPRoundedBezelStyle: CPButtonStateBezelStyleRounded,
        CPRoundRectBezelStyle: [CPNull null],
    };

/// @cond IGNORE
CPButtonDefaultHeight = 25.0;
CPButtonImageOffset   = 3.0;
/// @endcond

/*!
    @ingroup appkit
    @class CPButton

    CPButton is a subclass of CPControl that
    intercepts mouse-down events and sends an action message to a
    target object when it's clicked or pressed.
*/
@implementation CPButton : CPControl
{
    BOOL                _allowsMixedState;

    CPString            _title;
    CPString            _alternateTitle;

    CPInteger           _showsStateBy;
    CPInteger           _highlightsBy;
    BOOL                _imageDimsWhenDisabled;

    // NS-style Display Properties
    CPBezelStyle        _bezelStyle;
    CPControlSize       _controlSize;

    CPString            _keyEquivalent;
    unsigned            _keyEquivalentModifierMask;

    CPTimer             _continuousDelayTimer;
    CPTimer             _continuousTimer;
    float               _periodicDelay;
    float               _periodicInterval;

    BOOL                _isTracking;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPTargetBinding || [aBinding hasPrefix:CPArgumentBinding])
        return [CPActionBinding class];

    return [super _binderClassForBinding:aBinding];
}

+ (id)buttonWithTitle:(CPString)aTitle
{
    return [self buttonWithTitle:aTitle theme:[CPTheme defaultTheme]];
}

+ (id)buttonWithTitle:(CPString)aTitle theme:(CPTheme)aTheme
{
    var button = [[self alloc] init];

    [button setTheme:aTheme];
    [button setTitle:aTitle];
    [button sizeToFit];

    return button;
}

+ (CPString)defaultThemeClass
{
    return @"button";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"image": [CPNull null],
            @"image-offset": 0.0,
            @"bezel-inset": CGInsetMakeZero(),
            @"content-inset": CGInsetMakeZero(),
            @"bezel-color": [CPNull null],
        };
}

/*!
    Initializes and returns a newly allocated CPButton object with a specified frame rectangle.
    @param aFrame The frame rectangle for the created button object.
    @return An initialized CPView object or nil if the object couldn't be created.
*/
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        // Should we instead override the defaults?
        [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
        [self setValue:CPCenterVerticalTextAlignment forThemeAttribute:@"vertical-alignment"];
        [self setValue:CPImageLeft forThemeAttribute:@"image-position"];
        [self setValue:CPImageScaleNone forThemeAttribute:@"image-scaling"];

        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];

        [self _init];
    }

    return self;
}

- (void)_init
{
    _controlSize = CPRegularControlSize;

    _keyEquivalent = @"";
    _keyEquivalentModifierMask = 0;

    // Continuous button defaults.
    _periodicInterval   = 0.05;
    _periodicDelay      = 0.5;

    [self setButtonType:CPMomentaryPushInButton];
}

// Setting the state
/*!
    Returns a Boolean value indicating whether the button allows a mixed state.
    @return \c YES if the button has a 'mixed' state in addition to on and off.
*/
- (BOOL)allowsMixedState
{
    return _allowsMixedState;
}

/*!
    Sets whether the button can have a 'mixed' state.
    @param aFlag specifies whether a 'mixed' state is allowed or not
*/
- (void)setAllowsMixedState:(BOOL)aFlag
{
    aFlag = !!aFlag;

    if (_allowsMixedState === aFlag)
        return;

    _allowsMixedState = aFlag;

    if (!_allowsMixedState && [self state] === CPMixedState)
        [self setState:CPOnState];
}

/*!
    Sets the value of the button using an Objective-J object.
    @param anObjectValue The value of the button interpreted as an Objective-J object.
*/
- (void)setObjectValue:(id)anObjectValue
{
    if (!anObjectValue || anObjectValue === @"" || ([anObjectValue intValue] === 0))
        anObjectValue = CPOffState;
    else if (![anObjectValue isKindOfClass:[CPNumber class]])
        anObjectValue = CPOnState;
    else if (anObjectValue >= CPOnState)
        anObjectValue = CPOnState;
    else if (anObjectValue < CPOffState)
        if ([self allowsMixedState])
            anObjectValue = CPMixedState;
        else
            anObjectValue = CPOnState;

    [super setObjectValue:anObjectValue];

    switch ([self objectValue])
    {
        case CPMixedState:
            [self unsetThemeState:CPThemeStateSelected];
            [self setThemeState:CPButtonStateMixed];
            if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
                [self setThemeState:CPThemeStateHighlighted];
            else
                [self unsetThemeState:CPThemeStateHighlighted];
            break;

        case CPOnState:
            [self unsetThemeState:CPButtonStateMixed];
            [self setThemeState:CPThemeStateSelected];
            if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
                [self setThemeState:CPThemeStateHighlighted];
            else
                [self unsetThemeState:CPThemeStateHighlighted];
            break;

        case CPOffState:
            [self unsetThemeState:CPThemeState(CPThemeStateSelected, CPButtonStateMixed, CPThemeStateHighlighted)];
    }
}

/*!
    Returns the button's next state.
    @return The button's state. A button can have two or three states.
    If it has two, this value is either \c CPOffState (the normal or unpressed state)
    or \c CPOnState (the alternate or pressed state).
    If it has three, this value can be \c CPOnState (the feature is in effect everywhere), \c CPOffState (the feature is in effect nowhere), or \c CPMixedState (the feature is in effect somewhere).
*/
- (CPInteger)nextState
{
   if ([self allowsMixedState])
   {
      var value = [self state];

      return value - ((value === -1) ? -2 : 1);
   }

    return 1 - [self state];
}

/*!
    Sets the button's state to the next available state.
    @param aState Possible states are any of the CPButton globals:
    \c CPOffState, \c CPOnState, \c CPMixedState
*/
- (void)setNextState
{
    if ([self infoForBinding:CPValueBinding])
        [self setAllowsMixedState:NO];

    [self setState:[self nextState]];
}

/*!
    Sets the button's state to \c aState.
    @param aState Possible states are any of the CPButton globals:
    \c CPOffState, \c CPOnState, \c CPMixedState
*/
- (void)setState:(CPInteger)aState
{
    [self setIntValue:aState];
}

/*!
    Returns the button's current state
*/
- (CPInteger)state
{
    return [self intValue];
}

/*!
    Sets the title displayed by the button when in its normal state.
    @param aTitle The string to set as the button's title. This title is always shown on buttons
    that don’t use their alternate contents when highlighting or displaying their alternate state.
*/
- (void)setTitle:(CPString)aTitle
{
    if (_title === aTitle)
        return;

    _title = aTitle;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the title displayed on the button when it’s in its normal state.
    @return    The title displayed on the receiver when it’s in its normal state
    or the empty string if the button doesn’t display a title.
*/
- (CPString)title
{
    return _title;
}

- (void)setAlternateTitle:(CPString)aTitle
{
    if (_alternateTitle === aTitle)
        return;

    _alternateTitle = aTitle;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPString)alternateTitle
{
    return _alternateTitle;
}

- (void)setImage:(CPImage)anImage
{
    [self setValue:anImage forThemeAttribute:@"image"];
}

- (CPImage)image
{
    return [self valueForThemeAttribute:@"image" inState:CPThemeStateNormal];
}

/*!
    Sets the button's image which is used in its alternate state.
    @param anImage the image to be used while the button is in an alternate state
*/
- (void)setAlternateImage:(CPImage)anImage
{
    [self setValue:anImage forThemeAttribute:@"image" inState:CPThemeStateHighlighted];
}

/*!
    Returns the image used when the button is in an alternate state.
*/
- (CPImage)alternateImage
{
    return [self valueForThemeAttribute:@"image" inState:CPThemeStateHighlighted];
}

- (void)setImageOffset:(float)theImageOffset
{
    [self setValue:theImageOffset forThemeAttribute:@"image-offset"];
}

- (float)imageOffset
{
    return [self valueForThemeAttribute:@"image-offset"];
}

- (void)setShowsStateBy:(CPInteger)aMask
{
    // CPPushInCellMask cannot be set for showsStateBy.
    aMask &= ~CPPushInCellMask;

    if (_showsStateBy === aMask)
        return;

    _showsStateBy = aMask;

    if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask) && [self state] != CPOffState)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (CPInteger)showsStateBy
{
    return _showsStateBy;
}

- (void)setHighlightsBy:(CPInteger)aMask
{
    if (_highlightsBy === aMask)
        return;

    _highlightsBy = aMask;

    if ([self hasThemeState:CPThemeStateHighlighted])
    {
        [self setNeedsDisplay:YES];
        [self setNeedsLayout];
    }
}

- (CPInteger)highlightsBy
{
    return _highlightsBy;
}

- (void)setButtonType:(CPButtonType)aButtonType
{
    switch (aButtonType)
    {
        case CPMomentaryLightButton:
            [self setHighlightsBy:CPChangeGrayCellMask | CPChangeBackgroundCellMask];
            [self setShowsStateBy:CPNoCellMask];
            break;

        case CPMomentaryPushInButton:
            [self setHighlightsBy:CPPushInCellMask | CPChangeGrayCellMask | CPChangeBackgroundCellMask];
            [self setShowsStateBy:CPNoCellMask];
            break;

        case CPMomentaryChangeButton:
            [self setHighlightsBy:CPContentsCellMask];
            [self setShowsStateBy:CPNoCellMask];
            break;

        case CPPushOnPushOffButton:
            [self setHighlightsBy:CPPushInCellMask | CPChangeGrayCellMask | CPChangeBackgroundCellMask];
            [self setShowsStateBy:CPChangeBackgroundCellMask | CPChangeGrayCellMask];
            break;

        case CPOnOffButton:
            [self setHighlightsBy:CPChangeGrayCellMask | CPChangeBackgroundCellMask];
            [self setShowsStateBy:CPChangeGrayCellMask | CPChangeBackgroundCellMask];
            break;

        case CPToggleButton:
            [self setHighlightsBy:CPPushInCellMask | CPContentsCellMask];
            [self setShowsStateBy:CPContentsCellMask];
            break;

        case CPSwitchButton:
            [CPException raise:CPInvalidArgumentException
                        reason:"The CPSwitchButton type is not supported in Cappuccino, use the CPCheckBox class instead."];

        case CPRadioButton:
            [CPException raise:CPInvalidArgumentException
                        reason:"The CPRadioButton type is not supported in Cappuccino, use the CPRadio class instead."];

        default:
            [CPException raise:CPInvalidArgumentException
                        reason:"Unknown button type."];
    }

    [self setImageDimsWhenDisabled:YES];
}

- (void)setImageDimsWhenDisabled:(BOOL)imageShouldDimWhenDisabled
{
    imageShouldDimWhenDisabled = !!imageShouldDimWhenDisabled;

    if (_imageDimsWhenDisabled === imageShouldDimWhenDisabled)
        return;

    _imageDimsWhenDisabled = imageShouldDimWhenDisabled;

    if ([self hasThemeState:CPThemeStateDisabled])
    {
        [self setNeedsDisplay:YES];
        [self setNeedsLayout];
    }
}

- (BOOL)imageDimsWhenDisabled
{
    return _imageDimsWhenDisabled;
}

- (void)setPeriodicDelay:(float)aDelay interval:(float)anInterval
{
    _periodicDelay      = aDelay;
    _periodicInterval   = anInterval;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isContinuous])
    {
        _continuousDelayTimer = [CPTimer scheduledTimerWithTimeInterval:_periodicDelay callback: function()
        {
            if (!_continuousTimer)
                _continuousTimer = [CPTimer scheduledTimerWithTimeInterval:_periodicInterval target:self selector:@selector(onContinousEvent:) userInfo:anEvent repeats:YES];
        }

        repeats:NO];
    }

    [super mouseDown:anEvent];
}

- (void)onContinousEvent:(CPTimer)aTimer
{
    if (_target && _action && [_target respondsToSelector:_action])
        [_target performSelector:_action withObject:self];
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    _isTracking = YES;

    var startedTracking = [super startTrackingAt:aPoint];

    if (_highlightsBy & (CPPushInCellMask | CPChangeGrayCellMask))
    {
        if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
            [self highlight:[self state] == CPOffState];
        else
            [self highlight:YES];
    }
    else
    {
        if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
            [self highlight:[self state] != CPOffState];
        else
            [self highlight:NO];
    }

    return startedTracking;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _isTracking = NO;

    if (mouseIsUp && CGRectContainsPoint([self bounds], aPoint))
        [self setNextState];
    else
    {
        if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
            [self highlight:[self state] != CPOffState];
        else
            [self highlight:NO];
    }

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
    [self invalidateTimers];
}

- (void)invalidateTimers
{
    if (_continuousTimer)
    {
        [_continuousTimer invalidate];
        _continuousTimer = nil;
    }

    if (_continuousDelayTimer)
    {
        [_continuousDelayTimer invalidate];
        _continuousDelayTimer = nil;
    }
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];

    return CGRectInsetByInset(bounds, contentInset);
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    // Is this necessary? The theme itself can just change its inset to a zero inset when !CPThemeStateBordered.
    if (![self isBordered])
        return bounds;

    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    return CGRectInsetByInset(bounds, bezelInset);
}

- (CGSize)_minimumFrameSize
{
    var size = CGSizeMakeZero(),
        contentView = [self ephemeralSubviewNamed:@"content-view"];

    if (contentView)
    {
        [contentView sizeToFit];
        size = [contentView frameSize];
    }
    else
        size = [([self title] || " ") sizeWithFont:[self currentValueForThemeAttribute:@"font"]];

    var contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"];

    size.width = MAX(size.width + contentInset.left + contentInset.right, minSize.width);
    size.height = MAX(size.height + contentInset.top + contentInset.bottom, minSize.height);

    if (maxSize.width >= 0.0)
        size.width = MIN(size.width, maxSize.width);

    if (maxSize.height >= 0.0)
        size.height = MIN(size.height, maxSize.height);

    return size;
}

/*!
    Adjust the size of the button to fit the title and surrounding button image.
*/
- (void)sizeToFit
{
    [self layoutSubviews];

    [self setFrameSize:[self _minimumFrameSize]];

    if ([self ephemeralSubviewNamed:@"content-view"])
        [self layoutSubviews];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bezelRectForBounds:[self bounds]];

    else if (aName === "content-view")
        return [self contentRectForBounds:[self bounds]];

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }
    else
        return [[_CPImageAndTextView alloc] initWithFrame:CGRectMakeZero()];
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];

    [bezelView setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
    {
        var title = nil,
            image = nil;

        if (_isTracking)
        {
            if (_highlightsBy & CPContentsCellMask)
            {
                if (_showsStateBy & CPContentsCellMask)
                {
                    title = ([self state] == CPOffState && _alternateTitle) ? _alternateTitle : _title;
                    image = ([self state] == CPOffState && [self alternateImage]) ? [self alternateImage] : [self image];
                }
                else
                {
                    title = [self alternateTitle];
                    image = [self alternateImage];
                }
            }
            else if (_showsStateBy & CPContentsCellMask)
            {
                title = ([self state] != CPOffState && _alternateTitle) ? _alternateTitle : _title;
                image = ([self state] != CPOffState && [self alternateImage]) ? [self alternateImage] : [self image];
            }
            else
            {
                title = _title;
                image = [self image];
            }
        }
        else
        {
            if (_showsStateBy & CPContentsCellMask)
            {
                title = ([self state] != CPOffState && _alternateTitle) ? _alternateTitle : _title;
                image = ([self state] != CPOffState && [self alternateImage]) ? [self alternateImage] : [self image];
            }
            else
            {
                title = _title;
                image = [self image];
            }
        }

        [contentView setText:title];
        [contentView setImage:image];
        [contentView setImageOffset:[self currentValueForThemeAttribute:@"image-offset"]];

        [contentView setFont:[self currentValueForThemeAttribute:@"font"]];
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

/*!
    Sets the keyboard shortcut for this button. For special keys see
    CPEvent.j CP...FunctionKey and CPText.j CP...Character.

    @param aString the keyboard shortcut as a string
*/
- (void)setKeyEquivalent:(CPString)aString
{
    _keyEquivalent = aString || @"";

    // Check if the key equivalent is the enter key
    // Treat \r and \n as the same key equivalent. See issue #710.
    if (aString === CPNewlineCharacter || aString === CPCarriageReturnCharacter)
        [self setThemeState:CPThemeStateDefault];
    else
        [self unsetThemeState:CPThemeStateDefault];
}

- (void)viewWillMoveToWindow:(CPWindow)aWindow
{
    var selfWindow = [self window];

    if (selfWindow === aWindow || aWindow === nil)
        return;

    if ([selfWindow defaultButton] === self)
        [selfWindow setDefaultButton:nil];

    if ([self keyEquivalent] === CPNewlineCharacter || [self keyEquivalent] === CPCarriageReturnCharacter)
        [aWindow setDefaultButton:self];
}

/*!
    Returns the keyboard shortcut for this button.
*/
- (CPString)keyEquivalent
{
    return _keyEquivalent;
}

/*!
    Returns the mask used with this button's key equivalent.
*/
- (void)setKeyEquivalentModifierMask:(unsigned)aMask
{
    _keyEquivalentModifierMask = aMask;
}

/*!
    Sets the mask to be used with this button's key equivalent.
*/
- (unsigned)keyEquivalentModifierMask
{
    return _keyEquivalentModifierMask;
}

/*!
    Checks the button's key equivalent against that in the event, and if they
    match simulates a button click.
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    // Don't handle the key equivalent for the default window because the window will handle it for us
    if ([[self window] defaultButton] === self)
        return NO;

    if (![anEvent _triggersKeyEquivalent:[self keyEquivalent] withModifierMask:[self keyEquivalentModifierMask]])
        return NO;

    [self performClick:nil];

    return YES;
}

/*!
    Perform a click on the receiver.

    @param sender - The sender object
*/
- (void)performClick:(id)sender
{
    // This is slightly different from [super performClick:] in that the highlight behaviour is dependent on
    // highlightsBy and showsStateBy.
    if (![self isEnabled])
        return;

    [self setState:[self nextState]];

    var shouldHighlight = NO;

    if (_highlightsBy & (CPPushInCellMask | CPChangeGrayCellMask))
    {
        if (_showsStateBy & (CPChangeGrayCellMask | CPChangeBackgroundCellMask))
            shouldHighlight = [self state] == CPOffState;
        else
            shouldHighlight = YES;
    }

    [self highlight:shouldHighlight];

    try
    {
        [self sendAction:[self action] to:[self target]];
    }
    catch (e)
    {
        throw e;
    }
    finally
    {
        if (shouldHighlight)
            [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(unhighlightButtonTimerDidFinish:) userInfo:nil repeats:NO];
    }
}

@end

@implementation CPButton (NS)

- (void)setBezelStyle:(unsigned)aBezelStyle
{
    if (aBezelStyle === _bezelStyle)
        return;

    var currentState = [CPButtonBezelStyleStateMap objectForKey:_bezelStyle],
        newState = [CPButtonBezelStyleStateMap objectForKey:aBezelStyle];

    if (currentState)
        [self unsetThemeState:currentState];

    if (newState)
        [self setThemeState:newState];

    _bezelStyle = aBezelStyle;
}

- (unsigned)bezelStyle
{
    return _bezelStyle;
}

@end


var CPButtonImageKey                    = @"CPButtonImageKey",
    CPButtonAlternateImageKey           = @"CPButtonAlternateImageKey",
    CPButtonTitleKey                    = @"CPButtonTitleKey",
    CPButtonAlternateTitleKey           = @"CPButtonAlternateTitleKey",
    CPButtonIsBorderedKey               = @"CPButtonIsBorderedKey",
    CPButtonAllowsMixedStateKey         = @"CPButtonAllowsMixedStateKey",
    CPButtonImageDimsWhenDisabledKey    = @"CPButtonImageDimsWhenDisabledKey",
    CPButtonImagePositionKey            = @"CPButtonImagePositionKey",
    CPButtonKeyEquivalentKey            = @"CPButtonKeyEquivalentKey",
    CPButtonKeyEquivalentMaskKey        = @"CPButtonKeyEquivalentMaskKey",
    CPButtonPeriodicDelayKey            = @"CPButtonPeriodicDelayKey",
    CPButtonPeriodicIntervalKey         = @"CPButtonPeriodicIntervalKey",
    CPButtonHighlightsByKey             = @"CPButtonHighlightsByKey",
    CPButtonShowsStateByKey             = @"CPButtonShowsStateByKey";

@implementation CPButton (CPCoding)

/*!
    Initializes the button by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPButton.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        _title = [aCoder decodeObjectForKey:CPButtonTitleKey];
        _alternateTitle = [aCoder decodeObjectForKey:CPButtonAlternateTitleKey];
        _allowsMixedState = [aCoder decodeBoolForKey:CPButtonAllowsMixedStateKey];

        if ([aCoder containsValueForKey:CPButtonHighlightsByKey])
        {
            // If one exists, assume both do.
            _highlightsBy = [aCoder decodeIntForKey:CPButtonHighlightsByKey];
            _showsStateBy = [aCoder decodeIntForKey:CPButtonShowsStateByKey];
        }
        else
        {
            // Backwards compatibility: if this CPButton was encoded before coding of
            // highlightsBy and showsStateBy were added, we should just use the
            // default values from _init rather than overwriting with 0, 0.
        }

        [self setImageDimsWhenDisabled:[aCoder decodeObjectForKey:CPButtonImageDimsWhenDisabledKey]];

        if ([aCoder containsValueForKey:CPButtonImagePositionKey])
            [self setImagePosition:[aCoder decodeIntForKey:CPButtonImagePositionKey]];

        if ([aCoder containsValueForKey:CPButtonKeyEquivalentKey])
            [self setKeyEquivalent:CFData.decodeBase64ToUtf16String([aCoder decodeObjectForKey:CPButtonKeyEquivalentKey])];

        if ([aCoder containsValueForKey:CPButtonPeriodicDelayKey])
            _periodicDelay = [aCoder decodeObjectForKey:CPButtonPeriodicDelayKey];

        if ([aCoder containsValueForKey:CPButtonPeriodicIntervalKey])
            _periodicInterval = [aCoder decodeObjectForKey:CPButtonPeriodicIntervalKey];

        _keyEquivalentModifierMask = [aCoder decodeIntForKey:CPButtonKeyEquivalentMaskKey];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

/*!
    Archives this button into the provided coder.
    @param aCoder the coder to which the button's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [self invalidateTimers];

    [aCoder encodeObject:_title forKey:CPButtonTitleKey];
    [aCoder encodeObject:_alternateTitle forKey:CPButtonAlternateTitleKey];

    [aCoder encodeBool:_allowsMixedState forKey:CPButtonAllowsMixedStateKey];

    [aCoder encodeInt:_highlightsBy forKey:CPButtonHighlightsByKey];
    [aCoder encodeInt:_showsStateBy forKey:CPButtonShowsStateByKey];

    [aCoder encodeBool:[self imageDimsWhenDisabled] forKey:CPButtonImageDimsWhenDisabledKey];
    [aCoder encodeInt:[self imagePosition] forKey:CPButtonImagePositionKey];

    if (_keyEquivalent)
        [aCoder encodeObject:CFData.encodeBase64Utf16String(_keyEquivalent) forKey:CPButtonKeyEquivalentKey];

    [aCoder encodeInt:_keyEquivalentModifierMask forKey:CPButtonKeyEquivalentMaskKey];

    [aCoder encodeObject:_periodicDelay forKey:CPButtonPeriodicDelayKey];
    [aCoder encodeObject:_periodicInterval forKey:CPButtonPeriodicIntervalKey];
}

@end
