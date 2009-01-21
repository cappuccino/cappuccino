/*
 * CPImageView.j
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

@import <Foundation/CPNotificationCenter.j>

@import "CPControl.j"
@import "CPImage.j"
@import "CPShadowView.j"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

#include "CoreGraphics/CGGeometry.h"


/*
    @global
    @group CPImageScaling
*/
CPScaleProportionally   = 0;
/*
    @global
    @group CPImageScaling
*/
CPScaleToFit            = 1;
/*
    @global
    @group CPImageScaling
*/
CPScaleNone             = 2;


var CPImageViewShadowBackgroundColor = nil;
    
var LEFT_SHADOW_INSET       = 3.0,
    RIGHT_SHADOW_INSET      = 3.0,
    TOP_SHADOW_INSET        = 3.0,
    BOTTOM_SHADOW_INSET     = 5.0,
    VERTICAL_SHADOW_INSET   = TOP_SHADOW_INSET + BOTTOM_SHADOW_INSET,
    HORIZONTAL_SHADOW_INSET = LEFT_SHADOW_INSET + RIGHT_SHADOW_INSET;

/*! @class CPImageView

    This class is a control that displays an image.
*/
@implementation CPImageView : CPControl
{
    DOMElement      _DOMImageElement;
    
    CPImageScaling  _imageScaling;
    
    BOOL            _hasShadow;
    CPView          _shadowView;
    
    CGRect          _imageRect;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
#if PLATFORM(DOM)
        _DOMImageElement = document.createElement("img");
        _DOMImageElement.style.position = "absolute";
        _DOMImageElement.style.left = "0px";
        _DOMImageElement.style.top = "0px";
    
        CPDOMDisplayServerAppendChild(_DOMElement, _DOMImageElement);
        
        _DOMImageElement.style.visibility = "hidden";
#endif
    }
    
    return self;
}

/*!
    Returns the view's image.
*/
- (CPImage)image
{
    return [self objectValue];
}

- (void)setImage:(CPImage)anImage
{
    [self setObjectValue:anImage];
}

/*! @ignore */
- (void)setObjectValue:(CPImage)anImage
{
    var oldImage = [self objectValue];
    
    if (oldImage === anImage)
        return;
        
    [super setObjectValue:anImage];
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (oldImage)
        [defaultCenter removeObserver:self name:CPImageDidLoadNotification object:oldImage];

    var newImage = [self objectValue];
    
#if PLATFORM(DOM)
    _DOMImageElement.src = newImage ? [newImage filename] : "";
#endif

    var size = [newImage size];
    
    if (size && size.width === -1 && size.height === -1)
    {
        [defaultCenter addObserver:self selector:@selector(imageDidLoad:) name:CPImageDidLoadNotification object:newImage];
        
#if PLATFORM(DOM)
        _DOMImageElement.width = 0;
        _DOMImageElement.height = 0;
#endif

        [_shadowView setHidden:YES];
    }
    else
    {
        [self hideOrDisplayContents];
        [self tile];
    }
}

- (void)imageDidLoad:(CPNotification)aNotification
{
    [self hideOrDisplayContents];
    [self tile];
}

/*!
    Returns <code>YES</code> if the image view draws with
    a drop shadow. The default is <code>NO</code>.
*/
- (BOOL)hasShadow
{
    return _hasShadow;
}

/*!
    Sets whether the image view should draw with a drop shadow.
    @param shouldHaveShadow whether the image view should have a shadow
*/
- (void)setHasShadow:(BOOL)shouldHaveShadow
{
    if (_hasShadow == shouldHaveShadow)
        return;
    
    _hasShadow = shouldHaveShadow;

    if (_hasShadow)
    {
        _shadowView = [[CPShadowView alloc] initWithFrame:[self bounds]];
                        
        [self addSubview:_shadowView];
        
        [self tile];
    }
    else
    {
        [_shadowView removeFromSuperview];
        
        _shadowView = nil;
    }
    
    [self hideOrDisplayContents];
}

/*!
    Sets the type of image scaling that should be used to
    render the image.
    @param anImageScaling the type of scaling to use
*/
- (void)setImageScaling:(CPImageScaling)anImageScaling
{
    if (_imageScaling == anImageScaling)
        return;
    
    _imageScaling = anImageScaling;
    
#if PLATFORM(DOM)
    if (_imageScaling == CPScaleToFit)
    {
        CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, 0.0, 0.0);
    }
#endif
    
    [self tile];
}

/*!
    Returns the image scaling method used to
    render this image.
*/
- (CPImageScaling)imageScaling
{
    return _imageScaling;
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    [self tile];
}

/*!
    Toggles the display of the image view.
*/
- (void)hideOrDisplayContents
{
    if (![self image])
    {
#if PLATFORM(DOM)
        _DOMImageElement.style.visibility = "hidden";
#endif
        [_shadowView setHidden:YES];
    }
    else
    {
#if PLATFORM(DOM)
        _DOMImageElement.style.visibility = "visible";
#endif
        [_shadowView setHidden:NO];
    }
}

/*!
    Returns the view's image rectangle
*/
- (CGRect)imageRect
{
    return _imageRect;
}

/*!
    Add a description
*/
- (void)tile
{
    if (![self image])
        return;

    var bounds = [self bounds],
        image = [self image],
        x = 0.0,
        y = 0.0,
        insetWidth = (_hasShadow ? HORIZONTAL_SHADOW_INSET : 0.0),
        insetHeight = (_hasShadow ? VERTICAL_SHADOW_INSET : 0.0),
        boundsWidth = _CGRectGetWidth(bounds),
        boundsHeight = _CGRectGetHeight(bounds),
        width = boundsWidth - insetWidth,
        height = boundsHeight - insetHeight;
        
    if (_imageScaling == CPScaleToFit)
    {
#if PLATFORM(DOM)
        _DOMImageElement.width = ROUND(width);
        _DOMImageElement.height = ROUND(height);
#endif
    }
    else
    {
        var size = [image size];
        
        if (size.width == -1 && size.height == -1)
            return;

        if (_imageScaling == CPScaleProportionally)
        {
            // The max size it can be is size.width x size.height, so only
            // only proportion otherwise.
            if (width >= size.width && height >= size.height)
            {
                width = size.width;
                height = size.height;
            }
            else
            {
                var imageRatio = size.width / size.height,
                    viewRatio = width / height;
                    
                if (viewRatio > imageRatio)
                    width = height * imageRatio;
                else
                    height = width / imageRatio;
            }

#if PLATFORM(DOM)
            _DOMImageElement.width = ROUND(width);
            _DOMImageElement.height = ROUND(height);
#endif
        }
        else
        {
            width = size.width;
            height = size.height;
        }
    
        if (_imageScaling == CPScaleNone)
        {
#if PLATFORM(DOM)
            _DOMImageElement.width = ROUND(size.width);
            _DOMImageElement.height = ROUND(size.height);
#endif
        }

        var x = (boundsWidth - width) / 2.0,
            y = (boundsHeight - height) / 2.0;

#if PLATFORM(DOM)
        CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, x, y);
#endif
    }

    _imageRect = _CGRectMake(x, y, width, height);
    
    if (_hasShadow)
        [_shadowView setFrame:_CGRectMake(x - LEFT_SHADOW_INSET, y - TOP_SHADOW_INSET, width + insetWidth, height + insetHeight)];
}

- (void)mouseDown:(CPEvent)anEvent
{
    // Should we do something with this event?
    [[self nextResponder] mouseDown:anEvent];
}

@end

var CPImageViewImageKey         = @"CPImageViewImageKey",
    CPImageViewImageScalingKey  = @"CPImageViewImageScalingKey",
    CPImageViewHasShadowKey     = @"CPImageViewHasShadowKey";

@implementation CPImageView (CPCoding)

/*!
    Initializes the image view with the provided coder.
    @param aCoder the coder from which data will be read.
    @return the initialized image view
*/
- (id)initWithCoder:(CPCoder)aCoder
{
#if PLATFORM(DOM)
    _DOMImageElement = document.createElement("img");
    _DOMImageElement.style.position = "absolute";
    _DOMImageElement.style.left = "0px";
    _DOMImageElement.style.top = "0px";
    _DOMImageElement.style.visibility = "hidden";
#endif

    self = [super initWithCoder:aCoder];
    
    if (self)
    {
#if PLATFORM(DOM)
        _DOMElement.appendChild(_DOMImageElement);
#endif

        [self setImageScaling:[aCoder decodeIntForKey:CPImageViewImageScalingKey]];
        [self setHasShadow:[aCoder decodeBoolForKey:CPImageViewHasShadowKey]];
        
        [self tile];
    }
    
    return self;
}

/*!
    Writes the image view out to the coder.
    @param aCoder the coder to which the image
    view will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    // We do this in order to avoid encoding the _shadowView, which 
    // should just automatically be created programmatically as needed.
    if (_shadowView)
    {
        var actualSubviews = _subviews;
        
        _subviews = [_subviews copy];
        [_subviews removeObjectIdenticalTo:_shadowView];
    }
        
    [super encodeWithCoder:aCoder];
    
    if (_shadowView)
        _subviews = actualSubviews;
    
    [aCoder encodeInt:_imageScaling forKey:CPImageViewImageScalingKey];
    [aCoder encodeBool:_hasShadow forKey:CPImageViewHasShadowKey];
}

@end
