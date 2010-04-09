
@import <Foundation/CPObject.j>

#import "CoreGraphics/CGGeometry.h"
#import "Platform/Platform.h"

@implementation CPScreen : CPObject
{
}

- (CGRect)visibleFrame
{
#if PLATFORM(DOM)
    return _CGRectMake(window.screen.availLeft, window.screen.availTop, window.screen.availWidth, window.screen.availHeight);
#else
    return _CGRectMakeZero();
#endif
}

@end