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

import <Foundation/CPString.j>

import "CPColor.j"
import "CPFont.j"
import "CPImage.j"
import "CPTextField.j"
import "CPView.j"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"


@implementation _CPImageAndTitleView : CPView
{
    CPTextAlignment     _alignment;
    CPColor             _textColor;
    CPFont              _font;
    
    CPCellImagePosition _imagePosition;
    CPImageScaling      _imageScalng;
    
    CPImage             _image;
    CPString            _title;
    
    CGRect              _titleSize;

#if PLATFORM(DOM)
    DOMElement          _DOMImageElement;
#endif
    CPTextField         _titleField;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _alignment = CPCenterTextAlignment;
        _textColor = nil;
        _font = [CPFont systemFontOfSize:12.0];
        
        _imagePosition = CPNoImage;
        _imageScaling = CPScaleNone;
        
        _titleSize = CGSizeMakeZero();
    }
    
    return self;
}

- (void)setAlignment:(CPTextAlignment)anAlignment
{
    _alignment = anAlignment;
    
    [_titleField setAlignment:anAlignment];
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
    
    if (_imagePosition == CPImageOnly)
        [_titleField setHidden:YES];
    else
        [_titleField setHidden:NO];

    [self tile];
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

    [self tile];
}

- (void)imageScaling
{
    return _imageScaling;
}

- (void)setTextAlignment:(CPTextAlignment)aTextAlignment
{
    if (_alignment == aTextAlignment)
        return;
    
    _alignment = aTextAlignment;
    [_titleField setTextAlignment:aTextAlignment];
}

- (CPTextAlignment)textAlignment
{
    return _alignment;
}

- (void)setTextColor:(CPColor)aTextColor
{
    if (_textColor == aTextColor)
        return;
    
    _textColor = aTextColor;
    [_titleField setTextColor:aTextColor];
}

- (CPColor)textColor
{
    return _textColor;
}

- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
    
    _font = aFont;
    [_titleField setFont:aFont];
    
    [self updateTitleSize];
    
    [self tile];
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
    
    [self tile];
}

- (CPImage)image
{
    return _image;
}

- (void)setTitle:(CPString)aTitle
{
    if (_title == aTitle)
        return;
    
    _title = aTitle;
    
    if ([_title length])
    {
        if (!_titleField)
        {
            _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            
            [_titleField setEditable:NO];
            
            [_titleField setFont:_font];
            [_titleField setAlignment:_alignment];
            [_titleField setTextColor:_textColor];
            [_titleField setHidden:_imagePosition == CPImageOnly];
            
            [self addSubview:_titleField];
        }
        
        [_titleField setStringValue:_title];
        
        [self updateTitleSize];
    }
    else
    {
        [_titleField removeFromSuperview];
        
        _titleField = nil;
    }
    
    [self tile];
}

- (CPString)title
{
    return _title;
}

- (void)updateTitleSize
{
    if (!_titleField)
        return;
    
    var size = _titleSize;
    
    [_titleField sizeToFit];
    
    _titleSize = CGSizeMakeCopy([_titleField frame].size);
    
    [_titleField setFrameSize:size];
}

- (void)tile
{
    var size = [self bounds].size,
        centerX = size.width / 2.0,
        centerY = size.height / 2.0,
        titleHeight = _titleField ? _titleSize.height : 0.0,
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

    [_titleField setFrame:titleRect];
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

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self tile];
}

@end
