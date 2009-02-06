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
@import "CPThemedValue.j"

#include "CoreGraphics/CGGeometry.h"
#include "CPThemedValue.h"


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
    
    CPControlStateValue     _title;
    CPString                _alteranteTitle;
    
    CPControlStateValue     _image;
    CPImage                 _alternateImage;

    // Display Properties
    CPControlStateValue     _bezelInset;
    CPControlStateValue     _contentInset;
    
    CPControlStateValue     _bezelColor;

    // Layout Views
    CPView                  _bezelView;
    _CPImageAndTextView     _contentView;
    
    // NS-style Display Properties
    CPBezelStyle            _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        var theme = [self theme],
            theClass = [self class];
        
        _bezelInset = CPThemedValueMake(_CGInsetMakeZero(), "bezel-inset", theme, theClass);
        _contentInset = CPThemedValueMake(_CGInsetMakeZero(), "content-inset", theme, theClass);
        
        _bezelColor = CPThemedValueMake(nil, "bezel-color", theme, theClass);
        
        _image = CPThemedValueMake(nil, @"image", theme, theClass);
        _title = CPThemedValueMake(nil, @"title", theme, theClass);

        [self setAlignment:CPCenterTextAlignment];
        [self setVerticalAlignment:CPCenterVerticalTextAlignment];
        [self setImagePosition:CPImageLeft];
        [self setImageScaling:CPScaleNone];
        
        _controlSize = CPRegularControlSize;
        
//        [self setBezelStyle:CPRoundRectBezelStyle];
        [self setBordered:YES];
    }
    
    return self;
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

THEMED_STATED_VALUE(Title, title)

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

THEMED_STATED_VALUE(Image, image)

/*!
    Sets the button's image which is used in its alternate state.
    @param anImage the image to be used while the button is in an alternate state
*/
- (void)setAlternateImage:(CPImage)anImage
{
    if (_alternateImage === anImage)
        return;
    
    _alteranteImage = anImage;
    
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

/*!
    Highlights the receiver based on <code>aFlag</code>.
    @param If <code>YES</code> the button will highlight, <code>NO</code> the button will unhighlight.
*/
- (void)highlight:(BOOL)aFlag
{
    [super highlight:aFlag];
    
    [self drawBezelWithHighlight:aFlag];
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

/* @ignore */
- (void)drawBezelWithHighlight:(BOOL)shouldHighlight
{   return;
    _bezelBorderNeedsUpdate = ![self window];
    
    if (_bezelBorderNeedsUpdate)
        return;
    
    [self setBackgroundColorWithName:shouldHighlight ? CPControlHighlightedBackgroundColor : CPControlNormalBackgroundColor];
}

- (CPView)createBezelView
{
    var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

    [view setHitTests:NO];
    
    return view;
}

THEMED_STATED_VALUE(BezelColor, bezelColor)

- (CPView)createContentView
{
    var view = [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];
    
    return view;
}

THEMED_STATED_VALUE(ContentInset, contentInset)
THEMED_STATED_VALUE(BezelInset, bezelInset)

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    if (![self isBordered])
        return bounds;
        
    var contentInset = [self currentContentInset];
    
    if (!contentInset)
        return bounds;
    
    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;
    
    return bounds;
}

- (CGRect)bezelRectForBounds:(CFRect)bounds
{
    if (![self isBordered])
        return _CGRectMakeZero();

    var bezelInset = [self currentBezelInset];
    
    if (!_CGInsetIsEmpty(bezelInset))
        return bounds;
    
    bounds.origin.x += bezelInset.left;
    bounds.origin.y += bezelInset.top;
    bounds.size.width -= bezelInset.left + bezelInset.right;
    bounds.size.height -= bezelInset.top + bezelInset.bottom;
    
    return bounds;
}

- (void)layoutSubviews
{
    var bounds = [self bounds],
        bezelRect = [self bezelRectForBounds:_CGRectMakeCopy(bounds)];
    
    if (bezelRect && !_CGRectIsEmpty(bezelRect))
    {
        if (!_bezelView)
        {
            _bezelView = [self createBezelView];
            
            if (_bezelView)
                [self addSubview:_bezelView positioned:CPWindowBelow relativeTo:_contentView];
        }
        
        if (_bezelView)
            [_bezelView setFrame:bezelRect];
    }
    else if (_bezelView)
    {
        [_bezelView removeFromSuperview];
            
        _bezelView = nil;
    }
    
    if (_bezelView)
    {
        [_bezelView setBackgroundColor:[self bezelColor]];
    }
    
    var contentRect = [self contentRectForBounds:bounds];
    
    if (contentRect && !_CGRectIsEmpty(contentRect))
    {
        if (!_contentView)
        {
            _contentView = [self createContentView];
            
            if (_contentView)
                [self addSubview:_contentView positioned:CPWindowAbove relativeTo:_bezelView];
        }
        
        if (_contentView)
            [_contentView setFrame:contentRect];
    }
    else if (_contentView)
    {
        [_contentView removeFromSuperview];
        
        _contentView = nil;
    }
    
    if (_contentView)
    {
        [_contentView setText:[self currentTitle]];
        [_contentView setImage:[self currentImage]];
        
    //    [_imageAndTextView setText:[self titleForControlState:_title]];
    //    [_imageAndTextView setImage:[self imageForControlState:_controlState]];
    
        [_contentView setFont:[self currentFont]];
        [_contentView setTextColor:[self currentTextColor]];
        [_contentView setAlignment:[self currentAlignment]];
        [_contentView setVerticalAlignment:[self currentVerticalAlignment]];
        [_contentView setLineBreakMode:[self currentLineBreakMode]];
        [_contentView setTextShadowColor:[self currentTextShadowColor]];
        [_contentView setTextShadowOffset:[self currentTextShadowOffset]];
        [_contentView setImagePosition:[self currentImagePosition]];
        [_contentView setImageScaling:[self currentImageScaling]];
    }
}

@end

@implementation CPButton (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    [_bezelInset setTheme:theme];
    [_contentInset setTheme:theme];
    
    [_bezelColor setTheme:theme];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues];
    
    [values setObject:_bezelInset forKey:@"bezel-inset"];
    [values setObject:_contentInset forKey:@"content-inset"];

    [values setObject:_bezelColor forKey:@"bezel-color"];

    return values;
}

@end


@implementation CPButton (NS)

- (void)setBezelStyle:(unsigned)aBezelStyle
{
}

- (unsigned)bezelStyle
{
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (_isBordered === shouldBeBordered)
        return;
    
    _isBordered = shouldBeBordered;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isBordered
{
    return _isBordered;
}

@end


var CPButtonImageKey                = @"CPButtonImageKey",
    CPButtonAlternateImageKey       = @"CPButtonAlternateImageKey",
    CPButtonTitleKey                = @"CPButtonTitleKey",
    CPButtonAlteranteTitleKey       = @"CPButtonAlternateTitleKey",
    CPButtonContentInsetKey         = @"CPButtonContentInsetKey",
    CPButtonBezelInsetKey           = @"CPButtonBezelInsetKey",
    CPButtonBezelColorKey           = @"CPButtonBezelColorKey",
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
        
        var theme = [self theme],
            theClass = [self class];
        
        [self setAlternateImage:[aCoder decodeObjectForKey:CPButtonAlternateImageKey]];
        
        _image =  CPThemedValueDecode(aCoder, CPButtonImageKey, nil, @"image", theme, theClass);
        _title = CPThemedValueDecode(aCoder, CPButtonTitleKey, nil, @"title", theme, theClass);
                
        _contentInset = CPThemedValueDecode(aCoder, CPButtonContentInsetKey, _CGInsetMakeZero(), @"content-inset", theme, theClass);
        _bezelInset = CPThemedValueDecode(aCoder, CPButtonBezelInsetKey, _CGInsetMakeZero(), @"bezel-inset", theme, theClass);
        
        _bezelColor = CPThemedValueDecode(aCoder, CPButtonBezelColorKey, nil, @"bezel-color", theme, theClass);
    
        _isBordered = [aCoder decodeBoolForKey:CPButtonIsBorderedKey];
        
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
    // We do this in order to avoid encoding the _imageAndTextView, which 
    // should just automatically be created programmatically as needed.
    var actualSubviews = _subviews;
    
//    _subviews = [_subviews copy];
//    [_subviews removeObjectIdenticalTo:_imageAndTextView];
    
    [super encodeWithCoder:aCoder];
    
    _subviews = actualSubviews;
    

    [aCoder encodeObject:_alternateImage forKey:CPButtonAlternateImageKey];
    
    [aCoder encodeBool:_isBordered forKey:CPButtonIsBorderedKey];
    [aCoder encodeInt:_bezelStyle forKey:CPButtonBezelStyleKey];
    
    CPThemedValueEncode(aCoder, CPButtonImageKey, _image);
    CPThemedValueEncode(aCoder, CPButtonTitleKey, _title);

    CPThemedValueEncode(aCoder, CPButtonContentInsetKey, _contentInset);
    CPThemedValueEncode(aCoder, CPButtonBezelInsetKey, _bezelInset);

    CPThemedValueEncode(aCoder, CPButtonBezelColorKey, _bezelColor);
}

@end
