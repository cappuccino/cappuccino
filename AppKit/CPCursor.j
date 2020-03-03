/*
Cursor support by browser:
    OS X 10.6/Chrome 8       : All
    OS X 10.6/Safari 5       : All
    OS X 10.6/Firefox 3      : All except disappearingItemCursor (no url() support)
    OS X 10.6/Firefox 3.5    : All except disappearingItemCursor (no url() support)
    OS X 10.6/Firefox 3.6    : All except disappearingItemCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    OS X 10.6/Firefox 4.0b10 : All
    OS X/Opera 9             : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor  (no url() support)
    OS X/Opera 10            : All except disappearingItemCursor, closedHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    OS X/Opera 11            : All except disappearingItemCursor, closedHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    Win XP/Chrome 8          : All
    Win XP/Safari 5          : All
    Win XP/Firefox 3         : All
    Win XP/Firefox 3.5       : All
    Win XP/Firefox 3.6       : All
    Win XP/Firefox 4.0b10    : All
    Win XP/Opera 10          : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor (no url() support)
    Win XP/Opera 11          : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor (no url() support)
    Win XP/IE 7              : All
    Win XP/IE 8              : All
*/

@import <Foundation/CPObject.j>
@import "CPImage.j"
@import "CPCompatibility.j"

@global CPApp
@global CPPlatformWindow

var currentCursor = nil,
    cursorStack = [],
    cursors = {},
    ieCursorMap = {};

@typedef CPCursorPlatform
CPCursorPlatformNone    = 0;
CPCursorPlatformMac     = 1;
CPCursorPlatformWindows = 2;
CPCursorPlatformBoth    = 3;

@implementation CPCursor : CPObject
{
    CPString _cssString @accessors(readonly);
    CPString _hotSpot @accessors(readonly, getter=hotSpot);
    CPImage  _image @accessors(readonly, getter=image);
    BOOL     _isSetOnMouseEntered @accessors(readwrite, getter=isSetOnMouseEntered, setter=setOnMouseEntered:);
    BOOL     _isSetOnMouseExited @accessors(readwrite, getter=isSetOnMouseExited, setter=setOnMouseExited:);
}

+ (void)initialize
{
    if (self !== CPCursor)
        return;

    // IE < 9 does not support some CSS cursors, we map them to supported ones
    ieCursorMap = {
        "ew-resize":   "e-resize",
        "ns-resize":   "n-resize",
        "nesw-resize": "ne-resize",
        "nwse-resize": "nw-resize"
    };
}

- (id)initWithCSSString:(CPString)aString
{
    if (self = [super init])
        _cssString = aString;

    return self;
}

/*!
    Init a cursor with the given image and hotspot.
    hotspot is supported in CSS3 (but not IE).
*/
- (id)initWithImage:(CPImage)image hotSpot:(CGPoint)hotSpot
{
    _hotSpot = hotSpot;
    _image = image;
    return [self initWithCSSString:"url(" + [_image filename] + ")" + hotSpot.x + " " + hotSpot.y + ", auto"];
}

/*!
    Init a cursor with the given image and hotspot. This is provided
    for compliance with Cocoa. Note that foregroundColor and backgroundColor are ignored
    (as they are in Cocoa). See http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSCursor_Class/Reference/Reference.html
*/
- (id)initWithImage:(CPImage)image foregroundColorHint:(CPColor)foregroundColor backgroundColorHint:(CPColor)backgroundColor hotSpot:(CGPoint)aHotSpot
{
    return [self initWithImage:image hotSpot:aHotSpot];
}

+ (void)hide
{
    [self _setCursorCSS:@"none"]; // Not supported in IE < 9
}

+ (void)unhide
{
    [self _setCursorCSS:[currentCursor _cssString]];
}

+ (void)setHiddenUntilMouseMoves:(BOOL)flag
{
    if (flag)
        [CPCursor hide];
    else
        [CPCursor unhide];
}

- (void)pop
{
    [CPCursor pop];
}

+ (void)pop
{
    if (cursorStack.length > 1)
    {
        cursorStack.pop();
        currentCursor = cursorStack[cursorStack.length - 1];
    }
}

- (void)push
{
    cursorStack.push(self);
    currentCursor = self;
}

- (void)set
{
    if (currentCursor === self)
        return;
    
    currentCursor = self;

#if PLATFORM(DOM)
    [[self class] _setCursorCSS:_cssString];
#endif
}

- (void)mouseEntered:(CPEvent)event
{
}

- (void)mouseExited:(CPEvent)event
{
}

+ (CPCursor)currentCursor
{
    return currentCursor;
}

+ (void)_setCursorCSS:(CPString)aString
{
#if PLATFORM(DOM)
    var platformWindows = [[CPPlatformWindow visiblePlatformWindows] allObjects];

    for (var i = 0, count = [platformWindows count]; i < count; i++)
        platformWindows[i]._DOMBodyElement.style.cursor = aString;
#endif
}

// Internal method that is used to return the system cursors.  Caches the system cursors for performance.
+ (CPCursor)_nativeSystemCursorWithName:(CPString)cursorName cssString:(CPString)aString
{
    var cursor = cursors[cursorName];

    if (typeof cursor === "undefined")
    {
        var cssString;

        // IE <= 8 does not support some cursors, map them to supported cursors
        var ieLessThan9 = CPBrowserIsEngine(CPInternetExplorerBrowserEngine) && !CPFeatureIsCompatible(CPHTMLCanvasFeature);

        if (ieLessThan9)
            cssString = ieCursorMap[aString] || aString;
        else
            cssString = aString;

        cursors[cursorName] = cursor = [[CPCursor alloc] initWithCSSString:cssString];
    }

    return cursor;
}

+ (CPCursor)_imageCursorWithName:(CPString)cursorName cssString:(CPString)aString
{
    var cursor = cursors[cursorName];

    if (typeof cursor === "undefined")
    {
        var themeResourcePath = [[[CPApp themeBlend] bundle] resourcePath],
            extension = CPBrowserIsOperatingSystem(CPWindowsOperatingSystem) ? @"cur" : @"png",
            cssString = [CPString stringWithFormat:@"url(%@cursors/%@.%@), %@", themeResourcePath, cursorName, extension, aString];

        cursors[cursorName] = cursor = [[CPCursor alloc] initWithCSSString:cssString];
    }

    return cursor;
}

+ (CPCursor)_tryUsingNativeSystemCursorWithName:(CPString)cursorName cssString:(CPString)cssName onPlatform:(CPCursorPlatform)shouldUseNativeCursorOn fallingBackWithImageAndCSSPointer:(CPString)aString
{
    var useNativeSystemCursor = (((shouldUseNativeCursorOn == CPCursorPlatformBoth) ||
                                  ((shouldUseNativeCursorOn == CPCursorPlatformMac) && CPBrowserIsOperatingSystem(CPMacOperatingSystem)) ||
                                  ((shouldUseNativeCursorOn == CPCursorPlatformWindows) && CPBrowserIsOperatingSystem(CPWindowsOperatingSystem)))
                                 && [CPCursor _nativeCursorExists:cssName]);

    if (useNativeSystemCursor)
        return [CPCursor _nativeSystemCursorWithName:cursorName cssString:cssName];
    else
        return [CPCursor _imageCursorWithName:cursorName cssString:aString];
}

+ (BOOL)_nativeCursorExists:(CPString)cursorCSSName
{
#if PLATFORM(DOM)

    // FIXME: Trick until FF/Win & Chrome/Win correctly implement context-menu cursor
    // They will answer that they implement it but they actually don't

    if ([cursorCSSName isEqualToString:@"context-menu"] && CPBrowserIsOperatingSystem(CPWindowsOperatingSystem) && !CPBrowserIsEngine(CPInternetExplorerBrowserEngine) && !CPBrowserIsEngine(CPEdgeBrowserEngine))
        return NO;

    // Normal usage : try to set the cursor and check if resulting cursor is the one we tried to set.
    // If yes, then the browser implements the cursor. If no (and usually we get "default"), then it doesn't.

    var platformWindows = [[CPPlatformWindow visiblePlatformWindows] allObjects],
        count = [platformWindows count];

    if (count > 0)
    {
        var currentPlatformCursor = platformWindows[0]._DOMBodyElement.style.cursor;
        platformWindows[0]._DOMBodyElement.style.cursor = cursorCSSName;
        var doesExist = (platformWindows[0]._DOMBodyElement.style.cursor == cursorCSSName);
        platformWindows[0]._DOMBodyElement.style.cursor = currentPlatformCursor;

        return doesExist;
    }
#endif

    return NO;
}

+ (CPCursor)arrowCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"default"];
}

+ (CPCursor)crosshairCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"crosshair"];
}

+ (CPCursor)IBeamCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"text"];
}

+ (CPCursor)pointingHandCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"pointer"];
}

+ (CPCursor)resizeNorthwestCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"nw-resize"];
}

+ (CPCursor)resizeNorthwestSoutheastCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"nwse-resize"];
}

+ (CPCursor)resizeNortheastCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"ne-resize"];
}

+ (CPCursor)resizeNortheastSouthwestCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"nesw-resize"];
}

+ (CPCursor)resizeSouthwestCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"sw-resize"];
}

+ (CPCursor)resizeSoutheastCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"se-resize"];
}

+ (CPCursor)resizeDownCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"s-resize"];
}

+ (CPCursor)resizeUpCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"n-resize"];
}

+ (CPCursor)resizeLeftCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"w-resize"];
}

+ (CPCursor)resizeRightCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"e-resize"];
}

+ (CPCursor)resizeLeftRightCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"col-resize"];
}

+ (CPCursor)resizeEastWestCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"ew-resize"];
}

+ (CPCursor)resizeUpDownCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"row-resize"];
}

+ (CPCursor)resizeNorthSouthCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"ns-resize"];
}

+ (CPCursor)operationNotAllowedCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"not-allowed"];
}

+ (CPCursor)dragCopyCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"copy"];
}

+ (CPCursor)dragLinkCursor
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"alias"];
}

+ (CPCursor)contextualMenuCursor
{
    return [CPCursor _tryUsingNativeSystemCursorWithName:CPStringFromSelector(_cmd)
                                               cssString:@"context-menu"
                                              onPlatform:CPCursorPlatformBoth
                       fallingBackWithImageAndCSSPointer:@"default"];
}

+ (CPCursor)openHandCursor
{
    return [CPCursor _tryUsingNativeSystemCursorWithName:CPStringFromSelector(_cmd)
                                               cssString:@"grab"
                                              onPlatform:CPCursorPlatformMac
                       fallingBackWithImageAndCSSPointer:@"default"];
}

+ (CPCursor)closedHandCursor
{
    return [CPCursor _tryUsingNativeSystemCursorWithName:CPStringFromSelector(_cmd)
                                               cssString:@"grabbing"
                                              onPlatform:CPCursorPlatformMac
                       fallingBackWithImageAndCSSPointer:@"default"];
}

+ (CPCursor)disappearingItemCursor
{
    return [CPCursor _imageCursorWithName:CPStringFromSelector(_cmd) cssString:@"default"];
}

+ (CPCursor)IBeamCursorForVerticalLayout
{
    return [CPCursor _nativeSystemCursorWithName:CPStringFromSelector(_cmd) cssString:@"vertical-text"];
}

@end

@implementation CPCursor(CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super init])
        _cssString = [coder decodeObjectForKey:@"CPCursorNameKey"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_cssString forKey:@"CPCursorNameKey"];
}

@end
