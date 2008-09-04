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
 
import <Foundation/CPObject.j>
import <Foundation/CPString.j>
import <Foundation/CPBundle.j>
import <Foundation/CPRunLoop.j>

import "CPGeometry.j"

CPImageLoadStatusInitialized    = 0;
CPImageLoadStatusLoading        = 1;
CPImageLoadStatusCompleted      = 2;
CPImageLoadStatusCancelled      = 3;
CPImageLoadStatusInvalidData    = 4;
CPImageLoadStatusUnexpectedEOF  = 5;
CPImageLoadStatusReadError      = 6;

@implementation CPBundle (CPImageAdditions)

- (CPString)pathForResource:(CPString)aFilename
{
    return [self bundlePath] + "Resources/" + aFilename;
}

@end

@implementation CPImage : CPObject
{
    CPSize      _size;
    CPString    _filename;
    
    id          _delegate;
    unsigned    _loadStatus;
    
    Image       _image;
}

- (CPImage)initByReferencingFile:(CPString)aFilename size:(CPSize)aSize
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

- (CPImage)initWithContentsOfFile:(CPString)aFilename size:(CPSize)aSize
{
    self = [self initByReferencingFile:aFilename size:aSize];
    
    if (self)
        [self load];
    
    return self;
}

- (CPImage)initWithContentsOfFile:(CPString)aFilename
{
    self = [self initByReferencingFile:aFilename size: CGSizeMake(-1, -1)];
    
    if (self)
        [self load];
    
    return self;
}

- (CPString)filename
{
    return _filename;
}

- (void)setSize:(CPSize)aSize
{
    _size = CGSizeMakeCopy(aSize);
}

- (CGSize)size
{
    return _size;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (BOOL)loadStatus
{
    return _loadStatus;
}

- (void)load
{
    if (_loadStatus == CPImageLoadStatusLoading || _loadStatus == CPImageLoadStatusCompleted)
        return;
        
    _loadStatus = CPImageLoadStatusLoading;

    _image = new Image();

    var isSynchronous = YES;

    // FIXME: We need a better/performance way of doing this.
    _image.onload = function () { if (isSynchronous) window.setTimeout(function() { [self _imageDidLoad] }, 0); else [self _imageDidLoad]; }
    _image.onerror = function () { if (isSynchronous) window.setTimeout(function() { [self _imageDidError] }, 0); else [self _imageDidError]; }
    _image.onabort = function () { if (isSynchronous) window.setTimeout(function() { [self _imageDidAbort] }, 0); else [self _imageDidAbort]; }
        
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

- (void)_imageDidLoad
{
    _loadStatus = CPImageLoadStatusCompleted;

    // FIXME: IE is wrong on image sizes????
    if (!_size || (_size.width == -1 && _size.height == -1))
        _size = CGSizeMake(_image.width, _image.height);
    
    if ([_delegate respondsToSelector:@selector(imageDidLoad:)])
        [_delegate imageDidLoad:self];

    [[CPRunLoop currentRunLoop] performSelectors];
}

- (void)_imageDidError
{
    _loadStatus = CPImageLoadStatusReadError;
    
    if ([_delegate respondsToSelector:@selector(imageDidError:)])
        [_delegate imageDidError:self];

    [[CPRunLoop currentRunLoop] performSelectors];
}

- (void)_imageDidAbort
{
    _loadStatus = CPImageLoadStatusCancelled;
    
    if ([_delegate respondsToSelector:@selector(imageDidAbort:)])
        [_delegate imageDidAbort:self];

    [[CPRunLoop currentRunLoop] performSelectors];
}

@end

@implementation CPImage (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithContentsOfFile:[aCoder decodeObjectForKey:@"CPFilename"] size:[aCoder decodeSizeForKey:@"CPSize"]];
}

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
