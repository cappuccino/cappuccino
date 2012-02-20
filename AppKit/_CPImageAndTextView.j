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
@import "CPView.j"
@import "CPControl.j"

#include "CoreGraphics/CGGeometry.h"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

var _CPimageAndTextViewFrameSizeChangedFlag         = 1 << 0,
    _CPImageAndTextViewImageChangedFlag             = 1 << 1,
    _CPImageAndTextViewTextChangedFlag              = 1 << 2,
    _CPImageAndTextViewAlignmentChangedFlag         = 1 << 3,
    _CPImageAndTextViewVerticalAlignmentChangedFlag = 1 << 4,
    _CPImageAndTextViewLineBreakModeChangedFlag     = 1 << 5,
    _CPImageAndTextViewTextColorChangedFlag         = 1 << 6,
    _CPImageAndTextViewFontChangedFlag              = 1 << 7,
    _CPImageAndTextViewTextShadowColorChangedFlag   = 1 << 8,
    _CPImageAndTextViewImagePositionChangedFlag     = 1 << 9,
    _CPImageAndTextViewImageScalingChangedFlag      = 1 << 10;

/* @ignore */
@implementation _CPImageAndTextView : CPView
{
    CPTextAlignment         _alignment;
    CPVerticalTextAlignment _verticalAlignment;

    CPLineBreakMode         _lineBreakMode;
    CPColor                 _textColor;
    CPFont                  _font;

    CPColor                 _textShadowColor;
    CGSize                  _textShadowOffset;

    CPCellImagePosition     _imagePosition;
    CPImageScaling          _imageScaling;
    float                   _imageOffset;
    BOOL                    _shouldDimImage;

    CPImage                 _image;
    CPString                _text;

    CGRect                  _textSize;

    unsigned                _flags;

#if PLATFORM(DOM)
    DOMElement              _DOMImageElement;
    DOMELement              _DOMTextElement;
    DOMElement              _DOMTextShadowElement;
#endif
}

- (id)initWithFrame:(CGRect)aFrame control:(CPControl)aControl
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _textShadowOffset = _CGSizeMakeZero();
        [self setVerticalAlignment:CPTopVerticalTextAlignment];

        if (aControl)
        {
            [self setLineBreakMode:[aControl lineBreakMode]];
            [self setTextColor:[aControl textColor]];
            [self setAlignment:[aControl alignment]];
            [self setVerticalAlignment:[aControl verticalAlignment]];
            [self setFont:[aControl font]];
            [self setImagePosition:[aControl imagePosition]];
            [self setImageScaling:[aControl imageScaling]];
            [self setImageOffset:[aControl imageOffset]];
        }
        else
        {
            [self setLineBreakMode:CPLineBreakByClipping];
            //[self setTextColor:[aControl textColor]];
            [self setAlignment:CPCenterTextAlignment];
            [self setFont:[CPFont systemFontOfSize:12.0]];
            [self setImagePosition:CPNoImage];
            [self setImageScaling:CPScaleNone];
        }

        _textSize = NULL;
    }

    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame control:nil];
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

- (void)setVerticalAlignment:(CPVerticalTextAlignment)anAlignment
{
    if (_verticalAlignment === anAlignment)
        return;

    _verticalAlignment = anAlignment;
    _flags |= _CPImageAndTextViewVerticalAlignmentChangedFlag;

    [self setNeedsLayout];
}

- (unsigned)verticalAlignment
{
    return _verticalAlignment;
}

- (void)setLineBreakMode:(CPLineBreakMode)aLineBreakMode
{
    if (_lineBreakMode === aLineBreakMode)
        return;

    _lineBreakMode = aLineBreakMode;
    _flags |= _CPImageAndTextViewLineBreakModeChangedFlag;

    [self setNeedsLayout];
}

- (CPLineBreakMode)lineBreakMode
{
    return _lineBreakMode;
}

- (void)setImagePosition:(CPCellImagePosition)anImagePosition
{
    if (_imagePosition == anImagePosition)
        return;

    // If the position was CPNoImage, there is an image now,
    // so mark the flags accordingly so that the image will load.
    if (_imagePosition == CPNoImage)
        _flags |= _CPImageAndTextViewImageChangedFlag;

    _imagePosition = anImagePosition;
    _flags |= _CPImageAndTextViewImagePositionChangedFlag;

    [self setNeedsLayout];
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
    _flags |= _CPImageAndTextViewImageScalingChangedFlag;

    [self setNeedsLayout];
}

- (void)imageScaling
{
    return _imageScaling;
}

- (void)setDimsImage:(BOOL)shouldDimImage
{
    shouldDimImage = !!shouldDimImage;

    if (_shouldDimImage !== shouldDimImage)
    {
        _shouldDimImage = shouldDimImage;
        [self setNeedsLayout];
    }
}

- (void)setTextColor:(CPColor)aTextColor
{
    if (_textColor === aTextColor)
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
    _flags |= _CPImageAndTextViewFontChangedFlag;
    _textSize = NULL;

    [self setNeedsLayout];
}

- (CPFont)font
{
    return _font;
}

- (void)setTextShadowColor:(CPColor)aColor
{
    if (_textShadowColor === aColor)
        return;

    _textShadowColor = aColor;
    _flags |= _CPImageAndTextViewTextShadowColorChangedFlag;

    [self setNeedsLayout];
}

- (CPColor)textShadowColor
{
    return _textShadowColor;
}

- (void)setTextShadowOffset:(CGSize)anOffset
{
    if (_CGSizeEqualToSize(_textShadowOffset, anOffset))
        return;

    _textShadowOffset = _CGSizeMakeCopy(anOffset);

    [self setNeedsLayout];
}

- (CGSize)textShadowOffset
{
    return _textShadowOffset;
}

- (void)setImage:(CPImage)anImage
{
    if (_image == anImage)
        return;

    if ([_image delegate] === self)
        [_image setDelegate:nil];

    _image = anImage;
    _flags |= _CPImageAndTextViewImageChangedFlag;

    if ([_image loadStatus] !== CPImageLoadStatusCompleted)
        [_image setDelegate:self];

    [self setNeedsLayout];
}

- (void)setImageOffset:(float)theImageOffset
{
    if (_imageOffset === theImageOffset)
        return;

    _imageOffset = theImageOffset;
    [self setNeedsLayout];
}

- (float)imageOffset
{
    return _imageOffset;
}

- (void)imageDidLoad:(id)anImage
{
    if (anImage === _image)
    {
        _flags |= _CPImageAndTextViewImageChangedFlag;
        [self setNeedsLayout];
    }
}

- (CPImage)image
{
    return _image;
}

- (void)setText:(CPString)text
{
    if (_text === text)
        return;

    _text = text;
    _flags |= _CPImageAndTextViewTextChangedFlag;

    _textSize = NULL;

    [self setNeedsLayout];
}

- (CPString)text
{
    return _text;
}

- (void)layoutSubviews
{
#if PLATFORM(DOM)
    var needsDOMTextElement = _imagePosition !== CPImageOnly && ([_text length] > 0),
        hasDOMTextElement = !!_DOMTextElement;

    // Create or destroy the DOM Text Element as necessary
    if (needsDOMTextElement !== hasDOMTextElement)
    {
        if (hasDOMTextElement)
        {
            _DOMElement.removeChild(_DOMTextElement);

            _DOMTextElement = NULL;

            hasDOMTextElement = NO;
        }

        else
        {
            _DOMTextElement = document.createElement("div");

            var textStyle = _DOMTextElement.style;

            textStyle.position = "absolute";
            textStyle.whiteSpace = "pre";

            textStyle.zIndex = 200;
            textStyle.overflow = "hidden";

            _DOMElement.appendChild(_DOMTextElement);

            hasDOMTextElement = YES;

            // We have to set all these values now.
            _flags |= _CPImageAndTextViewTextChangedFlag | _CPImageAndTextViewFontChangedFlag | _CPImageAndTextViewLineBreakModeChangedFlag;
        }
    }

    var textStyle = hasDOMTextElement ? _DOMTextElement.style : nil;

    // Create or destroy the DOM Text Shadow element as necessary.
    var needsDOMTextShadowElement = hasDOMTextElement && !!_textShadowColor,
        hasDOMTextShadowElement = !!_DOMTextShadowElement;

    if (needsDOMTextShadowElement !== hasDOMTextShadowElement)
    {
        if (hasDOMTextShadowElement)
        {
            _DOMElement.removeChild(_DOMTextShadowElement);

            _DOMTextShadowElement = NULL;

            hasDOMTextShadowElement = NO;
        }
        else
        {
            _DOMTextShadowElement = document.createElement("div");

            var shadowStyle = _DOMTextShadowElement.style;

            shadowStyle.font = [_font ? _font : [CPFont systemFontOfSize:12.0] cssString];
            shadowStyle.position = "absolute";
            shadowStyle.whiteSpace = textStyle.whiteSpace;
            shadowStyle.wordWrap = textStyle.wordWrap;
            shadowStyle.color = [_textShadowColor cssString];

            shadowStyle.zIndex = 150;
            shadowStyle.textOverflow = textStyle.textOverflow;

            if (document.attachEvent)
            {
                shadowStyle.overflow = textStyle.overflow;
            }
            else
            {
                shadowStyle.overflowX = textStyle.overflowX;
                shadowStyle.overflowY = textStyle.overflowY;
            }

            _DOMElement.appendChild(_DOMTextShadowElement);

            hasDOMTextShadowElement = YES;

            _flags |= _CPImageAndTextViewTextChangedFlag; //sigh...
        }
    }

    var shadowStyle = hasDOMTextShadowElement ? _DOMTextShadowElement.style : nil;

    if (hasDOMTextElement)
    {
        // Update the text contents if necessary.
        if (_flags & _CPImageAndTextViewTextChangedFlag)
            if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
            {
                _DOMTextElement.innerText = _text;

                if (_DOMTextShadowElement)
                    _DOMTextShadowElement.innerText = _text;
            }
            else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
            {
                _DOMTextElement.textContent = _text;

                if (_DOMTextShadowElement)
                    _DOMTextShadowElement.textContent = _text;
            }

        if (_flags & _CPImageAndTextViewFontChangedFlag)
        {
            var fontStyle = [_font ? _font : [CPFont systemFontOfSize:12.0] cssString];
            textStyle.font = fontStyle;

            if (shadowStyle)
                shadowStyle.font = fontStyle;
        }

        // Update the line break mode if necessary.
        if (_flags & _CPImageAndTextViewLineBreakModeChangedFlag)
        {
            switch (_lineBreakMode)
            {
                case CPLineBreakByClipping:         textStyle.overflow = "hidden";
                                                    textStyle.textOverflow = "clip";
                                                    textStyle.whiteSpace = "pre";
                                                    textStyle.wordWrap = "normal";

                                                    break;

                case CPLineBreakByTruncatingHead:
                case CPLineBreakByTruncatingMiddle: // Don't have support for these (yet?), so just degrade to truncating tail.

                case CPLineBreakByTruncatingTail:   textStyle.textOverflow = "ellipsis";
                                                    textStyle.whiteSpace = "nowrap";
                                                    textStyle.overflow = "hidden";
                                                    textStyle.wordWrap = "normal";

                                                    break;

                case CPLineBreakByCharWrapping:
                case CPLineBreakByWordWrapping:     textStyle.wordWrap = "break-word";
                                                    try {
                                                        textStyle.whiteSpace = "pre";
                                                        textStyle.whiteSpace = "-o-pre-wrap";
                                                        textStyle.whiteSpace = "-pre-wrap";
                                                        textStyle.whiteSpace = "-moz-pre-wrap";
                                                        textStyle.whiteSpace = "pre-wrap";
                                                    }
                                                    catch (e) {
                                                        //internet explorer doesn't like these properties
                                                        textStyle.whiteSpace = "pre";
                                                    }

                                                    textStyle.overflow = "hidden";
                                                    textStyle.textOverflow = "clip";

                                                    break;
            }

            if (shadowStyle)
            {
                if (document.attachEvent)
                {
                    shadowStyle.overflow = textStyle.overflow;
                }
                else
                {
                    shadowStyle.overflowX = textStyle.overflowX;
                    shadowStyle.overflowY = textStyle.overflowY;
                }

                shadowStyle.wordWrap = textStyle.wordWrap;
                shadowStyle.whiteSpace = textStyle.whiteSpace;
                shadowStyle.textOverflow = textStyle.textOverflow;
            }
        }
    }

    var needsDOMImageElement = _image !== nil && _imagePosition !== CPNoImage,
        hasDOMImageElement = !!_DOMImageElement;

    // Create or destroy DOM Image element
    if (needsDOMImageElement !== hasDOMImageElement)
    {
        if (hasDOMImageElement)
        {
            _DOMElement.removeChild(_DOMImageElement);

            _DOMImageElement = NULL;

            hasDOMImageElement = NO;
        }

        else
        {
            _DOMImageElement = document.createElement("img");

            if ([CPPlatform supportsDragAndDrop])
            {
                _DOMImageElement.setAttribute("draggable", "true");
                _DOMImageElement.style["-khtml-user-drag"] = "element";
            }

            var imageStyle = _DOMImageElement.style;

            imageStyle.top = "0px";
            imageStyle.left = "0px";
            imageStyle.position = "absolute";
            imageStyle.zIndex = 100;

            _DOMElement.appendChild(_DOMImageElement);

            hasDOMImageElement = YES;
        }
    }

    var size = [self bounds].size,
        textRect = _CGRectMake(0.0, 0.0, size.width, size.height);

    if (hasDOMImageElement)
    {
        if (!imageStyle)
            var imageStyle = _DOMImageElement.style;

        if (_flags & _CPImageAndTextViewImageChangedFlag)
            _DOMImageElement.src = [_image filename];

        var centerX = size.width / 2.0,
            centerY = size.height / 2.0,
            imageSize = [_image size],
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

        if (CPFeatureIsCompatible(CPOpacityRequiresFilterFeature))
            imageStyle.filter = @"alpha(opacity=" + _shouldDimImage ? 35 : 100 + ")";
        else
            imageStyle.opacity = _shouldDimImage ? 0.35 : 1.0;

        _DOMImageElement.width = imageWidth;
        _DOMImageElement.height = imageHeight;
        imageStyle.width = MAX(imageWidth, 0) + "px";
        imageStyle.height = MAX(imageHeight, 0) + "px";

        if (_imagePosition === CPImageBelow)
        {
            imageStyle.left = FLOOR(centerX - imageWidth / 2.0) + "px";
            imageStyle.top = FLOOR(size.height - imageHeight) + "px";

            textRect.size.height = size.height - imageHeight - _imageOffset;
        }
        else if (_imagePosition === CPImageAbove)
        {
            imageStyle.left = FLOOR(centerX - imageWidth / 2.0) + "px";
            imageStyle.top = 0 + "px";

            textRect.origin.y += imageHeight + _imageOffset;
            textRect.size.height = size.height - imageHeight - _imageOffset;
        }
        else if (_imagePosition === CPImageLeft)
        {
            imageStyle.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            imageStyle.left = "0px";

            textRect.origin.x = imageWidth + _imageOffset;
            textRect.size.width -= imageWidth + _imageOffset;
        }
        else if (_imagePosition === CPImageRight)
        {
            imageStyle.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            imageStyle.left = FLOOR(size.width - imageWidth) + "px";

            textRect.size.width -= imageWidth + _imageOffset;
        }
        else if (_imagePosition === CPImageOnly || _imagePosition == CPImageOverlaps)
        {
            imageStyle.top = FLOOR(centerY - imageHeight / 2.0) + "px";
            imageStyle.left = FLOOR(centerX - imageWidth / 2.0) + "px";
        }
    }

    if (hasDOMTextElement)
    {
        var textRectX = _CGRectGetMinX(textRect),
            textRectY = _CGRectGetMinY(textRect),
            textRectWidth = _CGRectGetWidth(textRect),
            textRectHeight = _CGRectGetHeight(textRect);

        if (_verticalAlignment !== CPTopVerticalTextAlignment)
        {
            if (!_textSize)
            {
                if (_lineBreakMode === CPLineBreakByCharWrapping ||
                    _lineBreakMode === CPLineBreakByWordWrapping)
                    _textSize = [_text sizeWithFont:_font inWidth:textRectWidth];
                else
                    _textSize = [_text sizeWithFont:_font];
            }

            if (_verticalAlignment === CPCenterVerticalTextAlignment)
            {
                textRectY = textRectY + (textRectHeight - _textSize.height) / 2.0;
                textRectHeight = _textSize.height;
            }

            else //if (_verticalAlignment === CPBottomVerticalTextAlignment)
            {
                textRectY = textRectY + textRectHeight - _textSize.height;
                textRectHeight = _textSize.height;
            }
        }

        textStyle.top = ROUND(textRectY) + "px";
        textStyle.left = ROUND(textRectX) + "px";
        textStyle.width = MAX(ROUND(textRectWidth), 0) + "px";
        textStyle.height = MAX(ROUND(textRectHeight), 0) + "px";

        if (shadowStyle)
        {
            if (_flags & _CPImageAndTextViewTextShadowColorChangedFlag)
                shadowStyle.color = [_textShadowColor cssString];

            shadowStyle.top = ROUND(textRectY + _textShadowOffset.height) + "px";
            shadowStyle.left = ROUND(textRectX + _textShadowOffset.width) + "px";
            shadowStyle.width = MAX(ROUND(textRectWidth), 0) + "px";
            shadowStyle.height = MAX(ROUND(textRectHeight), 0) + "px";
        }
    }
#endif

    _flags = 0;
}

- (void)sizeToFit
{
    var size = CGSizeMakeZero();

    if ((_imagePosition !== CPNoImage) && _image)
    {
        var imageSize = [_image size];

        size.width += imageSize.width;
        size.height += imageSize.height;
    }

    if ((_imagePosition !== CPImageOnly) && [_text length] > 0)
    {
        if (!_textSize)
            _textSize = [_text sizeWithFont:_font ? _font : [CPFont systemFontOfSize:12.0]];

        if (_imagePosition === CPImageLeft || _imagePosition === CPImageRight)
        {
            size.width += _textSize.width + _imageOffset;
            size.height = MAX(size.height, _textSize.height);
        }
        else if (_imagePosition === CPImageAbove || _imagePosition === CPImageBelow)
        {
            size.width = MAX(size.width, _textSize.width);
            size.height += _textSize.height + _imageOffset;
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
