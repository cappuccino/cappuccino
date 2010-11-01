
@import <Foundation/CPObject.j>


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