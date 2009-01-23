/*
 * _CPImageAndTitleView.j
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

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

/* @ignore */
@implementation _CPImageAndTitleView : CPView
{
    CPTextAlignment     _alignment;
    CPColor             _textColor;
    CPFont              _font;
    
    CPCellImagePosition _imagePosition;
    CPImageScaling      _imageScaling;
    
    CPImage             _image;
    CPString            _title;
    
    CGRect              _titleSize;

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
        
        _titleSize = NULL;
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
    
#if PLATFORM(DOM)
    [self createOrDestroyDOMTextElement];
#endif

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
    
    _titleSize = NULL;
    
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
    
    var oldSize = [_image size],
        newSize = [anImage size];

    _image = anImage;

    if (anImage)
    {
#if PLATFORM(DOM)
        if (!_DOMImageElement)
        {
            _DOMImageElement = document.createElement("img");

            _DOMImageElement.style.top = "0px";
            _DOMImageElement.style.left = "0px";
            _DOMImageElement.style.position = "absolute";
            _DOMImageElement.style.zIndex = 100;

            _DOMElement.appendChild(_DOMImageElement);
        }
        
        _DOMImageElement.src = [_image filename];
#endif

        if (oldSize && CGSizeEqualToSize(newSize, oldSize))
            return;

#if PLATFORM(DOM)        
        _DOMImageElement.width = newSize.width;
        _DOMImageElement.height = newSize.height;
        _DOMImageElement.style.width = newSize.width + "px";
        _DOMImageElement.style.height = newSize.height + "px";
#endif
    }
    else
    {
#if PLATFORM(DOM)
        _DOMElement.removeChild(_DOMImageElement);
        
        _DOMImageElement = NULL;
#endif
    }
    
    [self setNeedsDisplay:YES];
}

- (CPImage)image
{
    return _image;
}

#if PLATFORM(DOM)
- (void)createOrDestroyDOMTextElement
{
    var needsDOMTextElement = _imagePosition !== CPImageOnly && ([_title length] > 0);
    
    if (needsDOMTextElement === !!_DOMTextElement)
        return;
    
    if (_DOMTextElement)
    {
        _DOMElement.removeChild(_DOMTextElement);
        _DOMTextElement = NULL;
    }
    
    else
    {
        _DOMTextElement = document.createElement("div");
        _DOMTextElement.style.background = "red";
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        _DOMTextElement.style.zIndex = 100;
        _DOMTextElement.style.overflow = "hidden";

        _DOMElement.appendChild(_DOMTextElement);
    }
}
#endif

- (void)setTitle:(CPString)aTitle
{
    if (_title === aTitle)
        return;
    
    _title = aTitle;
    
#if PLATFORM(DOM)
        [self createOrDestroyDOMTextElement];
#endif
    
#if PLATFORM(DOM)
    if (_DOMTextElement)
    {
        if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
            _DOMTextElement.innerText = _title;
    
        else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
            _DOMTextElement.textContent = _title;  
    }
#endif

    _titleSize = NULL;
    
    [self setNeedsDisplay:YES];
}

- (CPString)title
{
    return _title;
}

- (void)drawRect:(CGRect)aRect
{
    if (!_titleSize && _DOMTextElement)
        _titleSize = [_title sizeWithFont:_font];
        
    var size = [self bounds].size,
        centerX = size.width / 2.0,
        centerY = size.height / 2.0,
        titleHeight = _DOMTextElement ? _titleSize.height : 0.0,
        titleRect = CGRectMake(0.0, centerY - titleHeight / 2.0, size.width, titleHeight);

    if (_imagePosition != CPNoImage && _image)
    {
        var imageSize = [_image size], 
            imageWidth = imageSize.width,
            imageHeight = imageSize.height;
        
        if (_imageScaling == CPScaleToFit)
        {
            imageWidth = size.width;
            imageHeight = size.height;
        }
        else if (_imageScaling == CPScaleProportionally)
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

        if (_imagePosition == CPImageBelow)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.left = FLOOR(centerX - imageWidth / 2.0) + "px";
            _DOMImageElement.style.top = FLOOR(size.height - imageHeight) + "px";
#endif

            titleRect.origin.y = (size.height - imageHeight - titleHeight) / 2.0;
        }
        else if (_imagePosition == CPImageAbove)
        {
#if PLATFORM(DOM)
            CPDOMDisplayServerSetStyleLeftTop(_DOMImageElement, NULL, FLOOR(centerX - imageWidth / 2.0), 0);
#endif

            titleRect.origin.y = imageHeight + (size.height - imageHeight - titleHeight) / 2.0;
        }
        else if (_imagePosition == CPImageLeft)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            _DOMImageElement.style.left = "0px";
#endif

            titleRect.origin.x += imageWidth;
            titleRect.size.width -= imageWidth;
        }
        else if (_imagePosition == CPImageRight)
        {
#if PLATFORM(DOM)
            _DOMImageElement.style.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            _DOMImageElement.style.left = FLOOR(size.width - imageWidth) + "px";
#endif

            titleRect.size.width -= imageWidth;
        }
        else if(_imagePosition == CPImageOnly)
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
        _DOMTextElement.style.top = FLOOR(CGRectGetMinY(titleRect)) + "px";
        _DOMTextElement.style.left = FLOOR(CGRectGetMinX(titleRect)) + "px";
        _DOMTextElement.style.width = FLOOR(CGRectGetWidth(titleRect)) + "px";
        _DOMTextElement.style.height = FLOOR(CGRectGetHeight(titleRect)) + "px";
    }
#endif
}

- (void)sizeToFit
{
    if (!_titleSize && _DOMTextElement)
        _titleSize = [_title sizeWithFont:_font];
    
    var size = CGSizeMakeZero();
    
    if (_imagePosition != CPNoImage && _image)
    {
        var imageSize = [_image size];
        
        size.width += imageSize.width;
        size.height += imageSize.height;
    }
    
    if (_imagePosition != CPImageOnly && [_title length])
    {
        if (_imagePosition == CPImageLeft || _imagePosition == CPImageRight)
        {
            size.width += _titleSize.width;
            size.height = MAX(size.height, _titleSize.height);
        }
        else if (_imagePosition == CPImageAbove || _imagePosition == CPImageBelow)
        {
            size.width = MAX(size.width, _titleSize.width);
            size.height += _titleSize.height;
        }
        else // if (_imagePosition == CPImageOverlaps)
        {
            size.width = MAX(size.width, _titleSize.width);
            size.height = MAX(size.height, _titleSize.height);
        }
    }
    
    [self setFrameSize:size];
}

@end
