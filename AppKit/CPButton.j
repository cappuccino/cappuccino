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
@typedef CPBezelStyle
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
CPInlineBezelStyle              = 15;  // Inline
CPHUDBezelStyle                 = -1;


/* @group CPButtonType */
@typedef CPButtonType
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

CPButtonStateMixed                       = CPThemeState("mixed");
CPButtonStateBezelStyleRounded           = CPThemeState("rounded");             // IB style : Push
CPButtonStateBezelStyleShadowlessSquare  = CPThemeState("square");              // IB style : Square
CPButtonStateBezelStyleSmallSquare       = CPThemeState("gradient");            // IB style : Gradient
CPButtonStateBezelStyleTexturedRounded   = CPThemeState("textured-rounded");    // IB style : Textured rounded
CPButtonStateBezelStyleRoundRect         = CPThemeState("roundRect");           // IB style : Round rect
CPButtonStateBezelStyleRecessed          = CPThemeState("recessed");            // IB style : Recessed
CPButtonStateBezelStyleInline            = CPThemeState("inline");              // IB style : Inline
CPButtonStateBezelStyleRegularSquare     = CPThemeState("bevel");               // IB style : Bevel
CPButtonStateBezelStyleTextured          = CPThemeState("textured");            // IB style : Textured
CPButtonStateBezelStyleDisclosure        = CPThemeState("disclosure");          // IB style : Disclosure triangle
CPButtonStateBezelStyleRoundedDisclosure = CPThemeState("rounded-disclosure");  // IB style : Rounded disclosure

// add all future correspondance between bezel styles and theme state here.
var CPButtonBezelStyleStateMap = @{
        CPRoundedBezelStyle:            CPButtonStateBezelStyleRounded,
        CPShadowlessSquareBezelStyle:   CPButtonStateBezelStyleShadowlessSquare,
        CPSmallSquareBezelStyle:        CPButtonStateBezelStyleSmallSquare,
        CPTexturedRoundedBezelStyle:    CPButtonStateBezelStyleTexturedRounded,
        CPRoundRectBezelStyle:          CPButtonStateBezelStyleRoundRect,
        CPRecessedBezelStyle:           CPButtonStateBezelStyleRecessed,
        CPInlineBezelStyle:             CPButtonStateBezelStyleInline,
        CPRegularSquareBezelStyle:      CPButtonStateBezelStyleRegularSquare,
        CPTexturedSquareBezelStyle:     CPButtonStateBezelStyleTextured,
        CPDisclosureBezelStyle:         CPButtonStateBezelStyleDisclosure,
        CPRoundedDisclosureBezelStyle:  CPButtonStateBezelStyleRoundedDisclosure
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
    ThemeState          _bezelState;

    CPString            _keyEquivalent;
    unsigned            _keyEquivalentModifierMask;

    CPTimer             _continuousDelayTimer;
    CPTimer             _continuousTimer;
    float               _periodicDelay;
    float               _periodicInterval;

    BOOL                _isHighlighted;
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
            @"image-position": CPImageLeft,
            @"vertical-alignment": CPCenterVerticalTextAlignment,
            @"alignment": CPCenterTextAlignment,
            @"image-scaling": CPImageScaleNone,
            @"invert-image": NO,
            @"invert-image-on-push": NO,
            @"image-color": [CPNull null] // If null, image color follows text color
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
        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];

        [self _init];
    }

    return self;
}

- (void)_init
{
    _keyEquivalent = @"";
    _keyEquivalentModifierMask = 0;

    // Continuous button defaults.
    _periodicInterval   = 0.05;
    _periodicDelay      = 0.5;

    [self setButtonType:CPMomentaryPushInButton];
}

#pragma mark -
#pragma mark Control Size

- (void)setControlSize:(CPControlSize)aControlSize
{
    [super setControlSize:aControlSize];

    if ([self isBordered])
        [self _sizeToControlSize];
}


#pragma mark -

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
    // This is needed when compiling themes
    if (!_bezelState)
        _bezelState = CPThemeStateNormal;

    [self setValue:anImage forThemeAttribute:@"image" inState:_bezelState];
    // if we omit this, images will disappear as soon as the button becomes disabled
    [self setValue:anImage forThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateDisabled)];
}

- (CPImage)image
{
    if (!_bezelState)
        _bezelState = CPThemeStateNormal;

    return [self valueForThemeAttribute:@"image" inState:_bezelState];
}

/*!
    Sets the button's image which is used in its alternate state.
    @param anImage the image to be used while the button is in an alternate state
*/
- (void)setAlternateImage:(CPImage)anImage
{
    [self setValue:anImage forThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateHighlighted)];
    [self setValue:anImage forThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateSelected)];
}

/*!
    Returns the image used when the button is in an alternate state.
*/
- (CPImage)alternateImage
{
    return [self valueForThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateSelected)];
}

- (void)setHoveredImage:(CPImage)anImage
{
    [self setValue:anImage forThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateHovered)];
}

- (CPImage)hoveredImage
{
    return [self valueForThemeAttribute:@"image" inState:_bezelState.and(CPThemeStateHovered)];
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

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
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

- (void)highlight:(BOOL)shouldHighlight
{
    if (_isHighlighted == shouldHighlight)
        return;

    _isHighlighted = shouldHighlight;
    [super highlight:shouldHighlight];
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isEnabled] && [self isContinuous])
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

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    if (mouseIsUp && CGRectContainsPoint([self bounds], aPoint))
        [self setNextState];

    [self highlight:NO];
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
    var contentInset = [self valueForThemeAttribute:@"content-inset" inState:[self _contentVisualState]];

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
        size = [([self title] || " ") sizeWithFont:[self font]];

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

- (CPThemeState)_backgroundVisualState
{
    var visualState  = [self themeState] || CPThemeStateNormal, // Needed during theme compilation
        currentState = [self state],
        buttonIsOn   = (currentState !== CPOffState);

    if (_isHighlighted && (_highlightsBy & (CPPushInCellMask | CPChangeGrayCellMask)))
        visualState = visualState.and(CPThemeStateHighlighted);
    else
        visualState = visualState.without(CPThemeStateHighlighted);

    if (buttonIsOn && (_showsStateBy & (CPPushInCellMask | CPChangeGrayCellMask)))
        visualState = visualState.and((currentState === CPOnState) ? CPThemeStateSelected : CPButtonStateMixed);
    else
        visualState = visualState.without(CPThemeStateSelected);

    return visualState;
}

// Note : We have to split content and image visual states as, for example, radio buttons don't follow push buttons behavior
- (CPThemeState)_contentVisualState
{
    var visualState  = [self themeState] || CPThemeStateNormal, // Needed during theme compilation
        currentState = [self state],
        buttonIsOn   = (currentState !== CPOffState);

    // If the button is pushed (_isHighlighted), always add the highlighted state
    if (_isHighlighted || (((_showsStateBy & CPChangeGrayCellMask) || (_showsStateBy & CPChangeBackgroundCellMask)) && buttonIsOn))
        visualState = visualState.and(CPThemeStateHighlighted);
    else
        visualState = visualState.without(CPThemeStateHighlighted);

    if (buttonIsOn && (_showsStateBy & CPContentsCellMask))
        visualState = visualState.and((currentState === CPOnState) ? CPThemeStateSelected : CPButtonStateMixed);
    else
        visualState = visualState.without(CPThemeStateSelected);

    return visualState;
}

- (CPThemeState)_imageVisualState
{
    var visualState  = [self themeState] || CPThemeStateNormal, // Needed during theme compilation
        currentState = [self state],
        buttonIsOn   = (currentState !== CPOffState);

    // Remove highlighted & selected theme states
    visualState = visualState.without(CPThemeStateHighlighted);
    visualState = visualState.without(CPThemeStateSelected);

    // Note : We have to deal with special case where button is ON, highlightsBy and showsStateBy use content, and button is pushed
    //        BUT this should not be used for disclosure buttons !
    if (_isHighlighted && buttonIsOn && (_highlightsBy & CPContentsCellMask) && (_showsStateBy & CPContentsCellMask) && (_bezelStyle !== CPDisclosureBezelStyle))
        return visualState;

    if (_isHighlighted && ((_highlightsBy & CPContentsCellMask) || (_highlightsBy & CPChangeGrayCellMask)))
        visualState = visualState.and(CPThemeStateHighlighted);

    if (buttonIsOn && (_showsStateBy & CPContentsCellMask))
        visualState = visualState.and((currentState === CPOnState) ? CPThemeStateSelected : CPButtonStateMixed);

    return visualState;
}

- (CPString)_currentTitle
{
    var buttonIsOn = ([self state] !== CPOffState);

    // Note : We have to deal with special case where button is ON, highlightsBy and showsStateBy use content, and button is pushed
    if (_isHighlighted && buttonIsOn && (_highlightsBy & CPContentsCellMask) && (_showsStateBy & CPContentsCellMask))
        return _title;

    else if (_alternateTitle && ((_isHighlighted && (_highlightsBy & CPContentsCellMask)) || (buttonIsOn && (_showsStateBy & CPContentsCellMask))))
        return _alternateTitle;

    else
        return _title;
}

- (CPImage)_currentImage
{
    var visualState  = [self _imageVisualState],
        currentImage = [self valueForThemeAttribute:@"image"       inState:visualState],
        imageColor   = [self valueForThemeAttribute:@"image-color" inState:visualState],
        buttonIsOn   = ([self state] !== CPOffState);

    if ([currentImage isMaterialIconImage])
    {
        if (([self valueForThemeAttribute:@"invert-image" inState:visualState] || ([self valueForThemeAttribute:@"invert-image-on-push" inState:visualState] && (_isHighlighted || (((_showsStateBy & CPChangeGrayCellMask) || (_showsStateBy & CPChangeBackgroundCellMask)) && buttonIsOn)))))
            currentImage = [currentImage invertedImage];

        else if (imageColor && [imageColor isKindOfClass:CPColor])
            // In some buttons, image color doesn't follow text color !
            currentImage = [currentImage imageVersionWithColor:imageColor];

        else
            // By default, image color follows text color
            currentImage = [currentImage imageVersionWithColor:[self valueForThemeAttribute:@"text-color" inState:[self _contentVisualState]]];
    }

    return currentImage;
}

- (void)layoutSubviews
{
    var bezelView   = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                             positioned:CPWindowBelow
                        relativeToEphemeralSubviewNamed:@"content-view"],

        contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"],

        image              = [self _currentImage],
        contentVisualState = [self _contentVisualState];

    [bezelView   setBackgroundColor:[self valueForThemeAttribute:@"bezel-color" inState:[self _backgroundVisualState]]];
    [contentView setText:[self _currentTitle]];
    [contentView setImage:image];

    [contentView setImageOffset:[self valueForThemeAttribute:@"image-offset" inState:contentVisualState]];

    [contentView setFont:[self font]];
    [contentView setTextColor:[self valueForThemeAttribute:@"text-color" inState:contentVisualState]];
    [contentView setAlignment:[self valueForThemeAttribute:@"alignment"  inState:contentVisualState]];
    [contentView setVerticalAlignment:[self valueForThemeAttribute:@"vertical-alignment" inState:contentVisualState]];
    [contentView setLineBreakMode:[self valueForThemeAttribute:@"line-break-mode" inState:contentVisualState]];
    [contentView _setUsesSingleLineMode:YES];
    [contentView setTextShadowColor:[self valueForThemeAttribute:@"text-shadow-color" inState:contentVisualState]];
    [contentView setTextShadowOffset:[self valueForThemeAttribute:@"text-shadow-offset" inState:contentVisualState]];
    [contentView setImagePosition:[self valueForThemeAttribute:@"image-position"]];
    [contentView setImageScaling:[self valueForThemeAttribute:@"image-scaling"]];

    // We don't automatically dim material icon images as the color is driven by the theme
    [contentView setDimsImage:[self hasThemeState:CPThemeStateDisabled] && _imageDimsWhenDisabled && ![image isMaterialIconImage]];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
    {
        [self setThemeState:CPThemeStateBordered];

        if (_bezelState)
            _bezelState = _bezelState.and(CPThemeStateBordered);
        else
            _bezelState = CPThemeStateBordered;
    }
    else
    {
        [self unsetThemeState:CPThemeStateBordered];

        if (_bezelState)
            _bezelState = _bezelState.without(CPThemeStateBordered);
        else
            _bezelState = CPThemeStateNormal;
    }
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

    if (selfWindow === aWindow || aWindow == nil)
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

    [self highlight:YES];

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

    if (_bezelState && newState)
        _bezelState = _bezelState.and(newState);
    else
        _bezelState = newState || CPThemeStateNormal;

    // For disclosure triangle and rounded, we have to move away from
    // what Xcode tells us as we implement visual behavior with images (so content)
    // and not background

    if ((_bezelStyle === CPDisclosureBezelStyle) || (_bezelStyle === CPRoundedDisclosureBezelStyle))
        [self setShowsStateBy:CPContentsCellMask];
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
    CPButtonShowsStateByKey             = @"CPButtonShowsStateByKey",
    CPButtonBezelStyleKey               = @"CPButtonBezelStyleKey";

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

        if ([aCoder containsValueForKey:CPButtonIsBorderedKey])
            [self setBordered:[aCoder decodeBoolForKey:CPButtonIsBorderedKey]];

        if ([aCoder containsValueForKey:CPButtonBezelStyleKey])
            [self setBezelStyle:[aCoder decodeIntForKey:CPButtonBezelStyleKey]];

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

    [aCoder encodeBool:[self isBordered] forKey:CPButtonIsBorderedKey];
    [aCoder encodeInt: [self bezelStyle] forKey:CPButtonBezelStyleKey];
}

@end
