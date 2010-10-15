/*
Testing browsers:
    WebKit r50235 (Safari 4.0.3+)
    FireFox 3.5
    Opera 10.0.0

Implemented class methods:
    Webkit : All
    IE     : All
    FireFox Win : All
    FireFox Mac : All except closedHandCursor disappearingItemCursor // Firefox mac does not support url cursors
    Opera       : All except resizeLeftRightCursor resizeUpDownCursor operationNotAllowedCursor dragCopyCursor dragLinkCursor contextualMenuCursor openHandCursor closedHandCursor disappearingItemCursor // Opera does not support url cursors so these won't work with images
*/

#include "Platform/Platform.h"

@import <Foundation/CPObject.j>

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
    {
        cursorURLFormat = @"url(" + [[CPBundle bundleForClass:self] resourcePath] + @"/CPCursor/%@.cur)";

        if (CPBrowserIsEngine(CPGeckoBrowserEngine))
            cursorURLFormat += ", default";
    }

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
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:"s-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeUpCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"n-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeLeftCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"w-resize"]; // WebKit | FF | opera
}

+ (CPCursor)resizeRightCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

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
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"copy"]; // WebKit | FF
}

+ (CPCursor)dragLinkCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"alias"]; // WebKit | FF
}

+ (CPCursor)contextualMenuCursor
{
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)];

    return [CPCursor cursorWithCSSString:@"context-menu"]; // WebKit | FF Mac . Not impl FF Win.
}

+ (CPCursor)openHandCursor
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine))
        return [CPCursor cursorWithCSSString:@"-webkit-grab"];
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
        return [CPCursor cursorWithCSSString:@"-moz-grab"];
    else if (CPBrowserIsEngine(CPOperaBrowserEngine))
        return [CPCursor cursorWithCSSString:@"move"];

    return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)]; // WebKit only. move in FFMac|Opera
}

+ (CPCursor)closedHandCursor
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine))
        return [CPCursor cursorWithCSSString:@"-webkit-grabbing"];
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
        return [CPCursor cursorWithCSSString:@"-moz-grabbing"];

    return [CPCursor cursorWithImageNamed:CPStringFromSelector(_cmd)]; // WebKit || FF
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
    [self _setCursorCSS:[currentCursor _cssString]];
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

