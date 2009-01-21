/*
 * CPImage.j
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
 
@import <Foundation/CPBundle.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>
@import <Foundation/CPString.j>

@import "CPGeometry.j"

CPImageLoadStatusInitialized    = 0;
CPImageLoadStatusLoading        = 1;
CPImageLoadStatusCompleted      = 2;
CPImageLoadStatusCancelled      = 3;
CPImageLoadStatusInvalidData    = 4;
CPImageLoadStatusUnexpectedEOF  = 5;
CPImageLoadStatusReadError      = 6;

CPImageDidLoadNotification      = @"CPImageDidLoadNotification";

function CPImageInBundle(aFilename, aSize, aBundle)
{
    if (!aBundle)
        aBundle = [CPBundle mainBundle];
    
    if (aSize)
        return [[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:aFilename] size:aSize];
    
    return [[CPImage alloc] initWithContentsOfFile:[aBundle pathForResource:aFilename]];
}

@implementation CPBundle (CPImageAdditions)

- (CPString)pathForResource:(CPString)aFilename
{
    return [self resourcePath] + '/' + aFilename;
}

@end

/*! @class CPImage

    CPImage is used to represent images in the Cappuccino framework. It supports loading
    all image types supported by the browser.

    @par Delegate Methods
    
    @delegate -(void)imageDidLoad:(CPImage)image;
    Called when the specified image has finished loading.
    @param image the image that loaded

    @delegate -(void)imageDidError:(CPImage)image;
    Called when the specified image had an error loading.
    @param image the image with the loading error

    @delegate -(void)imageDidAbort:(CPImage)image;
    Called when the image loading was aborted.
    @param image the image that was aborted
*/
@implementation CPImage : CPObject
{
    CGSize      _size;
    CPString    _filename;
    
    id          _delegate;
    unsigned    _loadStatus;
    
    Image       _image;
}

/*!
    Initializes the image, by associating it with a filename. The image
    denoted in <code>aFilename</code> is not actually loaded. It will
    be loaded once needed.
    @param aFilename the file containing the image
    @param aSize the image's size
    @return the initialized image
*/
- (CPImage)initByReferencingFile:(CPString)aFilename size:(CGSize)aSize
{
    self = [super init];
    
    if (self)
    {
        _size = CPSizeCreateCopy(aSize);
        _filename = aFilename;
        _loadStatus = CPImageLoadStatusInitialized;
    }
    
    return self;
}

/*!
    Initializes the image. Loads the specified image into memory.
    @param aFilename the image to load
    @param aSize the size of the image
    @return the initialized image.
*/
- (CPImage)initWithContentsOfFile:(CPString)aFilename size:(CGSize)aSize
{
    self = [self initByReferencingFile:aFilename size:aSize];
    
    if (self)
        [self load];
    
    return self;
}

/*!
    Initializes the receiver with the contents of the specified
    image file. The method loads the data into memory.
    @param aFilename the file name of the image
    @return the initialized image
*/
- (CPImage)initWithContentsOfFile:(CPString)aFilename
{
    self = [self initByReferencingFile:aFilename size: CGSizeMake(-1, -1)];
    
    if (self)
        [self load];
    
    return self;
}

/*!
    Returns the path of the file associated with this image.
*/
- (CPString)filename
{
    return _filename;
}

/*!
    Sets the size of the image.
    @param the size of the image
*/
- (void)setSize:(CGSize)aSize
{
    _size = CGSizeMakeCopy(aSize);
}

/*!
    Returns the size of the image
*/
- (CGSize)size
{
    return _size;
}

/*!
    Sets the receiver's delegate.
    @param the delegate
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

/*!
    Returns the receiver's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Returns <code>YES</code> if the image data has already been loaded.
*/
- (BOOL)loadStatus
{
    return _loadStatus;
}

/*!
    Loads the image data from the file into memory. You
    should not call this method directly. Instead use
    one of the initializers.
*/

- (void)load
{
    if (_loadStatus == CPImageLoadStatusLoading || _loadStatus == CPImageLoadStatusCompleted)
        return;
        
    _loadStatus = CPImageLoadStatusLoading;

    _image = new Image();

    var isSynchronous = YES;

    // FIXME: We need a better/performance way of doing this.
    _image.onload = function ()
        {
            if (isSynchronous)
                window.setTimeout(function() { [self _imageDidLoad]; }, 0);
            else
            {
                [self _imageDidLoad];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
        }
    
    _image.onerror = function ()
        {
            if (isSynchronous)
                window.setTimeout(function() { [self _imageDidError]; }, 0);
            else
            {
                [self _imageDidError];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
        }
    
    _image.onabort = function ()
        {
            if (isSynchronous)
                window.setTimeout(function() { [self _imageDidAbort]; }, 0);
            else
            {
                [self _imageDidAbort];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
        }
        
    _image.src = _filename;
    
    isSynchronous = NO;
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return NO;
}

/* @ignore */
- (void)_imageDidLoad
{
    _loadStatus = CPImageLoadStatusCompleted;

    // FIXME: IE is wrong on image sizes????
    if (!_size || (_size.width == -1 && _size.height == -1))
        _size = CGSizeMake(_image.width, _image.height);

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPImageDidLoadNotification
        object:self];
        
    if ([_delegate respondsToSelector:@selector(imageDidLoad:)])
        [_delegate imageDidLoad:self];
}

/* @ignore */
- (void)_imageDidError
{
    _loadStatus = CPImageLoadStatusReadError;
    
    if ([_delegate respondsToSelector:@selector(imageDidError:)])
        [_delegate imageDidError:self];
}

/* @ignore */
- (void)_imageDidAbort
{
    _loadStatus = CPImageLoadStatusCancelled;
    
    if ([_delegate respondsToSelector:@selector(imageDidAbort:)])
        [_delegate imageDidAbort:self];
}

@end

@implementation CPImage (CPCoding)

/*!
    Initializes the image with data from a coder.
    @param aCoder the coder from which to read the image data
    @return the initialized image
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithContentsOfFile:[aCoder decodeObjectForKey:@"CPFilename"] size:[aCoder decodeSizeForKey:@"CPSize"]];
}

/*!
    Writes the image data from memory into the coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_filename forKey:@"CPFilename"];
    [aCoder encodeSize:_size forKey:@"CPSize"];
}

@end

@implementation CPThreePartImage : CPObject
{
    CPArray _imageSlices;
    BOOL    _isVertical;
}

- (id)initWithImageSlices:(CPArray)imageSlices isVertical:(BOOL)isVertical
{
    self = [super init];
    
    if (self)
    {
        _imageSlices = imageSlices;
        _isVertical = isVertical;
    }

    return self;
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isVertical
{
    return _isVertical;
}

- (BOOL)isThreePartImage
{
    return YES;
}

- (BOOL)isNinePartImage
{
    return NO;
}

@end

var CPThreePartImageImageSlicesKey  = @"CPThreePartImageImageSlicesKey",
    CPThreePartImageIsVerticalKey   = @"CPThreePartImageIsVerticalKey";

@implementation CPThreePartImage (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _imageSlices = [aCoder decodeObjectForKey:CPThreePartImageImageSlicesKey];
        _isVertical = [aCoder decodeBoolForKey:CPThreePartImageIsVerticalKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_imageSlices forKey:CPThreePartImageImageSlicesKey];
    [aCoder encodeBool:_isVertical forKey:CPThreePartImageIsVerticalKey];
}

@end


@implementation CPNinePartImage : CPObject
{
    CPArray _imageSlices;
}

- (id)initWithImageSlices:(CPArray)imageSlices
{
    self = [super init];
    
    if (self)
        _imageSlices = imageSlices;
    
    return self;
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return YES;
}

@end

var CPNinePartImageImageSlicesKey   = @"CPNinePartImageImageSlicesKey";

@implementation CPNinePartImage (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
        _imageSlices = [aCoder decodeObjectForKey:CPNinePartImageImageSlicesKey];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_imageSlices forKey:CPNinePartImageImageSlicesKey];
}

@end
