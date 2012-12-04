
@import <Foundation/CPObject.j>

@import "CAAnimation.j"

@implementation CAPropertyAnimation : CAAnimation
{
    CPString    _keyPath;

    BOOL        _isCumulative;
    BOOL        _isAdditive;
}

- (id)init
{
    self = [super init];

    _keyPath = nil;
    _isCumulative = NO;
    _isAdditive = NO;

    return self;
}

+ (id)animationWithKeyPath:(CPString)aKeyPath
{
    var animation = [self animation];

    [animation setKeyPath:aKeyPath];

    return animation;
}

- (void)setKeyPath:(CPString)aKeyPath
{
    _keyPath = aKeyPath;
}

- (CPString)keyPath
{
    return _keyPath;
}

- (void)setCumulative:(BOOL)isCumulative
{
    _isCumulative = isCumulative;
}

- (BOOL)cumulative
{
    return _isCumulative;
}

- (BOOL)isCumulative
{
    return _isCumulative;
}

- (void)setAdditive:(BOOL)isAdditive
{
    _isAdditive = isAdditive;
}

- (BOOL)additive
{
    return _isAdditive;
}

- (BOOL)isAdditive
{
    return _isAdditive;
}

@end
