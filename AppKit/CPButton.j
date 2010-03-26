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

#include "CoreGraphics/CGGeometry.h"


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
    
    CPImage             _image;
    CPImage             _alternateImage;

    CPInteger           _showsStateBy;
    CPInteger           _highlightsBy;
    BOOL                _imageDimsWhenDisabled;

    // NS-style Display Properties
    CPBezelStyle        _bezelStyle;
    CPControlSize       _controlSize;
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

+ (CPString)themeClass
{
    return @"button";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMakeZero(), [CPNull null]]
                                       forKeys:[@"bezel-inset", @"content-inset", @"bezel-color"]];
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
    if (_image === anImage)
        return;
    
    _image = anImage;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPImage)image
{
    return _image;
}

/*!
    Sets the button's image which is used in its alternate state.
    @param anImage the image to be used while the button is in an alternate state
*/
- (void)setAlternateImage:(CPImage)anImage
{
    if (_alternateImage === anImage)
        return;
    
    _alternateImage = anImage;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the image used when the button is in an alternate state.
*/
- (CPImage)alternateImage
{
    return _alternateImage;
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

    if (_imageDimsWhenDisabled)
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
    var size = [([self title] || " ") sizeWithFont:[self currentValueForThemeAttribute:@"font"]],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"];

    size.width = MAX(size.width + contentInset.left + contentInset.right, minSize.width);
    size.height = MAX(size.height + contentInset.top + contentInset.bottom, minSize.height);

    if (maxSize.width >= 0.0)
        size.width = MIN(size.width, maxSize.width);

    if (maxSize.height >= 0.0)
        size.height = MIN(size.height, maxSize.height);

    [self setFrameSize:size];
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
        [contentView setImage:([self hasThemeState:CPThemeStateHighlighted] && _alternateImage) ? _alternateImage : _image];

        [contentView setFont:[self currentValueForThemeAttribute:@"font"]];
        [contentView setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
        [contentView setAlignment:[self currentValueForThemeAttribute:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemeAttribute:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemeAttribute:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
        [contentView setImagePosition:[self currentValueForThemeAttribute:@"image-position"]];
        [contentView setImageScaling:[self currentValueForThemeAttribute:@"image-scaling"]];
    }
}

- (void)setDefaultButton:(BOOL)shouldBeDefaultButton
{
    if (shouldBeDefaultButton)
        [self setThemeState:CPThemeStateDefault];
    else
        [self unsetThemeState:CPThemeStateDefault];
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

@implementation CPButton (NS)

- (void)setBezelStyle:(unsigned)aBezelStyle
{
}

- (unsigned)bezelStyle
{
}

@end


var CPButtonImageKey                = @"CPButtonImageKey",
    CPButtonAlternateImageKey       = @"CPButtonAlternateImageKey",
    CPButtonTitleKey                = @"CPButtonTitleKey",
    CPButtonAlternateTitleKey       = @"CPButtonAlternateTitleKey",
    CPButtonIsBorderedKey           = @"CPButtonIsBorderedKey";

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

        [self setImage:[aCoder decodeObjectForKey:CPButtonImageKey]];
        [self setAlternateImage:[aCoder decodeObjectForKey:CPButtonAlternateImageKey]];
        
        [self setTitle:[aCoder decodeObjectForKey:CPButtonTitleKey]];
        [self setAlternateTitle:[aCoder decodeObjectForKey:CPButtonAlternateTitleKey]];
        
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

    [aCoder encodeObject:_image forKey:CPButtonImageKey];
    [aCoder encodeObject:_alternateImage forKey:CPButtonAlternateImageKey];

    [aCoder encodeObject:_title forKey:CPButtonTitleKey];
    [aCoder encodeObject:_alternateTitle forKey:CPButtonAlternateTitleKey];
}

@end

@import "CPCheckBox.j"
@import "CPRadio.j"
