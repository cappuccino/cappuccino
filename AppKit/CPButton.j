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

import "_CPImageAndTitleView.j"
import "CGGeometry.j"

import "CPControl.j"

#include "CoreGraphics/CGGeometry.h"


CPScaleProportionally   = 0;
CPScaleToFit            = 1;
CPScaleNone             = 2;

CPNoImage       = 0;
CPImageOnly     = 1;
CPImageLeft     = 2;
CPImageRight    = 3;
CPImageBelow    = 4;
CPImageAbove    = 5;
CPImageOverlaps = 6;

CPOnState       = 1;
CPOffState      = 0;
CPMixedState    = -1;

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

CPMomentaryLightButton   = 0;
CPPushOnPushOffButton    = 1;
CPToggleButton           = 2;
CPSwitchButton           = 3;
CPRadioButton            = 4;
CPMomentaryChangeButton  = 5;
CPOnOffButton            = 6;
CPMomentaryPushInButton  = 7;
CPMomentaryPushButton    = 0;
CPMomentaryLight         = 7;


var CPHUDBezelStyleTextColor = nil;

var _CPButtonClassName                          = nil,
    _CPButtonBezelStyleSizes                    = {},
    _CPButtonBezelStyleIdentifiers              = {},
    _CPButtonBezelStyleHighlightedIdentifier    = @"Highlighted";

@implementation CPButton : CPControl
{
    int                     _tag;
    int                     _state;
    BOOL                    _allowsMixedState;
    BOOL                    _isHighlighted;
    
    CPImage                 _image;
    CPImage                 _alternateImage;
    
    CPCellImagePosition     _imagePosition;
    CPImageScaling          _imageScalng;
    
    CPString                _title;
    CPString                _alternateTitle;

    CPBezelStyle            _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
    
    BOOL                    _bezelBorderNeedsUpdate;
    
    _CPImageAndTitleView    _imageAndTitleView;
}

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

- (void)setButtonType:(CPButtonType)aButtonType
{
    if (aButtonType == CPSwitchButton)
    {
        [self setBordered:NO];
        [self setImage:nil];
        [self setAlternateImage:nil];
        [self setAlignment:CPLeftTextAlignment];
    }
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _imagePosition = CPNoImage;
        _imageScaling = CPScaleNone;
        
        _controlSize = CPRegularControlSize;
        
        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];
        
        [self setAlignment:CPCenterTextAlignment];
    }
    
    return self;
}

- (void)setImagePosition:(CPCellImagePosition)anImagePosition
{
    if (_imagePosition == anImagePosition)
        return;
    
    _imagePosition = anImagePosition;
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (CPCellImagePosition)imagePosition
{
    return _imagePosition;
}

- (void)setImageScaling:(CPImageScaling)anImageScaling
{
    if (_imageScaling == anImageScaling)
        return;
    
    _imageScaling = anImageScaling;
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (CPImageScaling)imageScaling
{
    return _imageScaling;
}

- (void)setTextColor:(CPColor)aColor
{
    [super setTextColor:aColor];
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (void)setFont:(CPFont)aFont
{
    [super setFont:aFont];
    
    [self drawContentsWithHighlight:_isHighlighted];
}

// Setting the state

- (BOOL)allowsMixedState
{
    return _allowsMixedState;
}

- (void)setAllowsMixedState:(BOOL)aFlag
{
    _allowsMixedState = aFlag;
}

- (void)setNextState
{
    if (_state == CPOffState)
        _state = CPOnState;
    else
        _state = (_state >= CPOnState && _allowsMixedState) ? CPMixedState : CPOffState;
}

- (void)setState:(int)aState
{
    _state = aState;
}

- (int)state
{
    return _state;
}

- (void)setAlignment:(CPTextAlignment)anAlignment
{
    [super setAlignment:anAlignment];
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;
    
    _image = anImage;
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (CPImage)image
{
    return _image;
}

- (void)setAlternateImage:(CPImage)anImage
{
    _alternateImage = anImage;
}

- (CPImage)alternateImage
{
    return _alternateImage;
}

- (void)setTitle:(CPString)aTitle
{
    if (_title == aTitle)
        return;
    
    _title = aTitle;
    
    [self drawContentsWithHighlight:_isHighlighted];
}

- (CPString)title
{
    return _title;
}

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
    
        [_imageAndTitleView setFrameSize:imageAndTitleSize];
    }
    else
        [_imageAndTitleView setFrameSize:size];
}

- (void)sizeToFit
{
    [_imageAndTitleView sizeToFit];
    
    var frame = [_imageAndTitleView frame],
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

- (void)setFrameSize:(CPSize)aSize
{
    [super setFrameSize:aSize];

    [self tile];
}

- (void)highlight:(BOOL)aFlag
{
    [self drawBezelWithHighlight:aFlag];
    [self drawContentsWithHighlight:aFlag];
}

- (void)setTag:(int)aTag
{
    _tag = aTag;
}

- (int)tag
{
    return _tag;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _isHighlighted = YES;
    
    [self highlight:_isHighlighted];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    _isHighlighted = CGRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]);
    
    [self highlight:_isHighlighted];
}

- (void)mouseUp:(CPEvent)anEvent
{
    _isHighlighted = NO;
    
    [self highlight:_isHighlighted];

    [super mouseUp:anEvent];
}

// FIXME: This probably belongs in CPControl.
- (void)setControlSize:(CPControlSize)aControlSize
{
    if (_controlSize == aControlSize)
        return;
    
    _controlSize = aControlSize;
    
    [self drawBezelWithHighlight:_isHighlighted];
    [self _updateTextAttributes];
}

- (CPControlSize)controlSize
{
    return _controlSize;
}

- (void)setBordered:(BOOL)isBordered
{
    if (_isBordered == isBordered)
        return;
    
    _isBordered = isBordered;
    
    [self updateBackgroundColors];
    [self drawBezelWithHighlight:_isHighlighted];
    
    [self tile];
}

- (BOOL)isBordered
{
    return _isBordered;
}

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

- (int)bezelStyle
{
    return _bezelStyle;
}

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

- (void)drawBezelWithHighlight:(BOOL)shouldHighlight
{   
    _bezelBorderNeedsUpdate = ![self window];
    
    if (_bezelBorderNeedsUpdate)
        return;
    
    [self setBackgroundColorWithName:shouldHighlight ? CPControlHighlightedBackgroundColor : CPControlNormalBackgroundColor];
}

- (void)drawContentsWithHighlight:(BOOL)isHighlighted
{
    if (!_title && !_image && !_alternateTitle && !_alternateImage && !_imageAndTitleView)
        return;
    
    if (!_imageAndTitleView)
    {
        _imageAndTitleView = [[_CPImageAndTitleView alloc] initWithFrame:[self bounds]];
                
        [self addSubview:_imageAndTitleView];
        
        [self tile];
    }
        
    [_imageAndTitleView setFont:[self font]];
    [_imageAndTitleView setTextColor:[self textColor]];
    [_imageAndTitleView setAlignment:[self alignment]];
    [_imageAndTitleView setImagePosition:_imagePosition];
    [_imageAndTitleView setImageScaling:_imageScaling];
        
    [_imageAndTitleView setTitle:isHighlighted && _alternateTitle ? _alternateTitle : _title];
    [_imageAndTitleView setImage:isHighlighted && _alternateImage ? _alternateImage : _image];
}

- (void)viewDidMoveToWindow
{
    if (_bezelBorderNeedsUpdate)
        [self drawBezelWithHighlight:_isHighlighted];
}

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

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // We do this in order to avoid encoding the _imageAndTitleView, which 
    // should just automatically be created programmatically as needed.
    var actualSubviews = _subviews;
    
    _subviews = [_subviews copy];
    [_subviews removeObjectIdenticalTo:_imageAndTitleView];
    
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
