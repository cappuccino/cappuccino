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


/* @group CPBezelStyle */

CPRoundedBezelStyle             = 1;
CPRegularSquareBezelStyle       = 2;
CPThickSquareBezelStyle         = 3;
CPThickerSquareBezelStyle       = 4;
CPDisclosureBezelStyle          = 5;
CPShadowlessSquareBezelStyle    = 6;
CPCircularBezelStyle            = 7;
CPTexturedSquareBezelStyle      = 8;
CPHelpButtonBezelStyle          = 9;
CPSmallSquareBezelStyle         = 10;
CPTexturedRoundedBezelStyle     = 11;
CPRoundRectBezelStyle           = 12;
CPRecessedBezelStyle            = 13;
CPRoundedDisclosureBezelStyle   = 14;
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

CPNoButtonMask              = 0;
CPContentsButtonMask        = 1;
CPPushInButtonMask          = 2;
CPGrayButtonMask            = 4;
CPBackgroundButtonMask      = 8;

CPNoCellMask                = CPNoButtonMask;
CPContentsCellMask          = CPContentsButtonMask;
CPPushInCellMask            = CPPushInButtonMask;
CPChangeGrayCellMask        = CPGrayButtonMask;
CPChangeBackgroundCellMask  = CPBackgroundButtonMask;

CPButtonStateMixed  = CPThemeState("mixed");

CPButtonDefaultHeight = 24.0;
CPButtonImageOffset   = 3.0;

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

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], 0.0, _CGInsetMakeZero(), _CGInsetMakeZero(), [CPNull null]]
                                       forKeys:[@"image", @"image-offset", @"bezel-inset", @"content-inset", @"bezel-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        // Should we instead override the defaults?
        [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
        [self setValue:CPCenterVerticalTextAlignment forThemeAttribute:@"vertical-alignment"];
        [self setValue:CPImageLeft forThemeAttribute:@"image-position"];
        [self setValue:CPScaleNone forThemeAttribute:@"image-scaling"];

        _controlSize = CPRegularControlSize;

        _keyEquivalent = @"";
        _keyEquivalentModifierMask = 0;

//        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];
    }

    return self;
}

// Setting the state
/*!
    Returns \c YES if the button has a 'mixed' state in addition to on and off.
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

- (void)setObjectValue:(id)anObjectValue
{
    if (!anObjectValue || anObjectValue === @"" || ([anObjectValue intValue] === 0))
        anObjectValue = CPOffState;

    else if (![anObjectValue isKindOfClass:[CPNumber class]])
        anObjectValue = CPOnState;

    else if (anObjectValue > CPOnState)
        anObjectValue = CPOnState

    else if (anObjectValue < CPOffState)
        if ([self allowsMixedState])
            anObjectValue = CPMixedState;

        else
            anObjectValue = CPOnState;

    [super setObjectValue:anObjectValue];

    switch ([self objectValue])
    {
        case CPMixedState:  [self unsetThemeState:CPThemeStateSelected];
                            [self setThemeState:CPButtonStateMixed];
                            break;

        case CPOnState:     [self unsetThemeState:CPButtonStateMixed];
                            [self setThemeState:CPThemeStateSelected];
                            break;

        case CPOffState:    [self unsetThemeState:CPThemeStateSelected | CPButtonStateMixed];
    }
}

- (CPInteger)nextState
{
   if ([self allowsMixedState])
   {
      var value = [self state];

      return value - ((value === -1) ? -2 : 1);
   }

    return 1 - [self state];
}

- (void)setNextState
{
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

- (void)setTitle:(CPString)aTitle
{
    if (_title === aTitle)
        return;

    _title = aTitle;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

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

    if ([self hasThemeState:CPThemeStateHighlighted])
    {
        [self setNeedsDisplay:YES];
        [self setNeedsLayout];
    }
}

- (void)setButtonType:(CPButtonType)aButtonType
{
    switch (aButtonType)
    {
        case CPMomentaryLightButton:    [self setHighlightsBy:CPChangeBackgroundCellMask];
                                        [self setShowsStateBy:CPNoCellMask];
                                        break;

        case CPMomentaryPushInButton:   [self setHighlightsBy:CPPushInCellMask | CPChangeGrayCellMask];
                                        [self setShowsStateBy:CPNoCellMask];
                                        break;

        case CPMomentaryChangeButton:   [self setHighlightsBy:CPContentsCellMask];
                                        [self setShowsStateBy:CPNoCellMask];
                                        break;

        case CPPushOnPushOffButton:     [self setHighlightsBy:CPPushInCellMask | CPChangeGrayCellMask];
                                        [self setShowsStateBy:CPChangeBackgroundCellMask];
                                        break;

        case CPOnOffButton:             [self setHighlightsBy:CPChangeBackgroundCellMask];
                                        [self setShowsStateBy:CPChangeBackgroundCellMask];
                                        break;

        case CPToggleButton:            [self setHighlightsBy:CPPushInCellMask | CPContentsCellMask];
                                        [self setShowsStateBy:CPContentsCellMask];
                                        break;

        case CPSwitchButton:            [CPException raise:CPInvalidArgumentException
                                                    reason:"The CPSwitchButton type is not supported in Cappuccino, use the CPCheckBox class instead."];

        case CPRadioButton:             [CPException raise:CPInvalidArgumentException
                                                    reason:"The CPRadioButton type is not supported in Cappuccino, use the CPRadio class instead."];

        default:                        [CPException raise:CPInvalidArgumentException
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

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [self highlight:YES];

    return [super startTrackingAt:aPoint];
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self highlight:NO];

    [super stopTracking:lastPoint at:aPoint mouseIsUp:mouseIsUp];

    if (mouseIsUp && CGRectContainsPoint([self bounds], aPoint))
        [self setNextState];
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];

    if (_CGInsetIsEmpty(contentInset))
        return bounds;

    bounds = _CGRectMakeCopy(bounds);
    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;

    return bounds;
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    if (![self isBordered])
        return _CGRectMakeZero();

    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    if (_CGInsetIsEmpty(bezelInset))
        return bounds;

    bounds = _CGRectMakeCopy(bounds);
    bounds.origin.x += bezelInset.left;
    bounds.origin.y += bezelInset.top;
    bounds.size.width -= bezelInset.left + bezelInset.right;
    bounds.size.height -= bezelInset.top + bezelInset.bottom;

    return bounds;
}

/*!
    Adjust the size of the button to fit the title and surrounding button image.
*/
- (void)sizeToFit
{
    [self layoutSubviews];

    var size,
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

    [self setFrameSize:size];

    if (contentView)
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
        var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }
    else
        return [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];
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
        [contentView setText:([self hasThemeState:CPThemeStateHighlighted] && _alternateTitle) ? _alternateTitle : _title];
        [contentView setImage:[self currentValueForThemeAttribute:@"image"]];
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

@end

@implementation CPButton (NS)

- (void)setBezelStyle:(unsigned)aBezelStyle
{
}

- (unsigned)bezelStyle
{
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
    CPButtonKeyEquivalentMaskKey        = @"CPButtonKeyEquivalentMaskKey";

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
        _controlSize = CPRegularControlSize;

        _title = [aCoder decodeObjectForKey:CPButtonTitleKey];
        _alternateTitle = [aCoder decodeObjectForKey:CPButtonAlternateTitleKey];

        if ([aCoder containsValueForKey:CPButtonAllowsMixedStateKey])
            _allowsMixedState = [aCoder decodeBoolForKey:CPButtonAllowsMixedStateKey];

        [self setImageDimsWhenDisabled:[aCoder decodeObjectForKey:CPButtonImageDimsWhenDisabledKey]];

        if ([aCoder containsValueForKey:CPButtonImagePositionKey])
            [self setImagePosition:[aCoder decodeIntForKey:CPButtonImagePositionKey]];

        if ([aCoder containsValueForKey:CPButtonKeyEquivalentKey])
            [self setKeyEquivalent:CFData.decodeBase64ToUtf16String([aCoder decodeObjectForKey:CPButtonKeyEquivalentKey])];

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

    [aCoder encodeObject:_title forKey:CPButtonTitleKey];
    [aCoder encodeObject:_alternateTitle forKey:CPButtonAlternateTitleKey];

    [aCoder encodeBool:_allowsMixedState forKey:CPButtonAllowsMixedStateKey];

    [aCoder encodeBool:[self imageDimsWhenDisabled] forKey:CPButtonImageDimsWhenDisabledKey];
    [aCoder encodeInt:[self imagePosition] forKey:CPButtonImagePositionKey];

    if (_keyEquivalent)
        [aCoder encodeObject:CFData.encodeBase64Utf16String(_keyEquivalent) forKey:CPButtonKeyEquivalentKey];

    [aCoder encodeInt:_keyEquivalentModifierMask forKey:CPButtonKeyEquivalentMaskKey];
}

@end

@import "CPCheckBox.j"
@import "CPRadio.j"
