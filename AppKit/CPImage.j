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
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@import "_CPObject+Theme.j"
@import "CGGeometry.j"
@import "CPAppearance.j"
@import "CPCompatibility.j"
@import "CPGraphicsContext.j"
@import "CPTheme.j"

@class CPColor
@class _CPSystemImage
@global document

@protocol CPImageDelegate <CPObject>

@optional
- (void)imageDidLoad:(CPImage)anImage;
- (void)imageDidError:(CPImage)anImage;
- (void)imageDidAbort:(CPImage)anImage;

@end

var CPImageDelegate_imageDidLoad_   = 1 << 1,
    CPImageDelegate_imageDidError_  = 1 << 2,
    CPImageDelegate_imageDidAbort_  = 1 << 3;

CPImageLoadStatusInitialized    = 0;
CPImageLoadStatusLoading        = 1;
CPImageLoadStatusCompleted      = 2;
CPImageLoadStatusCancelled      = 3;
CPImageLoadStatusInvalidData    = 4;
CPImageLoadStatusUnexpectedEOF  = 5;
CPImageLoadStatusReadError      = 6;

CPImageDidLoadNotification      = @"CPImageDidLoadNotification";

/*
    System image names. Each constant has the name of an AppKit NSImageName constant with CP in
    place of NS, and AppKit's string with CP in place of NS, so that nib2cib maps an image name
    in a XIB by replacing the prefix. CPImageNameColorPanel keeps the string that it had before
    Cappuccino took AppKit's names, because existing cibs hold that string; nib2cib maps
    NSColorPanel to it. CPImageNameColorPanelHighlighted is Cappuccino's own name, for the
    highlighted image of the Colors toolbar item. AppKit's Touch Bar names are absent, because
    Cappuccino has no touch bar.
*/
CPImageNameActionTemplate                       = @"CPActionTemplate";
CPImageNameAddTemplate                          = @"CPAddTemplate";
CPImageNameAdvanced                             = @"CPAdvanced";
CPImageNameApplicationIcon                      = @"CPApplicationIcon";
CPImageNameBluetoothTemplate                    = @"CPBluetoothTemplate";
CPImageNameBonjour                              = @"CPBonjour";
CPImageNameBookmarksTemplate                    = @"CPBookmarksTemplate";
CPImageNameCaution                              = @"CPCaution";
CPImageNameColumnViewTemplate                   = @"CPColumnViewTemplate";
CPImageNameComputer                             = @"CPComputer";
CPImageNameDotMac                               = @"CPDotMac";
CPImageNameEnterFullScreenTemplate              = @"CPEnterFullScreenTemplate";
CPImageNameEveryone                             = @"CPEveryone";
CPImageNameExitFullScreenTemplate               = @"CPExitFullScreenTemplate";
CPImageNameFlowViewTemplate                     = @"CPFlowViewTemplate";
CPImageNameFolder                               = @"CPFolder";
CPImageNameFolderBurnable                       = @"CPFolderBurnable";
CPImageNameFolderSmart                          = @"CPFolderSmart";
CPImageNameFollowLinkFreestandingTemplate       = @"CPFollowLinkFreestandingTemplate";
CPImageNameFontPanel                            = @"CPFontPanel";
CPImageNameGoBackTemplate                       = @"CPGoBackTemplate";
CPImageNameGoForwardTemplate                    = @"CPGoForwardTemplate";
CPImageNameGoLeftTemplate                       = @"CPGoLeftTemplate";
CPImageNameGoRightTemplate                      = @"CPGoRightTemplate";
CPImageNameHomeTemplate                         = @"CPHomeTemplate";
CPImageNameIChatTheaterTemplate                 = @"CPIChatTheaterTemplate";
CPImageNameIconViewTemplate                     = @"CPIconViewTemplate";
CPImageNameInfo                                 = @"CPInfo";
CPImageNameInvalidDataFreestandingTemplate      = @"CPInvalidDataFreestandingTemplate";
CPImageNameLeftFacingTriangleTemplate           = @"CPLeftFacingTriangleTemplate";
CPImageNameListViewTemplate                     = @"CPListViewTemplate";
CPImageNameLockLockedTemplate                   = @"CPLockLockedTemplate";
CPImageNameLockUnlockedTemplate                 = @"CPLockUnlockedTemplate";
CPImageNameMenuMixedStateTemplate               = @"CPMenuMixedStateTemplate";
CPImageNameMenuOnStateTemplate                  = @"CPMenuOnStateTemplate";
CPImageNameMobileMe                             = @"CPMobileMe";
CPImageNameMultipleDocuments                    = @"CPMultipleDocuments";
CPImageNameNetwork                              = @"CPNetwork";
CPImageNamePathTemplate                         = @"CPPathTemplate";
CPImageNamePreferencesGeneral                   = @"CPPreferencesGeneral";
CPImageNameQuickLookTemplate                    = @"CPQuickLookTemplate";
CPImageNameRefreshFreestandingTemplate          = @"CPRefreshFreestandingTemplate";
CPImageNameRefreshTemplate                      = @"CPRefreshTemplate";
CPImageNameRemoveTemplate                       = @"CPRemoveTemplate";
CPImageNameRevealFreestandingTemplate           = @"CPRevealFreestandingTemplate";
CPImageNameRightFacingTriangleTemplate          = @"CPRightFacingTriangleTemplate";
CPImageNameShareTemplate                        = @"CPShareTemplate";
CPImageNameSlideshowTemplate                    = @"CPSlideshowTemplate";
CPImageNameSmartBadgeTemplate                   = @"CPSmartBadgeTemplate";
CPImageNameStatusAvailable                      = @"CPStatusAvailable";
CPImageNameStatusNone                           = @"CPStatusNone";
CPImageNameStatusPartiallyAvailable             = @"CPStatusPartiallyAvailable";
CPImageNameStatusUnavailable                    = @"CPStatusUnavailable";
CPImageNameStopProgressFreestandingTemplate     = @"CPStopProgressFreestandingTemplate";
CPImageNameStopProgressTemplate                 = @"CPStopProgressTemplate";
CPImageNameTrashEmpty                           = @"CPTrashEmpty";
CPImageNameTrashFull                            = @"CPTrashFull";
CPImageNameUser                                 = @"CPUser";
CPImageNameUserAccounts                         = @"CPUserAccounts";
CPImageNameUserGroup                            = @"CPUserGroup";
CPImageNameUserGuest                            = @"CPUserGuest";
CPImageNameColorPanel                           = @"CPImageNameColorPanel";
CPImageNameColorPanelHighlighted                = @"CPImageNameColorPanelHighlighted";

var imagesForNames = { },
    ImageDescriptionFormat = "%s {\n   filename: \"%s\",\n   size: { width:%f, height:%f }\n}",
    CPImageSystemImageNameKey = @"CPImageSystemImageNameKey",

    /*
        The system image names, each with its default image: the AppKit resource that holds the
        image, with its size, or null when only a theme gives the image.
    */
    _CPSystemImageDefaults = {
        "CPActionTemplate":                        null,
        "CPAddTemplate":                           null,
        "CPAdvanced":                              null,
        "CPApplicationIcon":                       null,
        "CPBluetoothTemplate":                     null,
        "CPBonjour":                               null,
        "CPBookmarksTemplate":                     null,
        "CPCaution":                               null,
        "CPColumnViewTemplate":                    null,
        "CPComputer":                              null,
        "CPDotMac":                                null,
        "CPEnterFullScreenTemplate":               null,
        "CPEveryone":                              null,
        "CPExitFullScreenTemplate":                null,
        "CPFlowViewTemplate":                      null,
        "CPFolder":                                null,
        "CPFolderBurnable":                        null,
        "CPFolderSmart":                           null,
        "CPFollowLinkFreestandingTemplate":        null,
        "CPFontPanel":                             null,
        "CPGoBackTemplate":                        null,
        "CPGoForwardTemplate":                     null,
        "CPGoLeftTemplate":                        null,
        "CPGoRightTemplate":                       null,
        "CPHomeTemplate":                          null,
        "CPIChatTheaterTemplate":                  null,
        "CPIconViewTemplate":                      null,
        "CPInfo":                                  null,
        "CPInvalidDataFreestandingTemplate":       null,
        "CPLeftFacingTriangleTemplate":            null,
        "CPListViewTemplate":                      null,
        "CPLockLockedTemplate":                    null,
        "CPLockUnlockedTemplate":                  null,
        "CPMenuMixedStateTemplate":                null,
        "CPMenuOnStateTemplate":                   null,
        "CPMobileMe":                              null,
        "CPMultipleDocuments":                     null,
        "CPNetwork":                               null,
        "CPPathTemplate":                          null,
        "CPPreferencesGeneral":                    null,
        "CPQuickLookTemplate":                     null,
        "CPRefreshFreestandingTemplate":           null,
        "CPRefreshTemplate":                       null,
        "CPRemoveTemplate":                        null,
        "CPRevealFreestandingTemplate":            null,
        "CPRightFacingTriangleTemplate":           null,
        "CPShareTemplate":                         null,
        "CPSlideshowTemplate":                     null,
        "CPSmartBadgeTemplate":                    null,
        "CPStatusAvailable":                       null,
        "CPStatusNone":                            null,
        "CPStatusPartiallyAvailable":              null,
        "CPStatusUnavailable":                     null,
        "CPStopProgressFreestandingTemplate":      null,
        "CPStopProgressTemplate":                  null,
        "CPTrashEmpty":                            null,
        "CPTrashFull":                             null,
        "CPUser":                                  null,
        "CPUserAccounts":                          null,
        "CPUserGroup":                             null,
        "CPUserGuest":                             null,
        "CPImageNameColorPanel":                   ["CPImage/CPImageNameColorPanel.png", 26.0, 29.0],
        "CPImageNameColorPanelHighlighted":        ["CPImage/CPImageNameColorPanelHighlighted.png", 26.0, 29.0]
    },
    _CPSystemImages = {},
    _CPSystemImageDefaultValues = {};

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

/// @cond IGNORE

/*
    Returns YES when aName is the name of a system image.
*/
function _CPImageIsSystemImageName(aName)
{
    return _CPSystemImageDefaults.hasOwnProperty(aName);
}

/*
    Returns the theme attribute of CPImage that holds a theme's values for the system image
    aName: the name without CP, in lower case with words joined by hyphens (CPAddTemplate is
    "add-template"). Cappuccino's own names also drop ImageName (CPImageNameColorPanel is
    "color-panel").
*/
function _CPThemeAttributeForSystemImageName(aName)
{
    return aName.replace(/^CP(ImageName)?/, "").replace(/([A-Z])/g, "-$1").toLowerCase().substring(1);
}

/*
    Returns the image for the system image aName in anAppearance: the current theme's value for
    anAppearance (see _CPThemeAttributeValueForAppearance), then the default image in
    _CPSystemImageDefaults, or nil when the system image has no default.
*/
function _CPSystemImageValue(aName, anAppearance)
{
    var attribute = [[CPTheme defaultTheme] attributeWithName:_CPThemeAttributeForSystemImageName(aName) forClass:[CPImage defaultThemeClass]],
        themeValue = _CPThemeAttributeValueForAppearance(attribute, anAppearance);

    if (themeValue)
        return themeValue;

    if (!_CPSystemImageDefaultValues.hasOwnProperty(aName))
    {
        var resource = _CPSystemImageDefaults[aName];

        _CPSystemImageDefaultValues[aName] = resource ? CPAppKitImage(resource[0], CGSizeMake(resource[1], resource[2])) : nil;
    }

    return _CPSystemImageDefaultValues[aName];
}

/// @endcond

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
@implementation CPImage : CPObject <CPTheme>
{
    CGSize                  _size;
    CPString                _filename;
    CPString                _name;

    id <CPImageDelegate>    _delegate;
    unsigned                _loadStatus;
    unsigned                _implementedDelegateMethods;

    Image                   _image;
}

// MARK: -
// MARK: Theming

+ (CPString)defaultThemeClass
{
    return "image";
}

/*
    CPImage has one theme attribute for each system image, which holds the theme's values for
    that image (see _CPSystemImageValue).
*/
+ (CPDictionary)themeAttributes
{
    var attributes = @{};

    for (var imageName in _CPSystemImageDefaults)
        [attributes setObject:[CPNull null] forKey:_CPThemeAttributeForSystemImageName(imageName)];

    return attributes;
}

- (id)init
{
    return [self initByReferencingFile:@"" size:CGSizeMake(-1, -1)];
}

/*!
    Initializes the image, by associating it with a filename. The image
    denoted in \c aFilename is not actually loaded. It will be loaded
    once needed.

    @param aFilename the file containing the image
    @param aSize the image's size
    @return the initialized image
*/
- (id)initByReferencingFile:(CPString)aFilename size:(CGSize)aSize
{
    // Quietly return nil like in Cocoa, rather than crashing later.
    if (aFilename == nil)
        return nil;

    self = [super init];

    if (self)
    {
        _size = CGSizeMakeCopy(aSize);
        _filename = aFilename;
        _loadStatus = CPImageLoadStatusInitialized;

        [self _initTheming];
    }

    return self;
}

/*
    Setting a theme value on a CPImage raised "CPImage does not contain theme attribute", because
    an object that is not a view loads its theme attributes only when its initialiser asks for
    them. A theme records its system images on a CPImage (see +themeAttributes), so each CPImage
    initialiser loads them, as the initialisers of CPColor and CPFont do.
*/
- (void)_initTheming
{
    _theme = [CPTheme defaultTheme];
    _themeState = CPThemeStateNormal;
    [self _loadThemeAttributes];
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
    if (!CPDOMAvailable) return;

    var dataURL;

    if ([_filename hasPrefix:@"data:image"])
        dataURL = _filename;
    else if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
    {
        var canvas = document.createElement("canvas"),
            ctx = canvas.getContext("2d");

        canvas.width = _image.width;
        canvas.height = _image.height;

        ctx.drawImage(_image, 0, 0);

        dataURL = canvas.toDataURL("image/png");
    }
    else
        return nil;

    var base64 = dataURL.replace(/^data:image\/png;base64,/, "");
    return [CPData dataWithBase64:base64];
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
    return CGSizeMakeCopy(_size);
}

/*!
    Returns the image with the name \c aName: an image registered under that name with
    -setName:, or else the system image of that name, such as CPImageNameAddTemplate. A system
    image takes its picture from the current theme and the drawing appearance each time it is
    used, so it follows a theme switch. +imageNamed: returns one shared instance for each
    system image.
    @param aName the name of the image
    @return the image, or \c nil when no image has that name
*/
+ (id)imageNamed:(CPString)aName
{
    var image = imagesForNames[aName];

    if (image)
        return image;

    return [self _systemImageNamed:aName];
}

/*
    Returns the shared system image with the name aName, or nil when aName is not a system
    image name.
*/
+ (CPImage)_systemImageNamed:(CPString)aName
{
    if (!_CPImageIsSystemImageName(aName))
        return nil;

    var image = _CPSystemImages[aName];

    if (!image)
        image = _CPSystemImages[aName] = [[_CPSystemImage alloc] _initWithSystemImageName:aName];

    return image;
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
- (void)setDelegate:(id <CPImageDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(imageDidLoad:)])
        _implementedDelegateMethods |= CPImageDelegate_imageDidLoad_;

    if ([_delegate respondsToSelector:@selector(imageDidError:)])
        _implementedDelegateMethods |= CPImageDelegate_imageDidError_;

    if ([_delegate respondsToSelector:@selector(imageDidAbort:)])
        _implementedDelegateMethods |= CPImageDelegate_imageDidAbort_;
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

    if (!CPDOMAvailable) return;

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

- (BOOL)isMaterialIconImage
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

    if (_implementedDelegateMethods & CPImageDelegate_imageDidLoad_)
        [_delegate imageDidLoad:self];
}

/* @ignore */
- (void)_imageDidError
{
    _loadStatus = CPImageLoadStatusReadError;

    if (_implementedDelegateMethods & CPImageDelegate_imageDidError_)
        [_delegate imageDidError:self];
}

/* @ignore */
- (void)_imageDidAbort
{
    _loadStatus = CPImageLoadStatusCancelled;

    if (_implementedDelegateMethods & CPImageDelegate_imageDidAbort_)
        [_delegate imageDidAbort:self];
}

@end

// MARK: -
// MARK: CSS Theming

// The code below adds support for CSS theming with 100% compatibility with current theming system.
// The idea is to extend CPImage (and CPColor) with CSS components and adapt low level UI components to
// support this new kind of CPColor/CPImage. See CPImageView, CPView and _CPImageAndTextView.
//
// To create a CPImage that uses CSS, simply use the new class method :
// + (CPImage)imageWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary size:(CGSize)aSize
// where beforeDictionary & afterDictionary are related to ::before & ::after pseudo-elements.
// If you don't need them, just use the simplified class method :
// + (CPImage)imageWithCSSDictionary:(CPDictionary)aDictionary size:(CGSize)aSize
//
// Examples :
// regularImageNormal = [CPImage imageWithCSSDictionary:@{
//                                                        @"border-color": A3ColorActiveBorder,
//                                                        @"border-style": @"solid",
//                                                        @"border-width": @"1px",
//                                                        @"border-radius": @"50%",
//                                                        @"box-sizing": @"border-box",
//                                                        @"background-color": A3ColorBackgroundWhite,
//                                                        @"transition-duration": @"0.35s",
//                                                        @"transition-property": @"all",
//                                                        @"transition-timing-function": @"ease"
//                                                        }
//                                                 size:CGSizeMake(16,16)];
//
// imageSearch = [CPImage imageWithCSSDictionary:@{
//                                                 @"background-image": @"url(%%packed.png)",
//                                                 @"background-position": @"-16px -32px",
//                                                 @"background-repeat": @"no-repeat",
//                                                 @"background-size": @"100px 400px"
//                                                 }
//                                          size:CGSizeMake(16,16)];
//
// Remark : Please note the special URL of the background image used in this example : url(%%packed.png)
//          During theme loading, "%%" will be replaced by the path to the theme blend resources folder.
//          Typically, a CSS theme will use some (rare) images all packed together in a single image resource (see packed.png in Aristo3 theme)
//
//          Also, please note that if you don't use one of the CSS components, you can either set it to nil (best solution) or to an empty dictionary, like :
//          aCssImage = [CPImage imageWithCSSDictionary:@{} beforeDictionary:nil afterDictionary:@{ ... }];
//
// You can use -(BOOL)isCSSBased to determine how to cope with it in your code.
// -(BOOL)hasCSSDictionary, -(BOOL)hasCSSBeforeDictionary and -(BOOL)hasCSSAfterDictionary are convience methods you can use.
//
// Remark : -(DOMElement)applyCSSImageForView is meant to be used by low level UI widgets (like CPImageView and _CPImageAndTextView) to implement CSS theme support.
//
// In some circumstances, you may have to clear a CSS image. You can do this easily by replacing your current image with the special dummy empty CSS image :
// [CPImage dummyCSSImageOfSize:CGSizeMake(someWidth, someHeight)]

@implementation CPImage (CSSTheming)
{
    CPDictionary            _cssDictionary              @accessors(property=cssDictionary);
    CPDictionary            _cssBeforeDictionary        @accessors(property=cssBeforeDictionary);
    CPDictionary            _cssAfterDictionary         @accessors(property=cssAfterDictionary);
    CGSize                  _displaySize;
}

+ (CPImage)imageWithCSSDictionary:(CPDictionary)aDictionary size:(CGSize)aSize
{
    return [[CPImage alloc] initWithCSSDictionary:aDictionary beforeDictionary:nil afterDictionary:nil size:aSize];
}

+ (CPImage)imageWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary size:(CGSize)aSize
{
    return [[CPImage alloc] initWithCSSDictionary:aDictionary beforeDictionary:beforeDictionary afterDictionary:afterDictionary size:aSize];
}

+ (CPImage)dummyCSSImageOfSize:(CGSize)aSize
{
    // This is used to clear a previous CSS image
    return [[CPImage alloc] initWithCSSDictionary:@{} beforeDictionary:nil afterDictionary:nil size:aSize];
}

+ (CPImage)imageWithMaterialIconNamed:(CPString)iconName size:(CGSize)size
{
    return [_CPMaterialIconImage imageWithIconNamed:iconName size:size];
}

+ (CPImage)imageWithMaterialIconNamed:(CPString)iconName size:(CGSize)size color:(CPColor)color
{
    return [_CPMaterialIconImage imageWithIconNamed:iconName size:size color:color];
}

- (id)initWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary size:(CGSize)aSize
{
    self = [super init];

    if (self)
    {
        [self _initTheming];

        _size = CGSizeMakeCopy(aSize);
        _filename = @"CSS image";
        _loadStatus = CPImageLoadStatusCompleted;
        _cssDictionary = aDictionary;
        _cssBeforeDictionary = beforeDictionary;
        _cssAfterDictionary = afterDictionary;
        _displaySize = CGSizeMakeCopy(aSize);
    }

    return self;
}

- (BOOL)isCSSBased
{
    return !!(_cssDictionary || _cssBeforeDictionary || _cssAfterDictionary);
}

- (BOOL)hasCSSDictionary
{
    return ([_cssDictionary count] > 0);
}

- (BOOL)hasCSSBeforeDictionary
{
    return ([_cssBeforeDictionary count] > 0);
}

- (BOOL)hasCSSAfterDictionary
{
    return ([_cssAfterDictionary count] > 0);
}

- (DOMElement)applyCSSImageForView:(CPView)aView onDOMElement:(DOMElement)aDOMElement styleNode:(DOMElement)aStyleNode previousState:(CPArrayRef)aPreviousStateRef
{
    if (!CPDOMAvailable) return;

    // First, restore previous CSS styling before applying the new one

    var aPreviousState = @deref(aPreviousStateRef);

    for (var i = 0, count = aPreviousState.length; i < count; i++)
        aDOMElement.style[aPreviousState[i][0]] = aPreviousState[i][1];

    aPreviousState = @[];

    // Then apply new CSS styling

    [_cssDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [aPreviousState addObject:@[aKey, aDOMElement.style[aKey]]];
         aDOMElement.style[aKey] = anObject;
     }];

    if (_cssBeforeDictionary || _cssAfterDictionary)
    {
        // We need to create a unique class name

        var styleClassName = @".CP" + [aView UID],
        styleContent = @"";

        if (_cssBeforeDictionary)
        {
            styleContent += styleClassName + @"::before { ";

            [_cssBeforeDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
             {
                 styleContent += aKey + ": " + anObject + "; ";
             }];

            styleContent += "} ";
        }

        if (_cssAfterDictionary)
        {
            styleContent += styleClassName + @"::after { ";

            [_cssAfterDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
             {
                 styleContent += aKey + ": " + anObject + "; ";
             }];

            styleContent += "} ";
        }

        var styleDescription = document.createTextNode(styleContent);

        if (!aStyleNode)
        {
            aStyleNode = document.createElement("style");

            aView._DOMElement.insertBefore(aStyleNode, aView._DOMElement.firstChild);

            aStyleNode.appendChild(styleDescription);
        }
        else
        {
            aStyleNode.replaceChild(styleDescription, aStyleNode.firstChild);
        }

        aDOMElement.className = @"CP"+[aView UID];
    }
    else
    {
        // no before/after so remove aStyleNode if existing

        if (aStyleNode)
        {
            aView._DOMElement.removeChild(aStyleNode);
            aStyleNode = nil;
        }
    }


    // Return actualised values

    @deref(aPreviousStateRef) = aPreviousState;

    return aStyleNode;
}

- (BOOL)_shouldBeResized
{
    return NO;
}

@end

var CPImageCSSDictionaryKey       = @"CPImageCSSDictionaryKey",
    CPImageCSSBeforeDictionaryKey = @"CPImageCSSBeforeDictionaryKey",
    CPImageCSSAfterDictionaryKey  = @"CPImageCSSAfterDictionaryKey";

// MARK: -

@implementation CPImage (CPCoding)

/*!
    Initializes the image with data from a coder.
    @param aCoder the coder from which to read the image data
    @return the initialized image
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if ([aCoder containsValueForKey:CPImageSystemImageNameKey])
        return [CPImage _systemImageNamed:[aCoder decodeObjectForKey:CPImageSystemImageNameKey]];

    if ([aCoder containsValueForKey:CPImageCSSDictionaryKey])
        return [self initWithCSSDictionary:[aCoder decodeObjectForKey:CPImageCSSDictionaryKey] beforeDictionary:[aCoder decodeObjectForKey:CPImageCSSBeforeDictionaryKey] afterDictionary:[aCoder decodeObjectForKey:CPImageCSSAfterDictionaryKey] size:[aCoder decodeSizeForKey:@"CPSize"]];
    else
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

    // CSS Styling
    if ([self isCSSBased])
    {
        [aCoder encodeObject:_cssDictionary       forKey:CPImageCSSDictionaryKey];
        [aCoder encodeObject:_cssBeforeDictionary forKey:CPImageCSSBeforeDictionaryKey];
        [aCoder encodeObject:_cssAfterDictionary  forKey:CPImageCSSAfterDictionaryKey];
    }
}

@end

// MARK: -
// MARK: Drawing

@implementation CPImage (Drawing)

- (void)drawAtPoint:(CGPoint)point fromRect:(CPRect)fromRect operation:(CGBlendMode)op fraction:(float)delta
{
    if (_loadStatus !== CPImageLoadStatusCompleted)
        return;

    var context = [CPGraphicsContext currentContext].graphicsPort;

    if (!context)
        return;

    CGContextSaveGState(context);

    CGContextSetBlendMode(context, op);
    CGContextSetAlpha(context, delta);

    context.drawImage(
        _image,
        fromRect.origin.x,
        fromRect.origin.y,
        fromRect.size.width,
        fromRect.size.height,
        point.x,
        point.y,
        fromRect.size.width,
        fromRect.size.height
    );

    CGContextRestoreGState(context);
}

@end


// MARK: -

@implementation _CPMaterialIconImage : CPImage
{
    CPMutableDictionary     _cachedColorVersions;
    CPColor                 _cachedInvertedColor;
}

+ (_CPMaterialIconImage)imageWithIconNamed:(CPString)iconName size:(CGSize)size
{
    return [[_CPMaterialIconImage alloc] initWithIconName:iconName size:size];
}

+ (_CPMaterialIconImage)imageWithIconNamed:(CPString)iconName size:(CGSize)size color:(CPColor)color
{
    return [[_CPMaterialIconImage alloc] initWithIconName:iconName size:size color:color];
}

+ (_CPMaterialIconImage)imageWithIconNamed:(CPString)iconName size:(CGSize)size color:(CPColor)color additionalCSSDictionary:(CPDictionary)additionalCSSDictionary
{
    return [[_CPMaterialIconImage alloc] initWithIconName:iconName size:size color:color additionalCSSDictionary:additionalCSSDictionary];
}

- (CPDictionary)_baseMaterialIconCSSDictionaryForIconName:(CPString)iconName size:(CGSize)size
{
    return @{
             @"width": size.width + @"px",
             @"height": size.height + @"px",
             @"top": @"0px",
             @"left": @"0px",
             @"content": @"'" + iconName + @"'",

             @"position": @"absolute",
             @"z-index": @"300",

             @"font-family": @"'Material Icons'",
             @"font-weight": @"normal",
             @"font-style": @"normal",
             @"font-size": MIN(size.width, size.height) + @"px",
             @"display": @"inline-block",
             @"line-height": @"1",
             @"text-transform": @"none",
             @"letter-spacing": @"normal",
             @"word-wrap": @"normal",
             @"white-space": @"nowrap",
             @"direction": @"ltr",
             @"-webkit-font-smoothing": @"antialiased",
             @"text-rendering": @"optimizeLegibility",
             @"-moz-osx-font-smoothing": @"grayscale",
             @"font-feature-settings": @"'liga'"
             };
}

- (_CPMaterialIconImage)initWithIconName:(CPString)iconName size:(CGSize)size
{
    return [super initWithCSSDictionary:@{}
                       beforeDictionary:@{}
                        afterDictionary:[self _baseMaterialIconCSSDictionaryForIconName:iconName size:size]
                                   size:size];
}

- (_CPMaterialIconImage)initWithIconName:(CPString)iconName size:(CGSize)size color:(CPColor)color
{
    var materialIconCSSDictionary = [self _baseMaterialIconCSSDictionaryForIconName:iconName size:size];

    [materialIconCSSDictionary setObject:[color cssString] forKey:@"color"];

    return [super initWithCSSDictionary:@{}
                       beforeDictionary:@{}
                        afterDictionary:materialIconCSSDictionary
                                   size:size];
}

- (void)addRotationEffectWithAngle:(float)angle
{
    [self addCSSDictionary:@{
                             @"transform":  @"rotate("+angle+"deg)",
                             @"transition": @"transform 0.35s ease"
                             }];
}

- (void)addCSSDictionary:(CPDictionary)additionalCSSDictionary
{
    [_cssAfterDictionary addEntriesFromDictionary:additionalCSSDictionary];
}

- (void)setSize:(CGSize)aSize
{
    [self _setDisplaySize:aSize];
    [super setSize:aSize];
}

- (void)_setDisplaySize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_displaySize, aSize))
        return;

    _displaySize = CGSizeMakeCopy(aSize);

    [_cssAfterDictionary setObject:(aSize.width + @"px") forKey:@"width"];
    [_cssAfterDictionary setObject:(aSize.height + @"px") forKey:@"height"];
    [_cssAfterDictionary setObject:(MIN(aSize.width, aSize.height) + @"px") forKey:@"font-size"];
}

- (BOOL)_shouldBeResized
{
    return YES;
}

- (BOOL)isMaterialIconImage
{
    return YES;
}

- (_CPMaterialIconImage)invertedImage
{
    if (!_cachedInvertedColor)
    {
        var sourceCSSColor = [_cssAfterDictionary objectForKey:@"color"] || @"rgba(0,0,0,1)",
            sourceColor    = [CPColor colorWithCSSString:sourceCSSColor];

        _cachedInvertedColor = [CPColor colorWithRed:(1-[sourceColor redComponent])
                                               green:(1-[sourceColor greenComponent])
                                                blue:(1-[sourceColor blueComponent])
                                               alpha:[sourceColor alphaComponent]];
    }

    return [self imageVersionWithColor:_cachedInvertedColor];
}

- (_CPMaterialIconImage)imageVersionWithColor:(CPColor)aColor
{
    // We can't just set the color in the cssAfterDictionary as this would not be noticed as a new image,
    // so -setImage won't do anything, so no visual refresh won't occur.
    // The trick here is to keep in cache a clone of this image for each needed color.
    var colorCSSString = [aColor cssString];

    if (!_cachedColorVersions)
        _cachedColorVersions = @{};

    var cachedColorVersion = [_cachedColorVersions objectForKey:colorCSSString];

    if (!cachedColorVersion)
    {
        cachedColorVersion = [self duplicate];
        [cachedColorVersion _setCSSColor:colorCSSString];

        [_cachedColorVersions setObject:cachedColorVersion forKey:colorCSSString];
    }

    return cachedColorVersion;
}

- (void)_setCSSColor:(CPString)aCSSColor
{
    [_cssAfterDictionary setObject:aCSSColor forKey:@"color"];
}

@end

// MARK: -

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

// MARK: -

@implementation CPImage (Duplication)

- (CPImage)duplicate
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:self]];
}

@end

// MARK: -

/*
    A system image keeps its name and resolves to an image each time it is used: the current
    theme's image for the drawing appearance, or the default image (see _CPSystemImageValue). So
    it follows a theme switch and the appearance in which a view draws. Each CPImage method
    forwards to the resolved image; the methods of CPImage subclasses forward through
    -forwardingTargetForSelector:. When there is no image, a system image is an empty, loaded
    image of size zero.
*/
@implementation _CPSystemImage : CPImage
{
    CPString    _systemImageName;
    CGSize      _sizeOverride;
    CPImage     _observedImage;
}

- (id)_initWithSystemImageName:(CPString)aName
{
    self = [super initByReferencingFile:@"" size:CGSizeMakeZero()];

    if (self)
        _systemImageName = aName;

    return self;
}

- (CPImage)_resolvedImage
{
    return _CPSystemImageValue(_systemImageName, [CPAppearance currentDrawingAppearance]);
}

// MARK: Name

- (CPString)name
{
    return _systemImageName;
}

/*
    The name of a system image is fixed.
*/
- (BOOL)setName:(CPString)aName
{
    return aName === _systemImageName;
}

// MARK: Forwarding

- (CPString)filename
{
    var resolvedImage = [self _resolvedImage];

    return resolvedImage ? [resolvedImage filename] : @"";
}

- (CPData)data
{
    return [[self _resolvedImage] data];
}

/*
    A size set with -setSize: replaces the size of the resolved image, as for any shared named
    image.
*/
- (void)setSize:(CGSize)aSize
{
    _sizeOverride = CGSizeMakeCopy(aSize);
}

- (CGSize)size
{
    if (_sizeOverride)
        return CGSizeMakeCopy(_sizeOverride);

    var resolvedImage = [self _resolvedImage];

    return resolvedImage ? [resolvedImage size] : CGSizeMakeZero();
}

- (Image)image
{
    return [[self _resolvedImage] image];
}

- (unsigned)loadStatus
{
    var resolvedImage = [self _resolvedImage];

    if (!resolvedImage)
        return CPImageLoadStatusCompleted;

    [self _observeImage:resolvedImage];

    return [resolvedImage loadStatus];
}

- (void)load
{
    var resolvedImage = [self _resolvedImage];

    [self _observeImage:resolvedImage];
    [resolvedImage load];
}

- (BOOL)isSingleImage
{
    var resolvedImage = [self _resolvedImage];

    return resolvedImage ? [resolvedImage isSingleImage] : YES;
}

- (BOOL)isThreePartImage
{
    return !![[self _resolvedImage] isThreePartImage];
}

- (BOOL)isNinePartImage
{
    return !![[self _resolvedImage] isNinePartImage];
}

- (BOOL)isMaterialIconImage
{
    return !![[self _resolvedImage] isMaterialIconImage];
}

- (BOOL)isCSSBased
{
    return !![[self _resolvedImage] isCSSBased];
}

- (BOOL)hasCSSDictionary
{
    return !![[self _resolvedImage] hasCSSDictionary];
}

- (BOOL)hasCSSBeforeDictionary
{
    return !![[self _resolvedImage] hasCSSBeforeDictionary];
}

- (BOOL)hasCSSAfterDictionary
{
    return !![[self _resolvedImage] hasCSSAfterDictionary];
}

- (CPDictionary)cssDictionary
{
    return [[self _resolvedImage] cssDictionary];
}

- (CPDictionary)cssBeforeDictionary
{
    return [[self _resolvedImage] cssBeforeDictionary];
}

- (CPDictionary)cssAfterDictionary
{
    return [[self _resolvedImage] cssAfterDictionary];
}

- (DOMElement)applyCSSImageForView:(CPView)aView onDOMElement:(DOMElement)aDOMElement styleNode:(DOMElement)aStyleNode previousState:(CPArrayRef)aPreviousStateRef
{
    return [[self _resolvedImage] applyCSSImageForView:aView onDOMElement:aDOMElement styleNode:aStyleNode previousState:aPreviousStateRef];
}

- (BOOL)_shouldBeResized
{
    return !![[self _resolvedImage] _shouldBeResized];
}

- (void)drawAtPoint:(CGPoint)point fromRect:(CPRect)fromRect operation:(CGBlendMode)op fraction:(float)delta
{
    [[self _resolvedImage] drawAtPoint:point fromRect:fromRect operation:op fraction:delta];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [[self _resolvedImage] respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    var resolvedImage = [self _resolvedImage];

    return [resolvedImage respondsToSelector:aSelector] ? resolvedImage : [super forwardingTargetForSelector:aSelector];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"System image %@: %@", _systemImageName, [[self _resolvedImage] description]];
}

// MARK: Loading

/*
    A view that finds the image not yet loaded waits for CPImageDidLoadNotification from the
    system image, so the system image posts it when the resolved image loads.
*/
- (void)_observeImage:(CPImage)anImage
{
    if (!anImage || anImage === _observedImage || [anImage loadStatus] === CPImageLoadStatusCompleted)
        return;

    var center = [CPNotificationCenter defaultCenter];

    if (_observedImage)
        [center removeObserver:self name:CPImageDidLoadNotification object:_observedImage];

    _observedImage = anImage;

    [center addObserver:self selector:@selector(_observedImageDidLoad:) name:CPImageDidLoadNotification object:anImage];
}

- (void)_observedImageDidLoad:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPImageDidLoadNotification object:_observedImage];

    _observedImage = nil;

    [self _imageDidLoad];
}

// MARK: Coding

- (Class)classForKeyedArchiver
{
    return [CPImage class];
}

/*
    A system image is archived by its name, so that it decodes to the shared system image.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_systemImageName forKey:CPImageSystemImageNameKey];
}

@end
