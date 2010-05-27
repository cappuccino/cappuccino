/*
Testing browsers:
    Safari 4.0.5, Windows and Mac
    Chrome 5.0375.55 Windows and Mac
    FireFox 3, 3.6 Windows and Mac
    Opera 9.64 Mac
    Opera 10.53 Windows and Mac
    Internet Explorer 7, 8 Windows

Implemented class methods:
    Webkit       : All
    IE 7, 8      : All
    Opera 10.53  : All except operationNotAllowedCursor dragCopyCursor dragLinkCursor contextualMenuCursor closedHandCursor disappearingItemCursor, additionally, in Windows: resizeLeftRightCursor resizeUpDownCursor openHandCursor // Opera does not support url cursors so these won't work with images
    Opera 9.64   : All except operationNotAllowedCursor dragCopyCursor dragLinkCursor contextualMenuCursor closedHandCursor disappearingItemCursor // Opera does not support url cursors so these won't work with images
    Firefox 3    : All on Windows, All except disappearingItemCursor on Mac
    Firefox 3.6  : All on Windows, All except operationNotAllowedCursor dragCopyCursor dragLinkCursor contextualMenuCursor on Mac
*/

#include "Platform/Platform.h"

var currentCursor = nil,
    cursorStack = [],
    cursors = {},
    cursorURLFormat = nil;

@implementation CPCursor : CPObject
{
    CPString _cssString;
    BOOL     _isSetOnMouseEntered @accessors(readwrite, getter=isSetOnMouseEntered, setter=setOnMouseEntered:);
    BOOL     _isSetOnMouseExited @accessors(readwrite, getter=isSetOnMouseExited, setter=setOnMouseExited:);
}

+ (CPCursor)currentCursor
{
    return currentCursor;
}

- (id)initWithCSSString:(CPString)aString
{
    if (self = [super init])
        _cssString = aString;

    return self;
}

+ (CPCursor)cursorWithCSSString:(CPString)cssString
{
    var cursor = cursors[cssString];

    if (typeof cursor == 'undefined')
    {
        cursor = [[CPCursor alloc] initWithCSSString:cssString];
        cursors[cssString] = cursor;
    }

    return cursor;
}

+ (CPCursor)cursorWithImageNamed:(CPString)imageName
{
    if (!cursorURLFormat)
        cursorURLFormat = @"url(" + [[CPBundle bundleForClass:self] resourcePath] + @"/CPCursor/%@.cur), default";
    
    var url = [CPString stringWithFormat:cursorURLFormat, imageName];
    
    return [[CPCursor alloc] initWithCSSString:url];
}

- (CPString)_cssString
{
    return _cssString;
}

+ (CPCursor)arrowCursor
{
    return [CPCursor cursorWithCSSString:@"default"]; // WebKit | FF | opera | IE
}

+ (CPCursor)crosshairCursor
{
    return [CPCursor cursorWithCSSString:@"crosshair"]; // WebKit | FF | opera | IE
}

+ (CPCursor)IBeamCursor
{
    return [CPCursor cursorWithCSSString:@"text"]; // WebKit | FF | opera | IE
}

+ (CPCursor)pointingHandCursor
{
    return [CPCursor cursorWithCSSString:@"pointer"]; // WebKit | FF | opera | IE
}

+ (CPCursor)resizeDownCursor
{
    return [CPCursor cursorWithCSSString:"s-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeUpCursor
{
    return [CPCursor cursorWithCSSString:@"n-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeLeftCursor
{
    return [CPCursor cursorWithCSSString:@"w-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeRightCursor
{
    return [CPCursor cursorWithCSSString:@"e-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeLeftRightCursor
{
    return [CPCursor cursorWithCSSString:@"col-resize"]; // WebKit | FF | IE
}

+ (CPCursor)resizeUpDownCursor
{
    return [CPCursor cursorWithCSSString:@"row-resize"]; // WebKit | FF | IE
}

+ (CPCursor)operationNotAllowedCursor
{
    return [CPCursor cursorWithCSSString:@"not-allowed"]; // WebKit | FF | IE
}

+ (CPCursor)dragCopyCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine) ||
        CPBrowserIsUserAgent("Safari") && CPBrowserIsOperatingSystem(CPWindowsOperatingSystem))        
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"copy"]; // WebKit | FF
}

+ (CPCursor)dragLinkCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine) ||
        CPBrowserIsUserAgent("Safari") && CPBrowserIsOperatingSystem(CPWindowsOperatingSystem))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"alias"]; // WebKit | FF
}

+ (CPCursor)contextualMenuCursor
{
    if (CPBrowserIsOperatingSystem(CPWindowsOperatingSystem))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"context-menu"]; // WebKit | FF Mac . Not impl FF Win.
}

+ (CPCursor)openHandCursor
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine) && !CPBrowserIsUserAgent("Chrome") && !CPBrowserIsOperatingSystem(CPWindowsOperatingSystem))
        return [CPCursor cursorWithCSSString:@"-webkit-grab"];
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine)) 
        return [CPCursor cursorWithCSSString:@"-moz-grab"];
    else if (CPBrowserIsEngine(CPOperaBrowserEngine))
        return [CPCursor cursorWithCSSString:@"move"];

    return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)]; // WebKit | FFMac.  Move in Opera 
}

+ (CPCursor)closedHandCursor
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine) && !CPBrowserIsUserAgent("Chrome") && !CPBrowserIsOperatingSystem(CPWindowsOperatingSystem))
        return [CPCursor cursorWithCSSString:@"-webkit-grabbing"];
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
        return [CPCursor cursorWithCSSString:@"-moz-grabbing"];        

    return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)]; // WebKit | FFMac
}

+ (CPCursor)disappearingItemCursor
{
    return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)]; // None
}

+ (void)hide
{
    [self _setCursorCSS:"none"]; // Not supported in IE
}

+ (void)unhide
{
    [self _setCursorCSS:[currentCursor _cssString]]
}

+ (void)setHiddenUntilMouseMoves:(BOOL)flag
{
    if (flag)
        [CPCursor hide];
    else
        [CPCursor unhide];
}

- (id)initWithImage:(CPImage)image hotSpot:(CPPoint)hotSpot
{
    return [self initWithCSSString:"url(" + [image filename] + ")"];
}

- (void)mouseEntered:(CPEvent)event
{
}

- (void)mouseExited:(CPEvent)event
{
}

- (void)set
{
    currentCursor = self; 

#if PLATFORM(DOM)
    [[self class] _setCursorCSS:_cssString];
#endif

}

+ (void)_setCursorCSS:(CPString)aString
{
#if PLATFORM(DOM)
    var platformWindows = [[CPPlatformWindow visiblePlatformWindows] allObjects];
    for (var i = 0, count = [platformWindows count]; i < count; i++)
        platformWindows[i]._DOMBodyElement.style.cursor = aString;
#endif
}

- (void)push
{
    currentCursor = cursorStack.push(self);
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

