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

import "CPImage.j"
import "CPControl.j"
import "CPShadowView.j"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

#include "CoreGraphics/CGGeometry.h"


CPScaleProportionally   = 0;
CPScaleToFit            = 1;
CPScaleNone             = 2;


var CPImageViewShadowBackgroundColor = nil;
    
var LEFT_SHADOW_INSET       = 3.0,
    RIGHT_SHADOW_INSET      = 3.0,
    TOP_SHADOW_INSET        = 3.0,
    BOTTOM_SHADOW_INSET     = 5.0,
    VERTICAL_SHADOW_INSET   = TOP_SHADOW_INSET + BOTTOM_SHADOW_INSET,
    HORIZONTAL_SHADOW_INSET = LEFT_SHADOW_INSET + RIGHT_SHADOW_INSET;

@implementation CPImageView : CPControl
{
    CPImage         _image;
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

- (CPImage)image
{
    return _image;
}

- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;
    
    _image = anImage;
    
    _DOMImageElement.src = [anImage filename];
    
    if (_imageScaling == CPScaleNone && _image)
    {
        var size = [_image size];
        
        _DOMImageElement.width = ROUND(size.width);
        _DOMImageElement.height = ROUND(size.height);
    }
    
    [self hideOrDisplayContents];
    
    [self tile];
}

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

- (void)setImageScaling:(CPImageScaling)anImageScaling
{
    if (_imageScaling == anImageScaling)
        return;
    
    _imageScaling = anImageScaling;
    
    if (_imageScaling == CPScaleToFit)
    {
        CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, 0.0, 0.0);
    }
    else if (_imageScaling == CPScaleNone && _image)
    {
        var size = [_image size];
        
        _DOMImageElement.width = ROUND(size.width);
        _DOMImageElement.height = ROUND(size.height);
    }
    
    [self tile];
}

- (CPImageScaling)imageScaling
{
    return _imageScaling;
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    [self tile];
}

- (void)hideOrDisplayContents
{
    if (!_image)
    {
        _DOMImageElement.style.visibility = "hidden";
        [_shadowView setHidden:YES];
    }
    else
    {
        _DOMImageElement.style.visibility = "visible";
        [_shadowView setHidden:NO];
    }
}

- (CGRect)imageRect
{
    return _imageRect;
}

- (void)tile
{
    if (!_image)
        return;
        
    var bounds = [self bounds],
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
        _DOMImageElement.width = ROUND(width);
        _DOMImageElement.height = ROUND(height);
    }
    else
    {
        var size = [_image size];
        
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
            
            _DOMImageElement.width = ROUND(width);
            _DOMImageElement.height = ROUND(height);
        }
        else
        {
            width = size.width;
            height = size.height;
        }
    
        var x = (boundsWidth - width) / 2.0,
            y = (boundsHeight - height) / 2.0;
            
        CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, x, y);
    }

    _imageRect = _CGRectMake(x, y, width, height);
    
    if (_hasShadow)
        [_shadowView setFrame:_CGRectMake(x - LEFT_SHADOW_INSET, y - TOP_SHADOW_INSET, width + insetWidth, height + insetHeight)];
}

@end

var CPImageViewImageKey         = @"CPImageViewImageKey",
    CPImageViewImageScalingKey  = @"CPImageViewImageScalingKey",
    CPImageViewHasShadowKey     = @"CPImageViewHasShadowKey";

@implementation CPImageView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _DOMImageElement = document.createElement("img");
        _DOMImageElement.style.position = "absolute";
        _DOMImageElement.style.left = "0px";
        _DOMImageElement.style.top = "0px";
    
        _DOMElement.appendChild(_DOMImageElement);
        _DOMImageElement.style.visibility = "hidden";
        
        [self setImage:[aCoder decodeObjectForKey:CPImageViewImageKey]];
        
        [self setImageScaling:[aCoder decodeIntForKey:CPImageViewImageScalingKey]];
        [self setHasShadow:[aCoder decodeBoolForKey:CPImageViewHasShadowKey]];
        
        [self tile];
    }
    
    return self;
}

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
    
    [aCoder encodeObject:_image forKey:CPImageViewImageKey];
    
    [aCoder encodeInt:_imageScaling forKey:CPImageViewImageScalingKey];
    [aCoder encodeBool:_hasShadow forKey:CPImageViewHasShadowKey];
}

@end
