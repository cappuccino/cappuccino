
@import <Foundation/CPObject.j>


#import "CoreGraphics/CGGeometry.h"

@implementation CPScreen : CPObject
{
}

- (CGRect)visibleFrame
{
    return _CGRectMake(window.screen.availLeft, window.screen.availTop, window.screen.availWidth, window.screen.availHeight);
}

@end