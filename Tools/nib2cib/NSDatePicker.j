/*
 * NSDatePicker.j
 * nib2cib
 *
 * Created by Alexendre Wilhelm.
 * Copyright 2013 The Cappuccino Foundation.
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

@import <AppKit/CPDatePicker.j>
@import <Foundation/CPDate.j>

@import "NSCell.j"

@class Nib2Cib

@global CPTextFieldDatePickerStyle
@global CPTextFieldAndStepperDatePickerStyle
@global CPClockAndCalendarDatePickerStyle
@global CPHourMinuteSecondDatePickerElementFlag
@global CPHourMinuteDatePickerElementFlag
@global IBDefaultFontFace
@global IBDefaultFontSize

var NSDatePickerDefaultSize = 22,
    NSDatePickerCalendarDefaultSize = 148;

@implementation CPDatePicker (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    var cell = [aCoder decodeObjectForKey:@"NSCell"];
    _minDate = [cell minDate];
    _maxDate = [cell maxDate];
    _timeInterval = [cell timeInterval];
    _datePickerMode = [cell datePickerMode];
    _datePickerElements = [cell datePickerElements];
    _datePickerStyle = [cell datePickerType];
    _dateValue = [cell objectValue];
    _backgroundColor = [cell backgroundColor];
    _drawsBackground = [cell drawsBackground];
    _formatter = [cell formatter];

    [self setBezeled:[cell isBezeled]];
    [self setBordered:[cell isBordered]];

    var theme = [Nib2Cib defaultTheme];

    if (_datePickerStyle != CPClockAndCalendarDatePickerStyle)
    {
        var minSize = [theme valueForAttributeWithName:@"min-size" forClass:[self class]],
            maxSize = [theme valueForAttributeWithName:@"max-size" forClass:[self class]];

        if (minSize.height > 0)
        {
            _frame.size.height = MAX(_frame.size.height, minSize.height);
            _bounds.size.height = MAX(_frame.size.height, minSize.height);
        }

        if (maxSize.height > 0)
        {
            _frame.size.height = MIN(_frame.size.height, maxSize.height);
            _bounds.size.height = MIN(_frame.size.height, maxSize.height);
        }

        if (minSize.width > 0)
        {
            _frame.size.width = MAX(_frame.size.width, minSize.width);
            _bounds.size.width = MAX(_frame.size.width, minSize.width);
        }

        if (maxSize.width > 0)
        {
            _frame.size.width = MIN(_frame.size.width, maxSize.width);
            _bounds.size.width = MAX(_frame.size.width, minSize.width);
        }

        if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle)
        {
            _frame.size.width -= 3;
            _bounds.size.width -= 3;
        }

        _frame.origin.y -= _frame.size.height - NSDatePickerDefaultSize - 4;
    }
    else
    {
        var minSize = [theme valueForAttributeWithName:@"min-size-calendar" forClass:[self class]],
            maxSize = [theme valueForAttributeWithName:@"max-size-calendar" forClass:[self class]],
            sizeClock = [theme valueForAttributeWithName:@"size-clock" forClass:[self class]];

        if (_datePickerElements & CPHourMinuteSecondDatePickerElementFlag || _datePickerElements & CPHourMinuteDatePickerElementFlag)
        {
            minSize.width += sizeClock.width + 10;
            maxSize.width += sizeClock.width + 10;
        }

        if (minSize.height > 0)
        {
            _frame.size.height = MAX(_frame.size.height, minSize.height);
            _bounds.size.height = MAX(_frame.size.height, minSize.height);
        }

        if (maxSize.height > 0)
        {
            _frame.size.height = MIN(_frame.size.height, maxSize.height);
            _bounds.size.height = MIN(_frame.size.height, maxSize.height);
        }

        if (minSize.width > 0)
        {
            _frame.size.width = MAX(_frame.size.width, minSize.width);
            _bounds.size.width = MAX(_frame.size.width, minSize.width);
        }

        if (maxSize.width > 0)
        {
            _frame.size.width = MIN(_frame.size.width, maxSize.width);
            _bounds.size.width = MAX(_frame.size.width, minSize.width);
        }

        _frame.origin.y -= _frame.size.height - NSDatePickerCalendarDefaultSize - 1;
    }

    if ([cell font]._name === IBDefaultFontFace && [[cell font] size] == IBDefaultFontSize)
        [self setTextFont:[theme valueForAttributeWithName:@"font" forClass:[self class]]];
    else
        [self setTextFont:[cell font]];


    var textColor = [cell textColor],
        defaultColor = [self currentValueForThemeAttribute:@"text-color"];

    // Don't change the text color if it is not the default, that messes up the theme lookups later
    if (![textColor isEqual:defaultColor])
        [self setTextColor:[cell textColor]];

    return self;
}

@end

@implementation NSDatePicker : CPDatePicker
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPDatePicker class];
}

@end


@implementation NSDatePickerCell : NSCell
{
    BOOL            _drawsBackground    @accessors(getter=drawsBackground);
    CPDate          _minDate            @accessors(getter=minDate);
    CPDate          _maxDate            @accessors(getter=maxDate);
    CPDateFormatter _formatter          @accessors(getter=formatter);
    CPInteger       _datePickerMode     @accessors(getter=datePickerMode);
    CPInteger       _datePickerElements @accessors(getter=datePickerElements);
    CPinteger       _datePickerType     @accessors(getter=datePickerType);
    double          _timeInterval       @accessors(getter=timeInterval);
    CPColor         _textColor          @accessors(getter=textColor);
    CPColor         _backgroundColor    @accessors(getter=backgroundColor);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        var flags = [aCoder decodeIntForKey:@"NSCellFlags"],
            pickerType = [aCoder decodeIntForKey:@"NSDatePickerType"] || 0;

        if ([aCoder decodeIntForKey:@"NSSuppressStepper"] && pickerType != 1)
            pickerType = 2;

        _timeInterval = [aCoder decodeDoubleForKey:@"NSTimeInterval"] || 0;
        _datePickerMode = [aCoder decodeIntForKey:@"NSDatePickerMode"] || 0;
        _datePickerElements = [aCoder decodeIntForKey:@"NSDatePickerElements"] || 0;
        _datePickerType = pickerType;
        _minDate = [aCoder decodeObjectForKey:@"NSMinDate"] || [CPDate distantPast];
        _maxDate = [aCoder decodeObjectForKey:@"NSMaxDate"]|| [CPDate distantFuture];;
        _textColor = [aCoder decodeObjectForKey:@"NSTextColor"];
        _backgroundColor = [aCoder decodeObjectForKey:@"NSBackgroundColor"];
        _isBordered = _isBezeled;

        if ([aCoder containsValueForKey:@"NSFormatter"])
            _formatter = [aCoder decodeObjectForKey:@"NSFormatter"];

        if ([aCoder containsValueForKey:@"NSDrawsBackground"])
            _drawsBackground = [aCoder decodeBoolForKey:@"NSDrawsBackground"];
        else
            _drawsBackground = YES;
    }

    return self;
}

@end

@implementation NSCalendarDate : CPDate
{
}

- (Class)classForKeyedArchiver
{
    return [CPDate class];
}

@end
