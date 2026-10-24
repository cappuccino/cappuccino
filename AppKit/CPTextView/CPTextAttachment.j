/*
 *  CPTextAttachment.j
 *  AppKit
 *
 *  Created by David Richardson on 25/10/2026.
 *  Copyright David Richardson 2026.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPData.j>
@import <Foundation/CPNotificationCenter.j>

@import "CPImage.j"
@import "CPImageView.j"

/*
    Posted when an attachment's displayed size changes, for example when its image has loaded.
    A text view that contains the attachment lays its text out again.
*/
_CPTextAttachmentDidChangeSizeNotification = @"_CPTextAttachmentDidChangeSizeNotification";

/*!
    @ingroup appkit
    @class CPTextAttachment

    A CPTextAttachment holds an image in rich text, as NSTextAttachment does in Cocoa. The text
    holds the attachment as one attachment character (CPAttachmentCharacter), whose
    CPAttachmentAttributeName attribute is the attachment. The attachment is edited, copied and
    undone as that one character.

    The attachment keeps the image's data and type, and shows the image in a view. As in TextKit
    2, an attachment is drawn by a view, not by a cell. The text system lays the view out as the
    character, at the view's size, with its bottom on the baseline. That size is the attachment's
    bounds, or the image's natural size, scaled down to fit the width of the text, as in TextEdit.
*/
@implementation CPTextAttachment : CPObject
{
    CPData          _contents;
    CPString        _fileType;
    CPImage         _image;
    CGRect          _bounds;

    CPImageView     _imageView;
    float           _maximumWidth;
}

/*!
    Initialises an attachment with image data.
    @param contentData the image's data
    @param aType the image's type, as a MIME type such as \c @"image/png", or a uniform type
    identifier such as \c @"public.png"
*/
- (id)initWithData:(CPData)contentData ofType:(CPString)aType
{
    if (self = [super init])
    {
        _contents = contentData;
        _fileType = aType;
        _bounds = CGRectMakeZero();
        _maximumWidth = 0.0;
    }

    return self;
}

- (id)init
{
    return [self initWithData:nil ofType:nil];
}

/* @ignore
    Returns an attachment made from a data URL, such as the browser's FileReader produces.
*/
+ (CPTextAttachment)_attachmentWithDataURL:(CPString)aDataURL
{
    var match = /^data:([^;,]+)(;base64)?,(.*)$/.exec(aDataURL || "");

    if (!match)
        return nil;

    var data = match[2] ? [CPData dataWithBase64:match[3]] : [CPData dataWithRawString:decodeURIComponent(match[3])];

    return [[self alloc] initWithData:data ofType:match[1]];
}

/*!
    Returns the image's data.
*/
- (CPData)contents
{
    return _contents;
}

/*!
    Sets the image's data. The image is made again from the data.
*/
- (void)setContents:(CPData)contentData
{
    _contents = contentData;
    [self _setImage:nil];
}

/*!
    Returns the image's type.
*/
- (CPString)fileType
{
    return _fileType;
}

/*!
    Sets the image's type.
*/
- (void)setFileType:(CPString)aType
{
    _fileType = aType;
}

/*!
    Returns the image. It is made from the attachment's data the first time it is needed.
*/
- (CPImage)image
{
    if (!_image && _contents)
        [self _setImage:[[CPImage alloc] initWithContentsOfFile:[self _dataURL]]];

    return _image;
}

/*!
    Sets the image. An image set this way has no data of its own unless it was made from a data
    URL, so an attachment that must be archived or copied should be made with
    -initWithData:ofType:.
*/
- (void)setImage:(CPImage)anImage
{
    [self _setImage:anImage];
}

/*!
    Returns the attachment's bounds in the text. With a zero size, the attachment takes the
    image's natural size.
*/
- (CGRect)bounds
{
    return CGRectMakeCopy(_bounds);
}

/*!
    Sets the attachment's bounds in the text.
*/
- (void)setBounds:(CGRect)aRect
{
    _bounds = CGRectMakeCopy(aRect);
    [self _updateViewSize];
}

// MARK: Display

/* @ignore
    Returns the view that shows the attachment in the text. The text system lays it out as the
    attachment character.
*/
- (CPView)_attachmentView
{
    if (!_imageView)
    {
        _imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        [_imageView setImageScaling:CPImageScaleAxesIndependently];
        [_imageView setImage:[self image]];
        [self _updateViewSize];
    }

    return _imageView;
}

/* @ignore
    Sets the widest the attachment may be shown, which is the width of the text. Returns YES if
    the displayed size changes.
*/
- (BOOL)_setMaximumWidth:(float)aWidth
{
    if (_maximumWidth === aWidth)
        return NO;

    _maximumWidth = aWidth;

    return [self _updateViewSize];
}

/* @ignore
    Returns the size at which the attachment is shown: its bounds, or the image's natural size,
    scaled down in proportion to fit the maximum width. The size is zero until the image has
    loaded.
*/
- (CGSize)_displaySize
{
    var size = CGSizeMakeCopy(_bounds.size);

    if (!size.width || !size.height)
    {
        var image = [self image];

        if (!image || [image loadStatus] !== CPImageLoadStatusCompleted)
            return CGSizeMakeZero();

        size = CGSizeMakeCopy([image size]);
    }

    if (_maximumWidth > 0.0 && size.width > _maximumWidth)
    {
        size.height = ROUND(size.height * _maximumWidth / size.width);
        size.width = _maximumWidth;
    }

    return size;
}

/* @ignore
    Gives the view the displayed size. Returns YES if the size changes.
*/
- (BOOL)_updateViewSize
{
    if (!_imageView)
        return NO;

    var size = [self _displaySize];

    if (CGSizeEqualToSize(size, [_imageView frameSize]))
        return NO;

    [_imageView setFrameSize:size];

    return YES;
}

/* @ignore
    Sets the image, and waits for it to load when it has not yet loaded.
*/
- (void)_setImage:(CPImage)anImage
{
    if (_image)
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPImageDidLoadNotification object:_image];

    _image = anImage;

    if (_image && [_image loadStatus] !== CPImageLoadStatusCompleted)
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_imageDidLoad:) name:CPImageDidLoadNotification object:_image];
        [_image load];
    }

    if (_imageView)
    {
        [_imageView setImage:_image];

        if ([self _updateViewSize])
            [[CPNotificationCenter defaultCenter] postNotificationName:_CPTextAttachmentDidChangeSizeNotification object:self];
    }
}

/* @ignore
    The image's natural size is known once it has loaded, so the view takes its size, and the
    text that contains the attachment is laid out again.
*/
- (void)_imageDidLoad:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPImageDidLoadNotification object:_image];

    if (_imageView)
        [_imageView setImage:_image];

    if ([self _updateViewSize])
        [[CPNotificationCenter defaultCenter] postNotificationName:_CPTextAttachmentDidChangeSizeNotification object:self];
}

/* @ignore
    Returns the attachment's data as a data URL, which the browser loads as an image.
*/
- (CPString)_dataURL
{
    return "data:" + [self _MIMEType] + ";base64," + [_contents base64];
}

/* @ignore
    Returns the image's MIME type. A uniform type identifier is mapped to its MIME type.
*/
- (CPString)_MIMEType
{
    var type = _fileType || @"image/png";

    if (type.indexOf("/") !== -1)
        return type;

    switch (type)
    {
        case @"public.jpeg":
            return @"image/jpeg";

        case @"com.compuserve.gif":
            return @"image/gif";

        case @"public.svg-image":
            return @"image/svg+xml";

        case @"org.webmproject.webp":
            return @"image/webp";

        default:
            return @"image/png";
    }
}

@end

var CPTextAttachmentContentsKey = @"CPTextAttachmentContents",
    CPTextAttachmentFileTypeKey = @"CPTextAttachmentFileType",
    CPTextAttachmentBoundsKey   = @"CPTextAttachmentBounds";

@implementation CPTextAttachment (CPCoding)

/*!
    Decodes the attachment. The image is made again from the archived data.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    var contentsString = [aCoder decodeObjectForKey:CPTextAttachmentContentsKey];

    self = [self initWithData:contentsString ? [CPData dataWithBase64:contentsString] : nil
                       ofType:[aCoder decodeObjectForKey:CPTextAttachmentFileTypeKey]];

    if (self && [aCoder containsValueForKey:CPTextAttachmentBoundsKey])
        _bounds = [aCoder decodeRectForKey:CPTextAttachmentBoundsKey];

    return self;
}

/*!
    Encodes the attachment's data, type and bounds. The view is not encoded.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    if (_contents)
        [aCoder encodeObject:[_contents base64] forKey:CPTextAttachmentContentsKey];

    if (_fileType)
        [aCoder encodeObject:_fileType forKey:CPTextAttachmentFileTypeKey];

    if (!CGRectIsEmpty(_bounds))
        [aCoder encodeRect:_bounds forKey:CPTextAttachmentBoundsKey];
}

@end
