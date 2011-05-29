/*
 * NSLevelIndicator.j
 * nib2cib
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

@import <AppKit/CPLevelIndicator.j>

@implementation CPLevelIndicator (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var cell = [aCoder decodeObjectForKey:@"NSCell"];

    _minValue = [cell minValue];
    _maxValue = [cell maxValue];

    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _levelIndicatorStyle = [cell levelIndicatorStyle];
        _warningValue = [cell warningValue];
        _criticalValue = [cell criticalValue];
        _tickMarkPosition = [cell tickMarkPosition];
        _numberOfTickMarks = [cell numberOfTickMarks];
        _numberOfMajorTickMarks = [cell numberOfMajorTickMarks];

        [self setEditable:[cell isEditable]];
    }

    return self;
}

@end

@implementation NSLevelIndicator : CPLevelIndicator
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPLevelIndicator class];
}

@end

@implementation NSLevelIndicatorCell : NSCell
{
    CPLevelIndicator    _levelIndicatorStyle    @accessors(readonly, getter=levelIndicatorStyle);
    double              _minValue               @accessors(readonly, getter=minValue);
    double              _maxValue               @accessors(readonly, getter=maxValue);
    double              _warningValue           @accessors(readonly, getter=warningValue);
    double              _criticalValue          @accessors(readonly, getter=criticalValue);
    CPTickMarkPosition  _tickMarkPosition       @accessors(readonly, getter=tickMarkPosition);
    int                 _numberOfTickMarks      @accessors(readonly, getter=numberOfTickMarks);
    int                 _numberOfMajorTickMarks @accessors(readonly, getter=numberOfMajorTickMarks);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _objectValue        = [aCoder decodeDoubleForKey:@"NSValue"];

        _minValue           = [aCoder decodeDoubleForKey:@"NSMinValue"] || 0;
        _maxValue           = [aCoder decodeDoubleForKey:@"NSMaxValue"];
        _warningValue       = [aCoder decodeDoubleForKey:@"NSWarningValue"];
        _criticalValue      = [aCoder decodeDoubleForKey:@"NSCriticalValue"];

        _levelIndicatorStyle = [aCoder decodeIntForKey:@"NSIndicatorStyle"] || 0;

        // None of these are included in the XIB if the defaults are used.
        _tickMarkPosition   = [aCoder decodeIntForKey:@"NSTickMarkPosition"] || 0;
        _numberOfTickMarks  = [aCoder decodeIntForKey:@"NSNumberOfTickMarks"] || 0;
        _numberOfTickMarks  = [aCoder decodeIntForKey:@"NSNumberOfMajorTickMarks"] || 0;
    }

    return self;
}

@end
