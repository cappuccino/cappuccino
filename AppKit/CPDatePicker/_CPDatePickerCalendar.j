/* _CPDatePickerCalendar.j
* AppKit
*
* Created by Alexandre Wilhelm
* Copyright 2012 <alexandre.wilhelmfr@gmail.com>
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

@import <Foundation/Foundation.j>

@import "_CPDatePickerClock.j"
@import "_CPDatePickerBox.j"
@import "_CPDatePickerMonthView.j"
@import "_CPDatePickerHeaderView.j"

@class CPDatePicker

@global CPApp
@global CPHourMinuteDatePickerElementFlag
@global CPHourMinuteSecondDatePickerElementFlag
@global CPTimeZoneDatePickerElementFlag
@global CPYearMonthDatePickerElementFlag
@global CPYearMonthDayDatePickerElementFlag
@global CPEraDatePickerElementFlag

@implementation _CPDatePickerCalendar : CPControl
{
    _CPDatePickerMonthView          _monthView;
    _CPDatePickerHeaderView         _headerView;
    _CPDatePickerClock              _datePickerClock;
    _CPDatePickerBox                _box;
    CPDatePicker                    _datePicker;
    CPInteger                       _startSelectionIndex;
    CPInteger                       _currentSelectionIndex;
    BOOL                            _hasClock;
    BOOL                            _hasCalendar;
    BOOL                            _isClockOnly;
    CPInteger                       _datePickerElements         @accessors(getter=datePickerElements);
}


#pragma mark Init method

/*! Init a _CPDatePickerCalendar
    @param aFrame
    @param aDatePicker
    @return a new instance of _CPDatePickerCalendar
*/
- (id)initWithFrame:(CGRect)aFrame withDatePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker         = aDatePicker;
        _datePickerElements = [_datePicker datePickerElements];

        [self _init];
    }

    return self;
}

/*! Init the object
*/
- (void)_init
{
    var sizeHeader          = [_datePicker valueForThemeAttribute:@"size-header"],
        sizeCalendar        = [_datePicker valueForThemeAttribute:@"size-calendar"],
        sizeClock           = [_datePicker valueForThemeAttribute:@"size-clock"],
        calendarClockMargin = [_datePicker valueForThemeAttribute:@"calendar-clock-margin"];

    _hasClock    = (_datePickerElements & CPHourMinuteSecondDatePickerElementFlag) || (_datePickerElements & CPHourMinuteDatePickerElementFlag);
    _hasCalendar = (_datePickerElements & CPYearMonthDayDatePickerElementFlag) || (_datePickerElements & CPYearMonthDatePickerElementFlag);
    _isClockOnly = _hasClock && !_hasCalendar;

    if (_hasCalendar && !_box)
    {
        _box = [[_CPDatePickerBox alloc] initWithFrame:CGRectMake(0, 0, sizeCalendar.width, sizeHeader.height + sizeCalendar.height)];
        [_box setDatePicker:_datePicker];
        [self addSubview:_box];

        _headerView = [[_CPDatePickerHeaderView alloc] initWithFrame:CGRectMake(0, 0, sizeHeader.width, sizeHeader.height) datePicker:_datePicker delegate:self];
        [_box addSubview:_headerView];

        _monthView = [[_CPDatePickerMonthView alloc] initWithFrame:CGRectMake(0, sizeHeader.height, sizeCalendar.width, sizeCalendar.height) datePicker:_datePicker delegate:self];
        [_box addSubview:_monthView];
    }

    if (_hasClock && !_datePickerClock)
    {
        _datePickerClock = [[_CPDatePickerClock alloc] initWithFrame:CGRectMake(0, 0, sizeClock.width, sizeClock.height) datePicker:_datePicker];
        [self addSubview:_datePickerClock];
    }

    if (_hasClock)
        [_datePickerClock setDatePickerElements:_datePickerElements];

    [self setDateValue:[_datePicker dateValue]];
}


#pragma mark -
#pragma mark Responder methods

- (BOOL)acceptsFirstResponder
{
    return YES;
}


#pragma mark -
#pragma mark Getter Setter methods

/*! Set the date value of the component. It sets the dateValue of the header and the monthView also
    @param aDateValue
*/
- (void)setDateValue:(CPDate)aDateValue
{
    var dateValue = [aDateValue copy];
    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    [_monthView setMonthForDate:dateValue];
    [_headerView setMonthForDate:[_monthView monthDate]];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*! Set enabled
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];

    [_datePickerClock setEnabled:aBoolean];
    [_headerView setEnabled:aBoolean];
    [_monthView setEnabled:aBoolean];
}

- (void)setDatePickerElements:(CPInteger)aDatePickerElements
{
    if (_datePickerElements === aDatePickerElements)
        return;

    _datePickerElements = aDatePickerElements;

    [self _init];
}

#pragma mark -
#pragma mark Layout methods

/*! Manager the subviews. It hides or not the clock.
*/
- (void)layoutSubviews
{
    var minSize = [_datePicker valueForThemeAttribute:@"min-size-calendar"],
        sizeHeader = [_datePicker valueForThemeAttribute:@"size-header"],
        sizeCalendar = [_datePicker valueForThemeAttribute:@"size-calendar"],
        sizeClock = [_datePicker valueForThemeAttribute:@"size-clock"],
        calendarClockMargin = [_datePicker valueForThemeAttribute:@"calendar-clock-margin"];

    if (_hasClock)
    {
        if (!_isClockOnly)
        {
            var frameSize = CGSizeMakeCopy(minSize);
            frameSize.width += sizeClock.width + calendarClockMargin;

            [_datePicker setFrameSize:frameSize];
            [_datePickerClock setFrameOrigin:CGPointMake(sizeCalendar.width + calendarClockMargin, [self bounds].size.height / 2 - sizeClock.height / 2)];
        }
        else
        {
            [_datePicker setFrameSize:sizeClock];
            [_datePickerClock setFrameOrigin:CGPointMake(0, 0)];
        }

        [_datePickerClock setHidden:NO];
        [_datePickerClock setFrameSize:sizeClock];
        [_datePickerClock setNeedsLayout];
    }
    else
    {
        [_datePicker setFrameSize:minSize];
        [_datePickerClock setHidden:YES];
    }

    if (_hasCalendar)
    {
        [_box setHidden:NO];
        [_headerView setHidden:NO];
        [_monthView setHidden:NO];
        [_box setNeedsLayout];
        [_box setNeedsDisplay:YES];
        [_headerView setNeedsLayout];
        [_monthView setNeedsLayout];
        [_monthView setNeedsDisplay:YES];
    }
    else
    {
        [_box setHidden:YES];
        [_headerView setHidden:YES];
        [_monthView setHidden:YES];
    }

    [self setFrameSize:[_datePicker frameSize]];
}


#pragma mark -
#pragma mark Action methods

/*! Move to the nextMonth without changing the dateValue of the datePicker
*/
- (void)_clickArrowNext:(id)sender
{
    var currentEvent = [CPApp currentEvent],
        modifierFlags = [currentEvent modifierFlags];

    if (modifierFlags & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        var date = [[_monthView monthDate] copy];
        date.setDate(1);

        if (modifierFlags & CPAlternateKeyMask)
            date.setUTCFullYear(date.getUTCFullYear() + 10);
        else
            date.setUTCFullYear(date.getUTCFullYear() + 1);

        [self setDateValue:date];
    }
    else
    {
         [self _displayNextMonth];
    }
}

- (void)_displayNextMonth
{
     [self setDateValue:[_monthView nextMonth]];
}

- (void)_displayPreviousMonth
{
    [self setDateValue:[_monthView previousMonth]];
}

/*! Move to the previous month without changing the dateValue of the datePicker
*/
- (void)_clickArrowPrevious:(id)sender
{
    var currentEvent = [CPApp currentEvent],
        modifierFlags = [currentEvent modifierFlags];

    if (modifierFlags & (CPCommandKeyMask | CPControlKeyMask | CPAlternateKeyMask))
    {
        var date = [[_monthView monthDate] copy];
        date.setDate(1);

        if (modifierFlags & CPAlternateKeyMask)
            date.setUTCFullYear(date.getUTCFullYear() - 10);
        else
            date.setUTCFullYear(date.getUTCFullYear() - 1);

        [self setDateValue:date];
    }
    else
    {
         [self _displayPreviousMonth];
    }
}

/*! Move to the current selected day
*/
- (void)_currentMonth:(id)sender
{
    [self setDateValue:[_datePicker dateValue]];
}

@end
