@import <Foundation/CPObject.j>

@import "CAPropertyAnimation.j"

/*!
    A CABasicAnimation is a simple animation that moves a
    CALayer from one point to another over a specified
    period of time.
*/
/*!
    A CABasicAnimation is a simple animation that moves a
    CALayer from one point to another over a specified
    period of time.
*/
@implementation CABasicAnimation : CAPropertyAnimation
{
    id  _fromValue;
    id  _toValue;
    id  _byValue;
}

- (id)init
{
    self = [super init];

    _fromValue = nil;
    _toValue = nil;
    _byValue = nil;

    return self;
}

/*!
    Sets the starting position for the animation.
    @param aValue the animation starting position
*/
- (void)setFromValue:(id)aValue
{
    _fromValue = aValue;
}

/*!
    Returns the animation's starting position.
*/
- (id)fromValue
{
    return _fromValue;
}

/*!
    Sets the ending position for the animation.
    @param aValue the animation ending position
*/
- (void)setToValue:(id)aValue
{
    _toValue = aValue;
}

/*!
    Returns the animation's ending position.
*/
- (id)toValue
{
    return _toValue;
}

/*!
    Sets the optional byValue for animation interpolation.
    @param aValue the byValue
*/
- (void)setByValue:(id)aValue
{
    _byValue = aValue;
}

/*!
    Returns the animation's byValue.
*/
- (id)byValue
{
    return _byValue;
}

@end