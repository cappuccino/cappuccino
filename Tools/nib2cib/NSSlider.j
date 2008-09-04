
import <AppKit/CPSlider.j>

import "NSSlider.j"


@implementation CPSlider (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        _minValue = [aCoder decodeDoubleForKey:@"NSMinValue"];
        _maxValue = [aCoder decodeDoubleForKey:@"NSMaxValue"];
/*    _knobThickness=8.0;
    _numberOfTickMarks=[keyed decodeIntForKey:@"NSNumberOfTickMarks"];
    _tickMarkPosition=[keyed decodeIntForKey:@"NSTickMarkPosition"];
    _allowsTickMarkValuesOnly=[keyed decodeBoolForKey:@"NSAllowsTickMarkValuesOnly"];*/
    }
    
    return self;
}

@end

@implementation NSSlider : CPSlider
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSlider class];
}

@end

@implementation NSSliderCell : NSCell
{
}
@end
