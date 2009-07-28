
@import <Foundation/CPObject.j>

#import "Platform.h"
#import "../CoreGraphics/CGGeometry.h"


var PrimaryPlatformWindow   = NULL;

@implementation CPPlatformWindow : CPObject
{
    CGRect  _contentRect;

#if PLATFORM(DOM)
    DOMWindow       _DOMWindow;

    DOMElement      _DOMBodyElement;
    DOMElement      _DOMFocusElement;

    CPArray         _windowLevels;
    CPDictionary    _windowLayers;

    BOOL            _mouseIsDown;
    CPWindow        _mouseDownWindow;
    CPTimeInterval  _lastMouseUp;
    CPTimeInterval  _lastMouseDown;

    Object          _charCodes;
    unsigned        _keyCode;

    BOOL            _DOMEventMode;

    // Native Pasteboard Support
    DOMElement      _DOMPasteboardElement;
    CPEvent         _pasteboardKeyDownEvent;

    CPString        _overriddenEventType;
#endif
}

+ (CPPlatformWindow)primaryPlatformWindow
{
    return PrimaryPlatformWindow;
}

+ (void)setPrimaryPlatformWindow:(CPPlatformWindow)aPlatformWindow
{
    PrimaryPlatformWindow = aPlatformWindow;
}

- (id)initWithContentRect:(CGRect)aRect
{
    self = [super init];

    if (self)
    {
        _contentRect = _CGRectMakeCopy(aRect);

#if PLATFORM(DOM)
        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];
        
        _charCodes = {};
#endif
    }

    return self;
}

- (id)init
{
    return [self initWithContentRect:_CGRectMake(0.0, 0.0, 400.0, 500.0)];
}

- (CGRect)contentRect
{
    return _CGRectMakeCopy(_contentRect);
}

- (CGRect)contentBounds
{
    var contentBounds = [self contentRect];

    contentBounds.origin = _CGPointMakeZero();

    return contentBounds;
}

- (void)usableContentFrame
{
    var frame = [self contentBounds];

    frame.origin = CGPointMakeZero();

    if ([CPMenu menuBarVisible])
    {
        var menuBarHeight = [[CPApp mainMenu] menuBarHeight];

        frame.origin.y += menuBarHeight;
        frame.size.height -= menuBarHeight;
    }

    return frame;
}

- (void)setContentRect:(CGRect)aRect
{
    if (!aRect || _CGRectEqualToRect(_contentRect, aRect))
        return;

    [self setContentOrigin:aRect.origin];
    [self setContentSize:aRect.size];
}

- (void)setContentOrigin:(CGPoint)aPoint
{
    var origin = _contentRect.origin;

    if (!aPoint || _CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    [self updateNativeContentOrigin];
}

- (void)setContentSize:(CGSize)aSize
{
    var size = _contentRect.size;

    if (!aSize || _CGSizeEqualToSize(size, aSize))
        return;

    var delta = _CGSizeMake(aSize.width - size.width, aSize.height - size.height);

    size.width = aSize.width;
    size.height = aSize.height;

    [self updateNativeContentSize];
}

- (void)updateFromNativeContentRect
{
    [self setContentRect:[self nativeContentRect]];
}
/*
- (BOOL)isVisible
{
    return NO;
}

/*
+ (BOOL)supportsMultipleWindows
{
#if PLATFORM(BROWSER)
    return YES;
#else
    return NO;
#endif
}
*/

- (BOOL)supportsFullPlatformWindows
{
#if PLATFORM(BROWSER)
    return YES;
#else
    return NO;
#endif
}

@end

#if PLATFORM(BROWSER)
@import "CPPlatformWindow+DOM.j"
#endif
