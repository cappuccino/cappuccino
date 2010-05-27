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
    return [[CPCursor alloc] initWithCSSString:[CPCursor _cssStringForCursorWithImageNamed:imageName]];
}

- (CPString)_cssString
{
    return _cssString;
}

+ (CPString)_cssStringForCursorWithImageNamed:(CPString)imageName
{
    if (!cursorURLFormat)
        cursorURLFormat = @"url(" + [[CPBundle bundleForClass:self] resourcePath] + @"CPCursor/%@.cur), auto";
    
    return [CPString stringWithFormat:cursorURLFormat, imageName];
}

+ (CPCursor)_cursorWithCSSString:(CPString)aString fallbackImageName:(CPString)imageName
{
    if (!imageName)
        return [CPCursor cursorWithCSSString:aString];
    return [CPCursor cursorWithCSSString:aString + ", " + [CPCursor _cssStringForCursorWithImageNamed:imageName]];
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
//    console.log([CPCursor _cursorWithCSSString:"s-resize" fallbackImageName:CPStringFromSelector(_cmd)]);
    return [CPCursor cursorWithCSSString:"s-resize, url()"]// fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF | opera | IE
}

+ (CPCursor)resizeUpCursor
{
    return [CPCursor _cursorWithCSSString:@"n-resize" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF | opera | IE
}

+ (CPCursor)resizeLeftCursor
{
    return [CPCursor _cursorWithCSSString:@"w-resize" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF | opera | IE
}

+ (CPCursor)resizeRightCursor
{
    return [CPCursor _cursorWithCSSString:@"e-resize" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF | opera | IE
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
    return [CPCursor _cursorWithCSSString:@"copy" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF
}

+ (CPCursor)dragLinkCursor
{
    return [CPCursor _cursorWithCSSString:@"alias" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF
}

+ (CPCursor)contextualMenuCursor
{
    return [CPCursor _cursorWithCSSString:@"context-menu" fallbackImageName:CPStringFromSelector(_cmd)]; // WebKit | FF Mac . Not impl FF Win.
}

+ (CPCursor)openHandCursor
{
    return [CPCursor _cursorWithCSSString:@"-webkit-grab, -moz-grab" fallbackImageName:CPStringFromSelector(_cmd)];
}

+ (CPCursor)closedHandCursor
{
    return [CPCursor _cursorWithCSSString:@"-webkit-grabbing, -moz-grabbing" fallbackImageName:CPStringFromSelector(_cmd)];
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
    return [self initWithCSSString:"url(" + [image filename] + "), default"];
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

