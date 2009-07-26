
@import <Foundation/CPObject.j>

#import "Platform.h"
#import "../CoreGraphics/CGGeometry.h"


var PlatformWindowClass = NULL;

@implementation CPPlatformWindow : CPObject
{
    CGRect  _contentRect;
}

+ (void)_setPlatformWindowClass:(Class)aClass
{
    PlatformWindowClass = aClass;
}

+ (Class)_platformWindowClass
{
    return PlatformWindowClass;
}

+ (id)alloc
{
    if (self === [CPPlatformWindow class])
        return [PlatformWindowClass alloc];

    return [super alloc];
}

- (id)initWithContentRect:(CGRect)aRect
{
    self = [super init];

    if (self)
        _contentRect = _CGRectMakeCopy(aRect);

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

@end

#if PLATFORM(BROWSER)
@import "_CPBrowserWindow.j"
#else
[CPPlatformWindow _setPlatformWindowClass:[CPPlatformWindow class]];
#endif
