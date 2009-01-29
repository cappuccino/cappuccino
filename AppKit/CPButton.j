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

#include "CoreGraphics/CGGeometry.h"


CPScaleProportionally   = 0;
CPScaleToFit            = 1;
CPScaleNone             = 2;

/*
    @global
    @group CPCellImagePosition
*/
CPNoImage       = 0;
/*
    @global
    @group CPCellImagePosition
*/
CPImageOnly     = 1;
/*
    @global
    @group CPCellImagePosition
*/
CPImageLeft     = 2;
/*
    @global
    @group CPCellImagePosition
*/
CPImageRight    = 3;
/*
    @global
    @group CPCellImagePosition
*/
CPImageBelow    = 4;
/*
    @global
    @group CPCellImagePosition
*/
CPImageAbove    = 5;
/*
    @global
    @group CPCellImagePosition
*/
CPImageOverlaps = 6;

/*
    @global
    @class CPButton
*/
CPOnState       = 1;
/*
    @global
    @class CPButton
*/
CPOffState      = 0;
/*
    @global
    @class CPButton
*/
CPMixedState    = -1;

/*
    @global
    @group CPBezelStyle
*/
CPRoundedBezelStyle             = 1;
/*
    @global
    @group CPBezelStyle
*/
CPRegularSquareBezelStyle       = 2;
/*
    @global
    @group CPBezelStyle
*/
CPThickSquareBezelStyle         = 3;
/*
    @global
    @group CPBezelStyle
*/
CPThickerSquareBezelStyle       = 4;
/*
    @global
    @group CPBezelStyle
*/
CPDisclosureBezelStyle          = 5;
/*
    @global
    @group CPBezelStyle
*/
CPShadowlessSquareBezelStyle    = 6;
/*
    @global
    @group CPBezelStyle
*/
CPCircularBezelStyle            = 7;
/*
    @global
    @group CPBezelStyle
*/
CPTexturedSquareBezelStyle      = 8;
/*
    @global
    @group CPBezelStyle
*/
CPHelpButtonBezelStyle          = 9;
/*
    @global
    @group CPBezelStyle
*/
CPSmallSquareBezelStyle         = 10;
/*
    @global
    @group CPBezelStyle
*/
CPTexturedRoundedBezelStyle     = 11;
/*
    @global
    @group CPBezelStyle
*/
CPRoundRectBezelStyle           = 12;
/*
    @global
    @group CPBezelStyle
*/
CPRecessedBezelStyle            = 13;
/*
    @global
    @group CPBezelStyle
*/
CPRoundedDisclosureBezelStyle   = 14;
/*
    @global
    @group CPBezelStyle
*/
CPHUDBezelStyle                 = -1;


/*
    @global
    @group CPButtonType
*/
CPMomentaryLightButton   = 0;
/*
    @global
    @group CPButtonType
*/
CPPushOnPushOffButton    = 1;
/*
    @global
    @group CPButtonType
*/
CPToggleButton           = 2;
/*
    @global
    @group CPButtonType
*/
CPSwitchButton           = 3;
/*
    @global
    @group CPButtonType
*/
CPRadioButton            = 4;
/*
    @global
    @group CPButtonType
*/
CPMomentaryChangeButton  = 5;
/*
    @global
    @group CPButtonType
*/
CPOnOffButton            = 6;
/*
    @global
    @group CPButtonType
*/
CPMomentaryPushInButton  = 7;
/*
    @global
    @group CPButtonType
*/
CPMomentaryPushButton    = 0;
/*
    @global
    @group CPButtonType
*/
CPMomentaryLight         = 7;


var CPHUDBezelStyleTextColor = nil;

var _CPButtonClassName                          = nil,
    _CPButtonBezelStyleSizes                    = {},
    _CPButtonBezelStyleIdentifiers              = {},
    _CPButtonBezelStyleHighlightedIdentifier    = @"Highlighted";

/*! @class CPButton

    CPButton is a subclass of CPControl that
    intercepts mouse-down events and sends an action message to a
    target object when it's clicked or pressed.
*/
@implementation CPButton : CPControl
{
    int                     _tag;
    int                     _state;
    BOOL                    _allowsMixedState;
    BOOL                    _isHighlighted;
    
    CPImage                 _image;
    CPImage                 _alternateImage;
    
    CPCellImagePosition     _imagePosition;
    CPImageScaling          _imageScaling;
    
    CPString                _title;
    CPString                _alternateTitle;

    CPBezelStyle            _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
    
    BOOL                    _bezelBorderNeedsUpdate;
    
    _CPImageAndTextView     _imageAndTextView;
}

/*!
    Initializes the CPButton class.
    @ignore
*/
+ (void)initialize
{
    if (self != [CPButton class])
        return;
    
    _CPButtonClassName = [CPButton className];

    // Textured Rounded
    _CPButtonBezelStyleIdentifiers[CPRoundedBezelStyle]             = @"Rounded";
    _CPButtonBezelStyleIdentifiers[CPRegularSquareBezelStyle]       = @"RegularSquare";
    _CPButtonBezelStyleIdentifiers[CPThickSquareBezelStyle]         = @"ThickSquare";
    _CPButtonBezelStyleIdentifiers[CPThickerSquareBezelStyle]       = @"ThickerSquare";
    _CPButtonBezelStyleIdentifiers[CPDisclosureBezelStyle]          = @"Disclosure";
    _CPButtonBezelStyleIdentifiers[CPShadowlessSquareBezelStyle]    = @"ShadowlessSquare";
    _CPButtonBezelStyleIdentifiers[CPCircularBezelStyle]            = @"Circular";
    _CPButtonBezelStyleIdentifiers[CPTexturedSquareBezelStyle]      = @"TexturedSquare";
    _CPButtonBezelStyleIdentifiers[CPHelpButtonBezelStyle]          = @"HelpButton";
    _CPButtonBezelStyleIdentifiers[CPSmallSquareBezelStyle]         = @"SmallSquare";
    _CPButtonBezelStyleIdentifiers[CPTexturedRoundedBezelStyle]     = @"TexturedRounded";
    _CPButtonBezelStyleIdentifiers[CPRoundRectBezelStyle]           = @"RoundRect";
    _CPButtonBezelStyleIdentifiers[CPRecessedBezelStyle]            = @"Recessed";
    _CPButtonBezelStyleIdentifiers[CPRoundedDisclosureBezelStyle]   = @"RoundedDisclosure";
    _CPButtonBezelStyleIdentifiers[CPHUDBezelStyle]                 = @"HUD";

    var regularIdentifier = _CPControlIdentifierForControlSize(CPRegularControlSize),
        smallIdentifier = _CPControlIdentifierForControlSize(CPSmallControlSize),
        miniIdentifier = _CPControlIdentifierForControlSize(CPMiniControlSize);

    // Rounded Rect
    var prefix = _CPButtonClassName + _CPButtonBezelStyleIdentifiers[CPRoundRectBezelStyle];
    
    _CPButtonBezelStyleSizes[prefix + regularIdentifier]                                            = [_CGSizeMake(10.0, 18.0), _CGSizeMake(1.0, 18.0), _CGSizeMake(10.0, 18.0)];
    _CPButtonBezelStyleSizes[prefix + regularIdentifier + _CPButtonBezelStyleHighlightedIdentifier] = [_CGSizeMake(10.0, 18.0), _CGSizeMake(1.0, 18.0), _CGSizeMake(10.0, 18.0)];
    
    // HUD
    var prefix = _CPButtonClassName + _CPButtonBezelStyleIdentifiers[CPHUDBezelStyle];    
    
    _CPButtonBezelStyleSizes[prefix + regularIdentifier]                                            = [_CGSizeMake(13.0, 20.0), _CGSizeMake(1.0, 20.0), _CGSizeMake(13.0, 20.0)];
    _CPButtonBezelStyleSizes[prefix + regularIdentifier + _CPButtonBezelStyleHighlightedIdentifier] = [_CGSizeMake(13.0, 20.0), _CGSizeMake(1.0, 20.0), _CGSizeMake(13.0, 20.0)];    

    CPHUDBezelStyleTextColor = [CPColor whiteColor];

    // Textured Rounded
    var prefix = _CPButtonClassName + _CPButtonBezelStyleIdentifiers[CPTexturedRoundedBezelStyle];    
    
    _CPButtonBezelStyleSizes[prefix + regularIdentifier]                                            = [_CGSizeMake(7.0, 20.0), _CGSizeMake(1.0, 20.0), _CGSizeMake(7.0, 20.0)];
    _CPButtonBezelStyleSizes[prefix + regularIdentifier + _CPButtonBezelStyleHighlightedIdentifier] = [_CGSizeMake(7.0, 20.0), _CGSizeMake(1.0, 20.0), _CGSizeMake(7.0, 20.0)];    
}

// Configuring Buttons
/*!
    Sets how the button highlights and shows its state.
    @param aButtonType Defines the behavior of the button.
*/
- (void)setButtonType:(CPButtonType)aButtonType
{
    if (aButtonType === CPSwitchButton)
    {
        [self setBordered:NO];
        [self setImage:nil];
        [self setAlternateImage:nil];
        [self setAlignment:CPLeftTextAlignment];
    }
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        [self setAlignment:CPCenterTextAlignment];
        [self setVerticalAlignment:CPCenterVerticalTextAlignment];
        [self setImagePosition:CPImageLeft];
        [self setImageScaling:CPScaleNone];
        
        _controlSize = CPRegularControlSize;
        
        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];
    }
    
    return self;
}

/*!
    Sets the position of the button's image to <code>anImagePosition</code>.
    @param anImagePosition the position for the button's image
*/
- (void)setImagePosition:(CPCellImagePosition)anImagePosition
{
    [super setImagePosition:anImagePosition];
    
    [_imageAndTextView setImagePosition:[self imagePosition]];
}

/*!
    Sets the button's images scaling method
    @param anImageScaling the image scaling method
*/
- (void)setImageScaling:(CPImageScaling)anImageScaling
{
    [super setImageScaling:anImageScaling];

    [_imageAndTextView setImageScaling:[self imageScaling]];
}

/*!
    Sets the color of the button's text
    @param aColor the color to use for drawing the button text
*/
- (void)setTextColor:(CPColor)aColor
{
    [super setTextColor:aColor];
    
    [_imageAndTextView setTextColor:[self textColor]];
}

/*!
    Sets the font that will be used to draw the button text
    @param aFont the font used to draw the button text
*/
- (void)setFont:(CPFont)aFont
{
    [super setFont:aFont];
    
    [_imageAndTextView setFont:[self font]];
}

// Setting the state
/*!
    Returns <code>YES</code> if the button has a 'mixed' state in addition to on and off.
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
    _allowsMixedState = aFlag;
}

/*!
    Sets the button to its next state.
*/
- (void)setNextState
{
    if (_state == CPOffState)
        _state = CPOnState;
    else
        _state = (_state >= CPOnState && _allowsMixedState) ? CPMixedState : CPOffState;
}

/*!
    Sets the button's state to <code>aState</code>.
    @param aState Possible states are any of the CPButton globals:
    <code>CPOffState, CPOnState, CPMixedState</code>
*/
- (void)setState:(int)aState
{
    _state = aState;
}

/*!
    Returns the button's current state
*/
- (int)state
{
    return _state;
}

/*!
    Sets the alignment of the text on the button.
    @param anAlignment an alignment object
*/
- (void)setAlignment:(CPTextAlignment)anAlignment
{
    [super setAlignment:anAlignment];
    
    [_imageAndTextView setAlignment:[self alignment]];
}

/*!
    Sets the image that will be drawn on the button.
    @param anImage the image that will be drawn
*/
- (void)setImage:(CPImage)anImage
{
    if (_image === anImage)
        return;
    
    _image = anImage;
    
    [self setNeedsDisplay:YES];
}

/*!
    Returns the image that will be drawn on the button
*/
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
    _alternateImage = anImage;
}

/*!
    Returns the image used when the button is in an alternate state.
*/
- (CPImage)alternateImage
{
    return _alternateImage;
}

/*!
    Sets the button's title.
    @param aTitle the new title for the button
*/
- (void)setTitle:(CPString)aTitle
{
    if (_title == aTitle)
        return;
    
    _title = aTitle;
    
    [self setNeedsDisplay:YES];
}

/*!
    Returns the button's title string
*/
- (CPString)title
{
    return _title;
}

/*!
    Lays out the button.
*/
- (void)tile
{
    var size = [self bounds].size;
    
    if (_isBordered)
    {
        var imageAndTitleSize = CGSizeMakeCopy(size);
    
        if (_bezelStyle == CPHUDBezelStyle)
            imageAndTitleSize.height -= 4.0;
        else if (_bezelStyle == CPRoundRectBezelStyle)
            imageAndTitleSize.height -= 2.0;
        else if (_bezelStyle == CPTexturedRoundedBezelStyle)
            imageAndTitleSize.height -= 2.0;
    
        [_imageAndTextView setFrameSize:imageAndTitleSize];
    }
    else
        [_imageAndTextView setFrameSize:size];
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    if (_isBordered)
    {
        if (_bezelStyle === CPHUDBezelStyle)
        {
            bounds.origin.x += 5.0;
            bounds.origin.y += 2.0;
            bounds.size.width -= 5.0 * 2;
            bounds.size.height -= 2.0 + 4.0;
        }
        
        else if (_bezelStyle === CPRoundRectBezelStyle)
        {
            bounds.origin.x += 5.0;
            bounds.origin.y += 1.0;
            bounds.size.width -= 5.0 * 2;
            bounds.size.height -= 1.0 + 2.0;
        }
        
        else if (_bezelStyle === CPTexturedRoundedBezelStyle)
        {
            bounds.origin.x += 5.0;
            bounds.origin.y += 2.0;
            bounds.size.width -= 5.0 * 2;
            bounds.size.height -= 2.0 + 3.0;
        }
    }

    return bounds;
}

- (void)drawRect:(CGRect)aRect
{
    if (!_imageAndTextView)
    {
        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:[self contentRectForBounds:[self bounds]] control:self];

        [self addSubview:_imageAndTextView];
    }
    else
        [_imageAndTextView setFrame:[self contentRectForBounds:[self bounds]]];

    [_imageAndTextView setText:_isHighlighted && _alternateTitle ? _alternateTitle : _title];
    [_imageAndTextView setImage:_isHighlighted && _alternateImage ? _alternateImage : _image];
}

/*!
    Compacts the button's frame to fit its contents.
*/
- (void)sizeToFit
{    if (!_imageAndTextView)
    {
        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:[self contentRectForBounds:[self bounds]] control:self];

        [self addSubview:_imageAndTextView];
    }
    
    [_imageAndTextView setText:_isHighlighted && _alternateTitle ? _alternateTitle : _title];
    [_imageAndTextView setImage:_isHighlighted && _alternateImage ? _alternateImage : _image];

    [_imageAndTextView sizeToFit];
    
    var frame = [_imageAndTextView frame],
        height = CGRectGetHeight(frame);
    /*
    if (_isBordered)
        if (_bezelStyle == CPHUDBezelStyle)
            height += 2.0;
        else if (_bezelStyle == CPRoundRectBezelStyle)
            height += 1.0;
        else if (_bezelStyle == CPTexturedRoundedBezelStyle)
            height += 2.0;
    */
    [self setFrameSize:CGSizeMake(CGRectGetWidth(frame), height)];
}

/*!
    Highlights the receiver based on <code>aFlag</code>.
    @param If <code>YES</code> the button will highlight, <code>NO</code> the button will unhighlight.
*/
- (void)highlight:(BOOL)aFlag
{
    _isHighlighted = aFlag;
    
    [self drawBezelWithHighlight:aFlag];
    [self setNeedsDisplay:YES];
}

/*!
    Sets button's tag.
    @param aTag the button's new tag
*/
- (void)setTag:(int)aTag
{
    _tag = aTag;
}

/*!
    Returns the button's tag.
*/
- (int)tag
{
    return _tag;
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
}

/*!
    Sets the button's control size.
    @param aControlSize the button's new control size
*/
- (void)setControlSize:(CPControlSize)aControlSize
{
    if (_controlSize == aControlSize)
        return;
    
    _controlSize = aControlSize;
    
    [self drawBezelWithHighlight:_isHighlighted];
    [self _updateTextAttributes];
}

/*!
    Returns the button's control size.
*/
- (CPControlSize)controlSize
{
    return _controlSize;
}

/*!
    Sets whether the button has a bezeled border.
    @param If <code>YES</code>, the the button will have a bezeled border.
*/
- (void)setBordered:(BOOL)isBordered
{
    if (_isBordered == isBordered)
        return;
    
    _isBordered = isBordered;
    
    [self updateBackgroundColors];
    [self drawBezelWithHighlight:_isHighlighted];
    
    [self tile];
}

/*!
    Returns <code>YES</code> if the border is bezeled.
*/
- (BOOL)isBordered
{
    return _isBordered;
}

/*!
    Sets the button's bezel style.
    @param aBezelStye one of the predefined bezel styles
*/
- (void)setBezelStyle:(CPBezelStyle)aBezelStyle
{
    // FIXME: We need real support for these:
    if (aBezelStyle == CPRoundedBezelStyle || 
        aBezelStyle == CPRoundedBezelStyle ||         
        aBezelStyle == CPRegularSquareBezelStyle ||
        aBezelStyle == CPThickSquareBezelStyle ||
        aBezelStyle == CPThickerSquareBezelStyle || 
        aBezelStyle == CPDisclosureBezelStyle || 
        aBezelStyle == CPShadowlessSquareBezelStyle || 
        aBezelStyle == CPCircularBezelStyle || 
        aBezelStyle == CPTexturedSquareBezelStyle || 
        aBezelStyle == CPHelpButtonBezelStyle || 
        aBezelStyle == CPSmallSquareBezelStyle || 
        aBezelStyle == CPRecessedBezelStyle || 
        aBezelStyle == CPRoundedDisclosureBezelStyle)
        aBezelStyle = CPRoundRectBezelStyle;

    if (_bezelStyle == aBezelStyle)
        return;
    
    _bezelStyle = aBezelStyle;
    
    [self updateBackgroundColors];
    [self drawBezelWithHighlight:_isHighlighted];
    
    [self _updateTextAttributes];
    [self tile];
}

/*!
    Returns the current bezel style
*/
- (int)bezelStyle
{
    return _bezelStyle;
}

/* @ignore */
- (void)updateBackgroundColors
{
    if (_isBordered)
    {
        [self setBackgroundColor:_CPControlThreePartImagePattern(
            NO,
            _CPButtonBezelStyleSizes,
            _CPButtonClassName,
            _CPButtonBezelStyleIdentifiers[_bezelStyle],
            _CPControlIdentifierForControlSize(_controlSize)) forName:CPControlNormalBackgroundColor];
            
        [self setBackgroundColor:_CPControlThreePartImagePattern(
            NO,
            _CPButtonBezelStyleSizes,
            _CPButtonClassName,
            _CPButtonBezelStyleIdentifiers[_bezelStyle],
            _CPControlIdentifierForControlSize(_controlSize),
            _CPButtonBezelStyleHighlightedIdentifier) forName:CPControlHighlightedBackgroundColor];
    }
    else
    {
        [self setBackgroundColor:nil forName:CPControlNormalBackgroundColor];
        [self setBackgroundColor:nil forName:CPControlHighlightedBackgroundColor];
    }
}

/* @ignore */
- (void)drawBezelWithHighlight:(BOOL)shouldHighlight
{   
    _bezelBorderNeedsUpdate = ![self window];
    
    if (_bezelBorderNeedsUpdate)
        return;
    
    [self setBackgroundColorWithName:shouldHighlight ? CPControlHighlightedBackgroundColor : CPControlNormalBackgroundColor];
}

- (void)viewDidMoveToWindow
{
    if (_bezelBorderNeedsUpdate)
        [self drawBezelWithHighlight:_isHighlighted];
}

/* @ignore */
- (void)_updateTextAttributes
{
    if (_bezelStyle == CPHUDBezelStyle)
        [self setTextColor:CPHUDBezelStyleTextColor];
    
    if (_controlSize == CPRegularControlSize)
        [self setFont:[CPFont systemFontOfSize:11.0]];
}

@end


var CPButtonImageKey                = @"CPButtonImageKey",
    CPButtonAlternateImageKey       = @"CPButtonAlternateImageKey",
    CPButtonTitleKey                = @"CPButtonTitleKey",
    CPButtonAlteranteTitleKey       = @"CPButtonAlternateTitleKey",
    CPButtonImageAndTitleViewKey    = @"CPButtonImageAndTitleViewKey",
    CPButtonImagePositionKey        = @"CPButtonImagePositionKey",
    CPButtonImageScalingKey         = @"CPButtonImageScalingKey",
    CPButtonIsBorderedKey           = @"CPButtonIsBorderedKey",
    CPButtonBezelStyleKey           = @"CPButtonBezelStyleKey",
    CPButtonImageAndTitleViewKey    = @"CPButtonImageAndTitleViewKey";

@implementation CPButton (CPCoding)

/*!
    Initializes the button by unarchiving data from <code>aCoder</code>.
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
        
        [self setImagePosition:[aCoder decodeIntForKey:CPButtonImagePositionKey]];
        [self setImageScaling:[aCoder decodeIntForKey:CPButtonImageScalingKey]];
    
        [self setBezelStyle:[aCoder decodeIntForKey:CPButtonBezelStyleKey]];
        [self setBordered:[aCoder decodeBoolForKey:CPButtonIsBorderedKey]];
    }
    
    return self;
}

/*!
    Archives this button into the provided coder.
    @param aCoder the coder to which the button's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    // We do this in order to avoid encoding the _imageAndTextView, which 
    // should just automatically be created programmatically as needed.
    var actualSubviews = _subviews;
    
    _subviews = [_subviews copy];
    [_subviews removeObjectIdenticalTo:_imageAndTextView];
    
    [super encodeWithCoder:aCoder];
    
    _subviews = actualSubviews;
    
    [aCoder encodeObject:_image forKey:CPButtonImageKey];
    [aCoder encodeObject:_alternateImage forKey:CPButtonAlternateImageKey];
    
    [aCoder encodeObject:_title forKey:CPButtonTitleKey];
    
    [aCoder encodeInt:_imagePosition forKey:CPButtonImagePositionKey];
    [aCoder encodeInt:_imageScaling forKey:CPButtonImageScalingKey];
    
    [aCoder encodeBool:_isBordered forKey:CPButtonIsBorderedKey];
    [aCoder encodeInt:_bezelStyle forKey:CPButtonBezelStyleKey];
}

@end
