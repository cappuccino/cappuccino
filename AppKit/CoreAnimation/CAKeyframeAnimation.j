@import <Foundation/CPObject.j>
@import "CAPropertyAnimation.j"

// Value calculation modes
kCAAnimationLinear = @"linear";
kCAAnimationDiscrete = @"discrete";
kCAAnimationPaced = @"paced";
kCAAnimationCubic = @"cubic";
kCAAnimationCubicPaced = @"cubicPaced";

// Rotation Mode Values
kCAAnimationRotateAuto = @"auto";
kCAAnimationRotateAutoReverse = @"autoReverse";

@implementation CAKeyframeAnimation : CAPropertyAnimation
{
    CPArray _values   @accessors(property=values);
    CPArray _keyTimes @accessors(property=keyTimes);
    CPArray _timingFunctions @accessors(property=timingFunctions);
    id _path @accessors(property=path);
    CPString _calculationMode @accessors(property=calculationMode);
    CPString _rotationMode @accessors(property=rotationMode);
    CPArray _tensionValues @accessors(property=tensionValues);
    CPArray _continuityValues @accessors(property=continuityValues);
    CPArray _biasValues @accessors(property=biasValues);
}

- (id)init
{
    self = [super init];

    _values = [CPArray array];
    _keyTimes = [CPArray array];
    _timingFunctions = [CPArray array];
    _tensionValues = [CPArray array];
    _continuityValues = [CPArray array];
    _biasValues = [CPArray array];

    return self;
}

@end
