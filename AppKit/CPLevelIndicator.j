/*
 * CPLevelIndicator.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPControl.j"

CPTickMarkBelow                             = 0;
CPTickMarkAbove                             = 1;
CPTickMarkLeft                              = CPTickMarkAbove;
CPTickMarkRight                             = CPTickMarkBelow;

CPRelevancyLevelIndicatorStyle              = 0;
CPContinuousCapacityLevelIndicatorStyle     = 1;
CPDiscreteCapacityLevelIndicatorStyle       = 2;
CPRatingLevelIndicatorStyle                 = 3;

/*!
    @ingroup appkit
    @class CPLevelIndicator

    CPLevelIndicator is a control which indicates a value visually on a scale.
*/
@implementation CPLevelIndicator : CPControl
{
    CPLevelIndicator    _levelIndicatorStyle @accessors;
    double              _minValue @accessors;
    double              _maxValue @accessors;
    double              _warningValue @accessors;
    double              _criticalValue @accessors;
    CPTickMarkPosition  _tickMarkPosition @accessors;
    int                 _numberOfTickMarks @accessors;
    int                 _numberOfMajorTickMarks @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _levelIndicatorStyle = CPDiscreteCapacityLevelIndicatorStyle;
        _maxValue = 2;
        _warningValue = 2;
        _criticalValue = 2;
    }

    return self;
}

/*
- (CPLevelIndicatorStyle)style;
- (void)setLevelIndicatorStyle:(CPLevelIndicatorStyle)style;

- (double)minValue;
- (void)setMinValue:(double)minValue;

- (double)maxValue;
- (void)setMaxValue:(double)maxValue;

- (double)warningValue;
- (void)setWarningValue:(double)warningValue;

- (double)criticalValue;
- (void)setCriticalValue:(double)criticalValue;

- (CPTickMarkPosition)tickMarkPosition;
- (void)setTickMarkPosition:(CPTickMarkPosition)position;

- (int)numberOfTickMarks;
- (void)setNumberOfTickMarks:(int)count;

- (int)numberOfMajorTickMarks;
- (void)setNumberOfMajorTickMarks:(int)count;

- (double)tickMarkValueAtIndex:(int)index;
- (CGRect)rectOfTickMarkAtIndex:(int)index;
*/

@end

var CPLevelIndicatorStyleKey                    = "CPLevelIndicatorStyleKey",
    CPLevelIndicatorMinValueKey                 = "CPLevelIndicatorMinValueKey",
    CPLevelIndicatorMaxValueKey                 = "CPLevelIndicatorMaxValueKey",
    CPLevelIndicatorWarningValueKey             = "CPLevelIndicatorWarningValueKey",
    CPLevelIndicatorCriticalValueKey            = "CPLevelIndicatorCriticalValueKey",
    CPLevelIndicatorTickMarkPositionKey         = "CPLevelIndicatorTickMarkPositionKey",
    CPLevelIndicatorNumberOfTickMarksKey        = "CPLevelIndicatorNumberOfTickMarksKey",
    CPLevelIndicatorNumberOfMajorTickMarksKey   = "CPLevelIndicatorNumberOfMajorTickMarksKey";

@implementation CPLevelIndicator (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _levelIndicatorStyle = [aCoder decodeIntForKey:CPLevelIndicatorStyleKey];
        _minValue = [aCoder decodeDoubleForKey:CPLevelIndicatorMinValueKey];
        _maxValue = [aCoder decodeDoubleForKey:CPLevelIndicatorMaxValueKey];
        _warningValue = [aCoder decodeDoubleForKey:CPLevelIndicatorWarningValueKey];
        _criticalValue = [aCoder decodeDoubleForKey:CPLevelIndicatorCriticalValueKey];
        _tickMarkPosition = [aCoder decodeIntForKey:CPLevelIndicatorTickMarkPositionKey];
        _numberOfTickMarks = [aCoder decodeIntForKey:CPLevelIndicatorNumberOfTickMarksKey];
        _numberOfMajorTickMarks = [aCoder decodeIntForKey:CPLevelIndicatorNumberOfMajorTickMarksKey];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_levelIndicatorStyle forKey:CPLevelIndicatorStyleKey];
    [aCoder encodeDouble:_minValue forKey:CPLevelIndicatorMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPLevelIndicatorMaxValueKey];
    [aCoder encodeDouble:_warningValue forKey:CPLevelIndicatorWarningValueKey];
    [aCoder encodeDouble:_criticalValue forKey:CPLevelIndicatorCriticalValueKey];
    [aCoder encodeInt:_tickMarkPosition forKey:CPLevelIndicatorTickMarkPositionKey];
    [aCoder encodeInt:_numberOfTickMarks forKey:CPLevelIndicatorNumberOfTickMarksKey];
    [aCoder encodeInt:_numberOfMajorTickMarks forKey:CPLevelIndicatorNumberOfMajorTickMarksKey];
}

@end
