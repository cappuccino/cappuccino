@import <Foundation/CPObject.j>

@import "CAPropertyAnimation.j"

@implementation CAKeyframeAnimation : CAPropertyAnimation
{
    CPArray _values   @accessors(property=values);
    CPArray _keyTimes @accessors(property=keyTimes);
    CPArray _timingFunctions @accessors(property=timingFunctions);
}

- (id)init
{
    self = [super init];

    _values = [CPArray array];
    _keyTimes = [CPArray array];
    _timingFunctions = [CPArray array];

    return self;
}

@end