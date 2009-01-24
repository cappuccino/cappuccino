/*
 * _CPImageAndTextView.j
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

@import <Foundation/CPString.j>

@import "CPColor.j"
@import "CPFont.j"
@import "CPImage.j"
@import "CPTextField.j"
@import "CPView.j"

#include "CoreGraphics/CGGeometry.h"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

var _CPImageAndTextViewTextChangedFlag  = 1 << 0,
    _CPImageAndTextViewImageChangedFlag = 1 << 1;

/* @ignore */
@implementation _CPImageAndTextView : CPView
{
    CPTextAlignment     _alignment;
    CPColor             _textColor;
    CPFont              _font;
    
    CPCellImagePosition _imagePosition;
    CPImageScaling      _imageScaling;
    
    CPImage             _image;
    CPString            _text;
    
    CGRect              _textSize;

    unsigned            _flags;

#if PLATFORM(DOM)
    DOMElement          _DOMImageElement;
    DOMELement          _DOMTextElement;
#endif
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        [self setAlignment:CPCenterTextAlignment];
        [self setFont:[CPFont systemFontOfSize:12.0]];
        [self setImagePosition:CPNoImage];
        [self setImageScaling:CPScaleNone];

        _textColor = nil;
        
        _textSize = NULL;
    }
    
    return self;
}

- (void)setAlignment:(CPTextAlignment)anAlignment
{
    if (_alignment === anAlignment)
        return;
    
    _alignment = anAlignment;
    
#if PLATFORM(DOM)
    switch (_alignment)
    {
        case CPLeftTextAlignment:       _DOMElement.style.textAlign = "left";
                                        break;
        case CPRightTextAlignment:      _DOMElement.style.textAlign = "right";
                                        break;
        case CPCenterTextAlignment:     _DOMElement.style.textAlign = "center";
                                        break;
        case CPJustifiedTextAlignment:  _DOMElement.style.textAlign = "justify";
                                        break;
        case CPNaturalTextAlignment:    _DOMElement.style.textAlign = "";
                                        break;
    }
#endif
}

- (CPTextAlignment)alignment
{
    return _alignment;
}

- (void)setImagePosition:(CPCellImagePosition)anImagePosition
{
    if (_imagePosition == anImagePosition)
        return;
    
    _imagePosition = anImagePosition;
    
    [self setNeedsDisplay:YES];
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

    [self setNeedsDisplay:YES];
}

- (void)imageScaling
{
    return _imageScaling;
}

- (void)setTextColor:(CPColor)aTextColor
{
    if (_textColor == aTextColor)
        return;
    
    _textColor = aTextColor;
    
#if PLATFORM(DOM)
    _DOMElement.style.color = [_textColor cssString];
#endif
}

- (CPColor)textColor
{
    return _textColor;
}

- (void)setFont:(CPFont)aFont
{
    if (_font === aFont)
        return;
    
    _font = aFont;
    
#if PLATFORM(DOM)
    _DOMElement.style.font = [_font ? _font : [CPFont systemFontOfSize:12.0] cssString];
#endif
    
    _textSize = NULL;
    
    [self setNeedsDisplay:YES];
}

- (CPFont)font
{
    return _font;
}

- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;
    
    _image = anImage;
    _flags |= _CPImageAndTextViewImageChangedFlag;
    
    [self setNeedsDisplay:YES];
}

- (CPImage)image
{
    return _image;
}

- (void)setTitle:(CPString)aTitle
{
    if (_text === aTitle)
        return;
    
    _text = aTitle;
    _flags |= _CPImageAndTextViewTextChangedFlag;
    
    _textSize = NULL;
    
    [self setNeedsDisplay:YES];
}

- (CPString)title
{
    return _text;
}

- (void)drawRect:(CGRect)aRect
{
#if PLATFORM(DOM)
    var needsDOMTextElement = _imagePosition !== CPImageOnly && ([_text length] > 0);
    
    // Create or destroy the DOM Text Element as necessary
    if (needsDOMTextElement !== !!_DOMTextElement)    
        if (_DOMTextElement)
        {
            _DOMElement.removeChild(_DOMTextElement);
            _DOMTextElement = NULL;
        }
        
        else
        {
            _DOMTextElement = document.createElement("div");
//            _DOMTextElement.style.background = "red";
            _DOMTextElement.style.position = "absolute";
            _DOMTextElement.style.whiteSpace = "pre";
            _DOMTextElement.style.cursor = "default";
            _DOMTextElement.style.zIndex = 100;
            _DOMTextElement.style.overflow = "hidden";
    
            _DOMElement.appendChild(_DOMTextElement);
        }
        
    if (_DOMTextElement)
    {   
        if (_flags & _CPImageAndTextViewTextChangedFlag)
            if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
                _DOMTextElement.innerText = _text;
        
            else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
                _DOMTextElement.textContent = _text;
            
        if (!_textSize)
            _textSize = [_text sizeWithFont:_font];
    }
    
    var needsDOMImageElement = _image !== nil;

    // Create or destroy DOM Image element    
    if (needsDOMImageElement !== !!_DOMImageElement)
        if (_DOMImageElement)
        {
            _DOMElement.removeChild(_DOMImageElement);
        
            _DOMImageElement = NULL;
        }
        
        else
        {
            _DOMImageElement = document.createElement("img");

            _DOMImageElement.style.top = "0px";
            _DOMImageElement.style.left = "0px";
            _DOMImageElement.style.position = "absolute";
            _DOMImageElement.style.zIndex = 100;

            _DOMElement.appendChild(_DOMImageElement);
        }
    
    if (_DOMImageElement && (_flags & _CPImageAndTextViewImageChangedFlag))
        _DOMImageElement.src = [_image filename];
#endif

    _flags = 0;
        
    var size = [self bounds].size,
        centerX = size.width / 2.0,
        centerY = size.height / 2.0,
        titleHeight = _DOMTextElement ? _textSize.height : 0.0,
        titleRect = _CGRectMake(0.0, centerY - titleHeight / 2.0, size.width, titleHeight);

    if ((_imagePosition !== CPNoImage) && _image)
    {
        var imageSize = [_image size], 
            imageWidth = imageSize.width,
            imageHeight = imageSize.height;
        
        if (_imageScaling === CPScaleToFit)
        {
            imageWidth = size.width;
            imageHeight = size.height;
        }
        else if (_imageScaling === CPScaleProportionally)
        {
            var scale = MIN(MIN(size.width, imageWidth) / imageWidth, MIN(size.height, imageHeight) / imageHeight);
    
            imageWidth *= scale;
            imageHeight *= scale;
        }

#if PLATFORM(DOM)
        _DOMImageElement.width = imageWidth;
        _DOMImageElement.height = imageHeight;        
        _DOMImageElement.style.width = imageWidth + "px";
        _DOMImageElement.style.height = imageHeight + "px";
#endif

        if (_imagePosition === CPImageBelow)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.left = FLOOR(centerX - imageWidth / 2.0) + "px";
            _DOMImageElement.style.top = FLOOR(size.height - imageHeight) + "px";
#endif

            titleRect.origin.y = (size.height - imageHeight - titleHeight) / 2.0;
        }
        else if (_imagePosition === CPImageAbove)
        {
#if PLATFORM(DOM)
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, FLOOR(centerX - imageWidth / 2.0), 0);
#endif

            titleRect.origin.y = imageHeight + (size.height - imageHeight - titleHeight) / 2.0;
        }
        else if (_imagePosition === CPImageLeft)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            _DOMImageElement.style.left = "0px";
#endif

            titleRect.origin.x += imageWidth;
            titleRect.size.width -= imageWidth;
        }
        else if (_imagePosition === CPImageRight)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            _DOMImageElement.style.left = FLOOR(size.width - imageWidth) + "px";
#endif

            titleRect.size.width -= imageWidth;
        }
        else if(_imagePosition === CPImageOnly)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            _DOMImageElement.style.left = FLOOR(centerX - imageWidth / 2.0) + "px";
#endif
        }
    }

#if PLATFORM(DOM)
    if (_DOMTextElement)
    {
        _DOMTextElement.style.top = FLOOR(_CGRectGetMinY(titleRect)) + "px";
        _DOMTextElement.style.left = FLOOR(_CGRectGetMinX(titleRect)) + "px";
        _DOMTextElement.style.width = FLOOR(_CGRectGetWidth(titleRect)) + "px";
        _DOMTextElement.style.height = FLOOR(_CGRectGetHeight(titleRect)) + "px";
    }
#endif
}

- (void)sizeToFit
{
    var size = CGSizeMakeZero();
    
    if (_imagePosition != CPNoImage && _image)
    {
        var imageSize = [_image size];
        
        size.width += imageSize.width;
        size.height += imageSize.height;
    }
    
    if (_imagePosition != CPImageOnly && [_text length] > 0)
    {
        if (!_textSize)
            _textSize = [_text sizeWithFont:_font];
            
        if (_imagePosition == CPImageLeft || _imagePosition == CPImageRight)
        {
            size.width += _textSize.width;
            size.height = MAX(size.height, _textSize.height);
        }
        else if (_imagePosition == CPImageAbove || _imagePosition == CPImageBelow)
        {
            size.width = MAX(size.width, _textSize.width);
            size.height += _textSize.height;
        }
        else // if (_imagePosition == CPImageOverlaps)
        {
            size.width = MAX(size.width, _textSize.width);
            size.height = MAX(size.height, _textSize.height);
        }
    }
    
    [self setFrameSize:size];
}

@end
