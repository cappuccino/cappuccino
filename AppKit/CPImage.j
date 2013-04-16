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
@import <Foundation/CPData.j>

@import "CGGeometry.j"
@import "CPCompatibility.j"

CPImageLoadStatusInitialized    = 0;
CPImageLoadStatusLoading        = 1;
CPImageLoadStatusCompleted      = 2;
CPImageLoadStatusCancelled      = 3;
CPImageLoadStatusInvalidData    = 4;
CPImageLoadStatusUnexpectedEOF  = 5;
CPImageLoadStatusReadError      = 6;

CPImageDidLoadNotification      = @"CPImageDidLoadNotification";

// Image Names
CPImageNameColorPanel               = @"CPImageNameColorPanel";
CPImageNameColorPanelHighlighted    = @"CPImageNameColorPanelHighlighted";

var imagesForNames = { },
    AppKitImageForNames = { },
    ImageDescriptionFormat = "%s {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}";

AppKitImageForNames[CPImageNameColorPanel]              = CGSizeMake(26.0, 29.0);
AppKitImageForNames[CPImageNameColorPanelHighlighted]   = CGSizeMake(26.0, 29.0);

/*!
    Returns a resource image with a relative path and size
    in a bundle.

    @param filename A filename or relative path to a resource image.
    @param width    Width of the image. May be omitted.
    @param height   Height of the image. May be omitted if width is omitted.
    @param size     Instead of passing width/height, a CGSize may be passed.
    @param bundle   Bundle in which the image resource can be found.
                    If omitted, defaults to the main bundle.
    @return CPImage
*/
function CPImageInBundle()
{
    var filename = arguments[0],
        size = nil,
        bundle = nil;

    if (typeof(arguments[1]) === "number")
    {
        if (arguments[1] !== nil && arguments[1] !== undefined)
            size = CGSizeMake(arguments[1], arguments[2]);

        bundle = arguments[3];
    }
    else if (typeof(arguments[1]) === "object")
    {
        size = arguments[1];
        bundle = arguments[2];
    }

    if (!bundle)
        bundle = [CPBundle mainBundle];

    if (size)
        return [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:filename] size:size];

    return [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:filename]];
}

function CPAppKitImage(aFilename, aSize)
{
    return CPImageInBundle(aFilename, aSize, [CPBundle bundleForClass:[CPView class]]);
}

/*!
    @ingroup appkit
    @class CPImage

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
    CPString    _name;

    id          _delegate;
    unsigned    _loadStatus;

    Image       _image;
}

- (id)init
{
    return [self initByReferencingFile:@"" size:CGSizeMake(-1, -1)];
}

/*!
    Initializes the image, by associating it with a filename. The image
    denoted in \c aFilename is not actually loaded. It will
    be loaded once needed.
    @param aFilename the file containing the image
    @param aSize the image's size
    @return the initialized image
*/
- (id)initByReferencingFile:(CPString)aFilename size:(CGSize)aSize
{
    self = [super init];

    if (self)
    {
        _size = CGSizeMakeCopy(aSize);
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
- (id)initWithContentsOfFile:(CPString)aFilename size:(CGSize)aSize
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
- (id)initWithContentsOfFile:(CPString)aFilename
{
    self = [self initByReferencingFile:aFilename size:CGSizeMake(-1, -1)];

    if (self)
        [self load];

    return self;
}

/*!
    Initializes the receiver with the specified data. The method loads the data into memory.
    @param someData the CPData object representing the image
    @return the initialized image
*/
- (id)initWithData:(CPData)someData
{
    var base64 = [someData base64],
        type = [base64 hasPrefix:@"/9j/4AAQSkZJRgABAQEASABIAAD/"] ? @"jpg" : @"png",
        dataURL = "data:image/" + type + ";base64," + base64;

    return [self initWithContentsOfFile:dataURL];
}

/*!
    Returns the path of the file associated with this image.
*/
- (CPString)filename
{
    return _filename;
}

/*!
    Returns the data associated with this image.
    @discussion Returns nil if the reciever was not initialized with -initWithData: and the browser does not support the canvas feature;
*/
- (CPData)data
{
#if PLATFORM(DOM)
    var dataURL;

    if ([_filename hasPrefix:@"data:image"])
        dataURL = _filename;
    else if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
    {
        var canvas = document.createElement("canvas"),
            ctx = canvas.getContext("2d");

        canvas.width = _image.width,
        canvas.height = _image.height;

        ctx.drawImage(_image, 0, 0);

        dataURL = canvas.toDataURL("image/png");
    }
    else
        return nil;

    var base64 = dataURL.replace(/^data:image\/png;base64,/, "");
    return [CPData dataWithBase64:base64];
#endif
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

+ (id)imageNamed:(CPString)aName
{
    var image = imagesForNames[aName];

    if (image)
        return image;

    var imageOrSize = AppKitImageForNames[aName];

    if (!imageOrSize)
        return nil;

    if (!imageOrSize.isa)
    {
        imageOrSize = CPAppKitImage("CPImage/" + aName + ".png", imageOrSize);

        [imageOrSize setName:aName];

        AppKitImageForNames[aName] = imageOrSize;
    }

    return imageOrSize;
}

- (BOOL)setName:(CPString)aName
{
    if (_name === aName)
        return YES;

    if (imagesForNames[aName])
        return NO;

    _name = aName;

    imagesForNames[aName] = self;

    return YES;
}

- (CPString)name
{
    return _name;
}

/*!
    Returns the underlying Image element for a single image.
*/
- (Image)image
{
    return _image;
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
    Returns the load status, which will be CPImageLoadStatusCompleted if the image data has already been loaded.
*/
- (unsigned)loadStatus
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

#if PLATFORM(DOM)
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
            [self _derefFromImage];
        };

    _image.onerror = function ()
        {
            if (isSynchronous)
                window.setTimeout(function() { [self _imageDidError]; }, 0);
            else
            {
                [self _imageDidError];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
            [self _derefFromImage];
        };

    _image.onabort = function ()
        {
            if (isSynchronous)
                window.setTimeout(function() { [self _imageDidAbort]; }, 0);
            else
            {
                [self _imageDidAbort];
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }
            [self _derefFromImage];
        };

    _image.src = _filename;

    // onload and friends may fire after this point but BEFORE the end of the run loop,
    // crazy, I know. So don't set isSynchronous here, rather wait a bit longer.
    window.setTimeout(function() { isSynchronous = NO; }, 0);
#endif
}

- (BOOL)isSingleImage
{
    return YES;
}

- (BOOL)isThreePartImage
{
    return NO;
}

- (BOOL)isNinePartImage
{
    return NO;
}

- (CPString)description
{
    var filename = [self filename],
        size = [self size];

    if (filename.indexOf("data:") === 0)
    {
        var index = filename.indexOf(",");

        if (index > 0)
            filename = [CPString stringWithFormat:@"%s,%s...%s", filename.substr(0, index), filename.substr(index + 1, 10), filename.substr(filename.length - 10)];
        else
            filename = "data:<unknown type>";
    }

    return [CPString stringWithFormat:ImageDescriptionFormat, [super description], filename, size.width, size.height];
}

/* @ignore */
- (void)_derefFromImage
{
    _image.onload = null;
    _image.onerror = null;
    _image.onabort = null;
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

- (CPString)filename
{
    return @"";
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isVertical
{
    return _isVertical;
}

- (BOOL)isSingleImage
{
    return NO;
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

- (CPString)filename
{
    return @"";
}

- (CPArray)imageSlices
{
    return _imageSlices;
}

- (BOOL)isSingleImage
{
    return NO;
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
