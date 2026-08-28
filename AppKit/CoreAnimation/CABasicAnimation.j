@import <Foundation/CPObject.j>

@import "CAPropertyAnimation.j"

/*!
    @ingroup appkit
    @class CABasicAnimation
    A CABasicAnimation provides basic single-keyframe interpolation for a layer property over a specified duration.
*/
@implementation CABasicAnimation : CAPropertyAnimation
{
    id  _fromValue;
    id  _toValue;
    id  _byValue;
}

/*!
    Initializes a newly allocated basic animation instance with default values.
    @return the initialized animation instance
*/
- (id)init
{
    self = [super init];

    _fromValue = nil;
    _toValue = nil;
    _byValue = nil;

    return self;
}

/*!
    Sets the starting value for the animated property.
    @param aValue the starting value
*/
- (void)setFromValue:(id)aValue
{
    _fromValue = aValue;
}

/*!
    Returns the starting value of the animated property.
    @return the starting value
*/
- (id)fromValue
{
    return _fromValue;
}

/*!
    Sets the ending value for the animated property.
    @param aValue the ending value
*/
- (void)setToValue:(id)aValue
{
    _toValue = aValue;
}

/*!
    Returns the ending value of the animated property.
    @return the ending value
*/
- (id)toValue
{
    return _toValue;
}

/*!
    Sets the relative value by which the property is modified during animation.
    @param aValue the relative change value
*/
- (void)setByValue:(id)aValue
{
    _byValue = aValue;
}

/*!
    Returns the relative value by which the property is modified during animation.
    @return the relative change value
*/
- (id)byValue
{
    return _byValue;
}

@end
