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

@import "CPControl.j"
@import "CPTextField.j"
@import "CPButton.j"
@import "CPView.j"
@import "CPBezierPath.j"
@import "_CPDatePickerClock.j"

@import <Foundation/Foundation.j>

@class CPDatePicker

@global CPSingleDateMode
@global CPRangeDateMode

@global CPTextFieldAndStepperDatePickerStyle
@global CPTextFieldDatePickerStyle

@global CPHourMinuteDatePickerElementFlag
@global CPHourMinuteSecondDatePickerElementFlag
@global CPTimeZoneDatePickerElementFlag
@global CPYearMonthDatePickerElementFlag
@global CPYearMonthDayDatePickerElementFlag
@global CPEraDatePickerElementFlag

var CPShortWeekDayNameArrayEn = [@"Mo", @"Tu", @"We", @"Th", @"Fr", @"Sa", @"Su"],
    CPShortWeekDayNameArrayUS = [@"Su", @"Mo", @"Tu", @"We", @"Th", @"Fr", @"Sa"],
    CPShortWeekDayNameArrayFr = [@"L", @"M", @"M", @"J", @"V", @"S", @"D"],
    CPShortWeekDayNameArrayDe = [@"M", @"D", @"M", @"D", @"F", @"S", @"S"],
    CPShortWeekDayNameArrayEs = [@"L", @"M", @"X", @"J", @"V", @"S", @"D"],
    CPShortMonthNameArrayEn = [@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"],
    CPShortMonthNameArrayFr = [@"janv.", String.fromCharCode(102, 233, 118, 46), @"mars", @"apr.", @"mai", @"juin", @"juil.", String.fromCharCode(97, 111, 251, 116), @"sept.", @"oct.", @"nov.", String.fromCharCode(100, 233, 99, 46)],
    CPShortMonthNameArrayDe = [@"Jan", @"Feb", String.fromCharCode(77, 228, 114), @"Apr", @"Mai", @"Jun", @"Jul", @"Aug", @"Sep", @"Okt", @"Nov", @"Dez"],
    CPShortMonthNameArrayEs = [@"ene", @"feb", @"mar", @"abr", @"may", @"jun", @"jul", @"ago", @"sep", @"oct", @"nov", @"dic"];

@implementation _CPDatePickerCalendar : CPControl
{
    _CPDatePickerMonthView          _monthView;
    _CPDatePickerHeaderView         _headerView;
    _CPDatePickerClock              _datePickerClock;
    CPBox                           _box;
    CPDatePicker                    _datePicker;
    CPInteger                       _startSelectionIndex;
    CPInteger                       _currentSelectionIndex;
}


#pragma mark -
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
        _datePicker = aDatePicker
        [self _init];
    }
    return self;
}

/*! Init the object
*/
- (void)_init
{
    var sizeHeader = [_datePicker valueForThemeAttribute:@"size-header"],
        sizeCalendar = [_datePicker valueForThemeAttribute:@"size-calendar"],
        sizeClock = [_datePicker valueForThemeAttribute:@"size-clock"];

    _box = [[_DatePickerBox alloc] initWithFrame:CGRectMake(0, 0, sizeCalendar.width, sizeHeader.height + sizeCalendar.height)];
    [_box setDatePicker:_datePicker];

    _headerView = [[_CPDatePickerHeaderView alloc] initWithFrame:CGRectMake(0, 0, sizeHeader.width, sizeHeader.height) datePicker:_datePicker delegate:self];
    [_box addSubview:_headerView];

    _monthView = [[_CPDatePickerMonthView alloc] initWithFrame:CGRectMake(0, sizeHeader.height, sizeCalendar.width, sizeCalendar.height) datePicker:_datePicker delegate:self];
    [_box addSubview:_monthView];

    _datePickerClock = [[_CPDatePickerClock alloc] initWithFrame:CGRectMake(sizeCalendar.width + 10, sizeHeader.height + sizeCalendar.height / 2 - sizeClock.height / 2, sizeClock.width, sizeClock.height) datePicker:_datePicker];
    [_datePickerClock setHidden:YES];
    [self addSubview:_datePickerClock];

    [self addSubview:_box];

    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Responder methods

- (BOOL)becomeFirstResponder
{
    return YES;
}

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


#pragma mark -
#pragma mark Layout methods

/*! Manager the subviews. It hides or not the clock.
*/
- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    var minSize = [_datePicker valueForThemeAttribute:@"min-size-calendar"],
        sizeHeader = [_datePicker valueForThemeAttribute:@"size-header"],
        sizeCalendar = [_datePicker valueForThemeAttribute:@"size-calendar"],
        sizeClock = [_datePicker valueForThemeAttribute:@"size-clock"];

    [super layoutSubviews];

    if ([_datePicker datePickerElements] & CPHourMinuteSecondDatePickerElementFlag || [_datePicker datePickerElements] & CPHourMinuteDatePickerElementFlag)
    {
        [_datePickerClock setHidden:NO];
        [_datePickerClock setNeedsLayout];

        if ([_datePicker datePickerElements] & CPYearMonthDatePickerElementFlag || [_datePicker datePickerElements] & CPYearMonthDayDatePickerElementFlag)
        {
            var frameSize = CGSizeMakeCopy(minSize);
            frameSize.width += sizeClock.width + 10;

            [_datePicker setFrameSize:frameSize];
            [_datePickerClock setFrameOrigin:CGPointMake(sizeCalendar.width + 10, [self bounds].size.height / 2 - sizeClock.height / 2)];
        }
        else
        {
            [_datePicker setFrameSize:sizeClock];
            [_datePickerClock setFrameOrigin:CGPointMake(0, 0)];
        }

    }
    else
    {
        [_datePicker setFrameSize:minSize];
        [_datePickerClock setHidden:YES];
    }

    if ([_datePicker datePickerElements] & CPYearMonthDatePickerElementFlag || [_datePicker datePickerElements] & CPYearMonthDayDatePickerElementFlag)
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
}


#pragma mark -
#pragma mark Action methods

/*! Move to the nextMonth without changing the dateValue of the datePicker
*/
- (void)_nextMonth:(id)sender
{
    [self setDateValue:[_monthView nextMonth]];
}

/*! Move to the previous month without changing the dateValue of the datePicker
*/
- (void)_previousMonth:(id)sender
{
    [self setDateValue:[_monthView previousMonth]];
}

/*! Move to the current selected day
*/
- (void)_currentMonth:(id)sender
{
    [self setDateValue:[_datePicker dateValue]];
}

@end


@implementation _CPDatePickerHeaderView : CPControl
{
    CPArray      _dayLabels;
    CPArray      _monthNames;
    CPButton     _nextButton;
    CPButton     _previousButton;
    CPButton     _currentButton;
    CPDatePicker _datePicker;
    CPDate       _date;
    CPTextField  _title;
}


#pragma mark -
#pragma mark Init methods

/*! Init a new instance of _CPDatePickerHeaderView
    @param aFrame
    @param aDatePicker
    @return a new instance of _CPDatePickerHeaderView
*/
- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)aDatePicker delegate:(id)aDelegate
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _datePicker = aDatePicker;

        // Title
        _title = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_title setValue:[_datePicker valueForThemeAttribute:@"title-font" inState:CPThemeStateNormal] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];

        [_title setValue:[_datePicker valueForThemeAttribute:@"title-font" inState:CPThemeStateDisabled] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
        [_title setValue:[_datePicker valueForThemeAttribute:@"title-text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

        [self addSubview:_title];

        _dayLabels = [CPArray array];

        // Days
        for (var i = 0; i < [[self _dayNames] count]; i++)
        {
            var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            [label setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];

            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-font" inState:CPThemeStateNormal] forThemeAttribute:@"font" inState:CPThemeStateNormal];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];

            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-font" inState:CPThemeStateDisabled] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
            [label setValue:[_datePicker valueForThemeAttribute:@"weekday-text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

            [_dayLabels addObject:label];
            [self addSubview:label];
        }

        // Arrows
        _previousButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
        [_previousButton setButtonType:CPMomentaryChangeButton];
        [_previousButton setBordered:NO];
        [_previousButton setImage:[_datePicker valueForThemeAttribute:@"arrow-image-left"]];
        [_previousButton setAlternateImage:[_datePicker valueForThemeAttribute:@"arrow-image-left-highlighted"]];
        [self addSubview:_previousButton];

        _nextButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
        [_nextButton setButtonType:CPMomentaryChangeButton];
        [_nextButton setBordered:NO];
        [_nextButton setImage:[_datePicker valueForThemeAttribute:@"arrow-image-right"]];
        [_nextButton setAlternateImage:[_datePicker valueForThemeAttribute:@"arrow-image-right-highlighted"]];
        [self addSubview:_nextButton];

        _currentButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
        [_currentButton setButtonType:CPMomentaryChangeButton];
        [_currentButton setBordered:NO];
        [_currentButton setImage:[_datePicker valueForThemeAttribute:@"circle-image"]];
        [_currentButton setAlternateImage:[_datePicker valueForThemeAttribute:@"circle-image-highlighted"]];
        [self addSubview:_currentButton];

        [_previousButton setTarget:aDelegate];
        [_previousButton setAction:@selector(_previousMonth:)];

        [_nextButton setTarget:aDelegate];
        [_nextButton setAction:@selector(_nextMonth:)];

        [_currentButton setTarget:aDelegate];
        [_currentButton setAction:@selector(_currentMonth:)];

        [self setNeedsLayout];
    }

    return self;
}


#pragma mark -
#pragma mark Getter Setter methods

/*! Return the day names depending on the CPLocale of the datePicker
    @return an array
*/
- (CPArray)_dayNames
{
    switch ([[_datePicker locale] objectForKey:CPLocaleLanguageCode])
    {
        case @"en":

            // Check if it's in the american format. If yes the week will begin the sunday
            if ([_datePicker _isAmericanFormat])
                return CPShortWeekDayNameArrayUS;
            else
                return CPShortWeekDayNameArrayEn;
            break;

        case @"es":
            return CPShortWeekDayNameArrayEs;
            break;

        case @"de":
            return CPShortWeekDayNameArrayDe;
            break;

        case @"fr":
            return CPShortWeekDayNameArrayFr;
            break;

        default:
            return CPShortWeekDayNameArrayEn
            break;
    }
}

/*! Return the month names depending on the CPLocale of the datePicker
    @return an array
*/
- (CPArray)_monthNames
{
    switch ([[_datePicker locale] objectForKey:CPLocaleLanguageCode])
    {
        case @"en":
            return CPShortMonthNameArrayEn;
            break;

        case @"es":
            return CPShortMonthNameArrayEs;
            break;

        case @"de":
            return CPShortMonthNameArrayDe;
            break;

        case @"fr":
            return CPShortMonthNameArrayFr;
            break;

        default:
            return CPShortMonthNameArrayEn
            break;
    }

}

/*! Set the monthDate of the header
    @aMonthDate the new monthDate
*/
- (void)setMonthForDate:(CPDate)aMonthDate
{
    _date = aMonthDate;
    [self setNeedsLayout];
}

/*! Set enabled
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [_previousButton setEnabled:aBoolean];
    [_nextButton setEnabled:aBoolean];
    [_currentButton setEnabled:aBoolean];
    [_dayLabels makeObjectsPerformSelector:@selector(setEnabled:) withObject:aBoolean];
    [_title setEnabled:aBoolean];
}


#pragma mark -
#pragma mark Layout methods

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    var bounds = [self bounds],
        dayNames = [self _dayNames],
        width = CGRectGetWidth(bounds),
        buttonInset = [_datePicker valueForThemeAttribute:@"arrow-inset"],
        numberOfLabels = [_dayLabels count],
        labelWidth = width / numberOfLabels,
        sizeButtonLeft = [[_datePicker valueForThemeAttribute:@"arrow-image-left"] size],
        sizeButtonRight = [[_datePicker valueForThemeAttribute:@"arrow-image-right"] size],
        sizeButtonCircle = [[_datePicker valueForThemeAttribute:@"circle-image"] size],
        sizeTileWidth = [_datePicker valueForThemeAttribute:@"size-tile"].width;

    // Arrows
    [_nextButton setFrame:CGRectMake(width - [_nextButton frameSize].width - buttonInset.right, buttonInset.top, sizeButtonRight.width, sizeButtonRight.height)];
    [_currentButton setFrame:CGRectMake(CGRectGetMinX([_nextButton frame]) - sizeButtonCircle.width - buttonInset.left - buttonInset.right, buttonInset.top, sizeButtonCircle.width, sizeButtonCircle.height)];
    [_previousButton setFrame:CGRectMake(CGRectGetMinX([_currentButton frame]) - sizeButtonLeft.width - buttonInset.left - buttonInset.right, buttonInset.top, sizeButtonLeft.width, sizeButtonLeft.height)];

    var firstDayTileX;

    // Weekday label
    for (var i = 0; i < numberOfLabels; i++)
    {
        var dayLabel = _dayLabels[i];

        [dayLabel setStringValue:dayNames[i]];
        [dayLabel sizeToFit]
        [dayLabel setFrameOrigin:CGPointMake(sizeTileWidth * (i + 1) - sizeTileWidth / 2 - [dayLabel frameSize].width / 2, 23)];

        if (i == 0)
            firstDayTileX = sizeTileWidth * (i + 1) - sizeTileWidth / 2 - [dayLabel frameSize].width / 2
    }

    // Title
    [_title setStringValue:[CPString stringWithFormat:@"%s %i", [self _monthNames][_date.getMonth()], _date.getFullYear()]];
    [_title sizeToFit];
    [_title setFrameOrigin:CGPointMake(firstDayTileX, 6)];
}

@end


@implementation _CPDatePickerMonthView : CPControl
{
    BOOL         _isMonthJustChanged;
    CPArray      _dayTiles;
    CPDate       _clickDate;
    CPDate       _dragDate;
    CPDate       _date;
    CPDate       _previousMonth @accessors(property=previousMonth);
    CPDate       _nextMonth @accessors(property=nextMonth);
    CPDatePicker _datePicker;
    CPEvent      _eventDragged;
    CPTimer      _timerMonth;
    id           _delegate;
    int          _indexDayTile;
}


#pragma mark -
#pragma mark Init methods

/*! Init a _CPDatePickerMonthView
    @param aFrame
    @param aDatePicker
    @return a new _CPDatePickerMonthView
*/
- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)aDatePicker delegate:(id)aDelegate
{
    if (self = [super initWithFrame:aFrame])
    {
        _delegate = aDelegate;
        _isMonthJustChanged = NO;
        _indexDayTile = -1;
        _datePicker = aDatePicker;
        _dayTiles = [CPArray array];

        // Create tiles
        for (var i = 0; i < 42; i++)
        {
            var dayView = [[_CPDatePickerDayView alloc] initWithFrame:CGRectMakeZero() withDatePicker:_datePicker];
            [self addSubview:dayView];
            [_dayTiles addObject:dayView];
        }

        [self setNeedsLayout];
    }
    return self;
}


#pragma mark -
#pragma mark Getter Setter methods

/*! Set the monthDate of the component
    @param aDate
*/
- (void)setMonthForDate:(CPDate)aDate
{
    if (_dragDate)
    {
         if (_dragDate.getMonth() != _date.getMonth())
             _isMonthJustChanged = YES;

         _date = [_dragDate copy];
    }
    else
    {
        _date = [aDate copy];
    }

    if (![aDate isEqualToDate:[CPDate distantFuture]])
    {
        // Reset the date to the first day of the month & midnight
        _date.setDate(1);
        [_date _resetToMidnight];

        // There must be a better way to do this.
        var firstDay = [_date copy];
        firstDay.setDate(1);

        // Set the previous and next month date. This is usefull for the tile of the next/previous month
        _previousMonth = new Date(firstDay.getTime() - 86400000);
        _previousMonth.setDate(1);

        _nextMonth = new Date(firstDay.getTime() + (([_date _daysInMonth] + 1) * 86400000));
        _nextMonth.setDate(1);
    }

    [self reloadData];

    if (_isMonthJustChanged)
    {
        var dayTile = [_dayTiles objectAtIndex:_indexDayTile];

        if ([dayTile date].getMonth() == _date.getMonth())
        {
            [self mouseDragged:_eventDragged];
        }
        else
        {
            if ([dayTile date].getMonth() - _date.getMonth() == 1 || [dayTile date].getFullYear() - _date.getFullYear() == 1)
                _timerMonth = [CPTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(_timerNextMonthEvent:) userInfo:nil repeats:NO];
            else
                _timerMonth = [CPTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(_timerPreviousMonthEvent:) userInfo:nil repeats:NO];
        }
    }
}

- (void)monthDate
{
    return _date;
}

/*! Return the size of a tile
*/
- (CGSize)tileSize
{
    return [_datePicker valueForThemeAttribute:@"size-tile"];
}

/*! Return the first index day of the month
*/
- (int)startOfWeekForDate:(CPDate)aDate
{
    var day = aDate.getDay();

    // American people begins the week the sunday
    if (![_datePicker _isAmericanFormat])
        return (day + 6) % 7;

    return day;
}

/*! Set enabled
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];
    [self reloadData];
}


/*! Return the index of tile depending of the giving event
    @param anEvent
    @return an index
*/
- (CPInteger)indexOfTileForEvent:(CPEvent)anEvent
{
    var locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        tileSize = [self tileSize];

    // Get the week row
    var rowIndex = FLOOR(locationInView.y / tileSize.height),
        columnIndex = FLOOR(locationInView.x / tileSize.width);

    columnIndex = MIN(MAX(columnIndex, 0), 6);
    rowIndex = MIN(MAX(rowIndex, 0), 5);

    var tileIndex = (rowIndex * 7) + columnIndex;

    return tileIndex;
}

#pragma mark -
#pragma mark Reload data

/*! Reload the data
*/
- (void)reloadData
{
    if (!_date)
        return;

    var currentMonth = _date,
        startOfMonthDay = [self startOfWeekForDate:currentMonth],
        daysInPreviousMonth = [_previousMonth _daysInMonth],
        firstDayToShowInPreviousMonth = daysInPreviousMonth - startOfMonthDay,
        currentDate = new Date(_previousMonth.getFullYear(), _previousMonth.getMonth(), firstDayToShowInPreviousMonth),
        now = [CPDate date],
        dateValue = [_datePicker dateValue];

    // Update the tiles
    for (var i = 0; i < [_dayTiles count]; i++)
    {
        var dayTile = _dayTiles[i];

        // Increment to next day
        currentDate.setTime(currentDate.getTime() + 90000000);
        [currentDate _resetToMidnight];

        var isPresentMonth = (now.getMonth() == currentDate.getMonth()
                      && now.getFullYear() == currentDate.getFullYear());

        [dayTile setDate:[currentDate copy]];
        [dayTile setStringValue:currentDate.getDate()];
        [dayTile setDisabled:![self isEnabled] || currentDate.getMonth() !== currentMonth.getMonth()];
        [dayTile setHighlighted:isPresentMonth && currentDate.getDate() == now.getDate()];
    }

    // Select the dates
    [self _selectDate:[_datePicker dateValue] timeInterval:[_datePicker timeInterval]];
}


#pragma mark -
#pragma mark Select methods

/*! Select one date or several date depending of the giving interval
    @param aStartDate
    @param anInterval;
*/
- (void)_selectDate:(CPDate)aStartDate timeInterval:(CPInteger)anInterval
{
    var endDate = [[CPDate alloc] initWithTimeInterval:anInterval sinceDate:aStartDate],
        tilesCount = [_dayTiles count];

    aStartDate = [aStartDate copy];

    [aStartDate _resetToMidnight];
    [endDate _resetToMidnight];

    for (var i = 0; i < tilesCount; i++)
    {
        var tile = _dayTiles[i],
            tileDate = [[tile date] copy],
            selected = NO;

        [tileDate _resetToMidnight]

        if (aStartDate)
            selected = tileDate >= aStartDate && tileDate <= endDate;

        // Select a tile
        [tile setSelected:selected];
    }
}

#pragma mark -
#pragma mark Layout methods

/*! Tile the view
*/
- (void)tile
{
    var tileSize = [self tileSize],
        width = tileSize.width,
        height = tileSize.height,
        tilesCount = [_dayTiles count],
        borderWidth =  [_datePicker valueForThemeAttribute:@"border-width"],
        tileIndex;

    // Set the frame of the tiles
    for (tileIndex = 0; tileIndex < tilesCount; tileIndex++)
    {
        var dayInWeek = tileIndex % 7,
            weekInMonth = (tileIndex - dayInWeek) / 7,
            tileFrame = CGRectMake(dayInWeek * width, weekInMonth * height, width + borderWidth, height + borderWidth);

        [_dayTiles[tileIndex] setFrame:tileFrame];
    }

    [self reloadData];
}

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    [super layoutSubviews];

    [self tile];
    [_dayTiles makeObjectsPerformSelector:@selector(setNeedsLayout)];
}

/*! Draw the component. This draws the border of the tile.
    The selected tile are drawed in the drawRect method of the tile. But the unselected tile here.
    It avoids some problems with tiles over other tiles (otherwise the color of the tile border would be different).
    Rememeber that the first pixel of a tile are over the last pixel of the last tile (because the border)
*/
- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        width = [self tileSize].width,
        height = [self tileSize].height,
        isBorderPair = ([_datePicker valueForThemeAttribute:@"border-width"] % 2) == 0;

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [_datePicker valueForThemeAttribute:@"border-color" inState:[_datePicker themeState]]);
    CGContextSetLineWidth(context,  [_datePicker valueForThemeAttribute:@"border-width"]);

    if ([_datePicker isBordered])
    {
        for (var i = 0; i < 6; i++)
        {
            var y = i * height;

            // Very usefull to avoid to have a line of two pixels instead one
            if (!isBorderPair)
                y += 0.5

            CGContextMoveToPoint(context, 0, y);
            CGContextAddLineToPoint(context, [self bounds].size.width, y);
        }

        for (var i = 0; i < 7; i++)
        {
            var x = i * width;

            // Very usefull to avoid to have a line of two pixels instead one
            if (!isBorderPair)
                x += 0.5

            CGContextMoveToPoint(context, x, 0);
            CGContextAddLineToPoint(context, x, [self bounds].size.height);
        }
    }
    else
    {
        var y = 0;

        // Very usefull to avoid to have a line of two pixels instead one
        if (!isBorderPair)
            y += 0.5

        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, [self bounds].size.width, y);
    }

    CGContextStrokePath(context);
    CGContextClosePath(context);
}


#pragma mark -
#pragma mark Mouse event

/*! Mouse down event
*/
- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    var dayTile = [_dayTiles objectAtIndex:[self indexOfTileForEvent:anEvent]],
        dateTile = [[dayTile date] copy],
        dateValue = [_datePicker dateValue];

    _clickDate = [dateTile copy];
    _dragDate = nil;
    _indexDayTile = -1;
    _eventDragged = nil

    // Check if we have to change or not the month of the component
    if ([dayTile date].getMonth() == _date.getMonth())
    {
        var minDate = [[_datePicker minDate] copy],
            maxDate = [[_datePicker maxDate] copy];

        [minDate _resetToMidnight];
        [maxDate _resetToLastSeconds];

        if (dateTile >= minDate && dateTile <= maxDate)
            [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:0];
    }
    else
    {
        // Check the year and the month. The year is usefull when changing from Jan to Dec.
        if (_date.getMonth() - [dayTile date].getMonth() == 1 || _date.getFullYear() - [dayTile date].getFullYear() == 1)
            [_delegate _previousMonth:self];
        else
            [_delegate _nextMonth:self];
    }
}

/*! Mouse dragged event
*/
- (void)mouseDragged:(CPEvent)anEvent
{
    if (![self isEnabled]  || !CGRectContainsPoint([self bounds],[self convertPoint:[anEvent locationInWindow] fromView:nil]))
        return;

    var dayTile = [_dayTiles objectAtIndex:[self indexOfTileForEvent:anEvent]],
        dateTile = [[dayTile date] copy],
        dateValue = [_datePicker dateValue];

    _dragDate = [dateTile copy];
    _indexDayTile = [self indexOfTileForEvent:anEvent];
    _eventDragged = anEvent;

    if ([_datePicker datePickerMode] == CPSingleDateMode)
    {
        // Check if we have to change or not the month of the component
        if ([dayTile date].getMonth() == _date.getMonth())
        {
            [_timerMonth invalidate];
            _isMonthJustChanged = NO;

            [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:0];
        }
        else if (!_isMonthJustChanged)
        {
            [_timerMonth invalidate];
            _isMonthJustChanged = NO;

            // Check the year and the month. The year is usefull when changing from Jan to Dec.
            if (_date.getMonth() - [dayTile date].getMonth() == 1 || _date.getFullYear() - [dayTile date].getFullYear() == 1)
                [_delegate _previousMonth:self];
            else
                [_delegate _nextMonth:self];
        }
    }
    else
    {
        if (dateTile.getMonth() == _date.getMonth() || !_isMonthJustChanged)
        {
            [_timerMonth invalidate];
            _isMonthJustChanged = NO;

            var dateValueAtMidnight = [[_datePicker dateValue] copy];

            [dateValueAtMidnight _resetToMidnight];

            if (dateTile < _clickDate)
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:[_clickDate timeIntervalSinceDate:dateTile]];
            else if ([[dayTile date] isEqualToDate:_clickDate])
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:0];
            else
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:_clickDate] timeInterval:[dateTile timeIntervalSinceDate:dateValueAtMidnight]];
        }
    }
}

- (void)mouseUp:(CPEvent)anEvent
{
    [_timerMonth invalidate];
    _dragDate = nil;
    _clickDate = nil;
    _isMonthJustChanged = NO;
    _indexDayTile = -1;
    _eventDragged = nil;
}


#pragma mark -
#pragma mark Timer

- (void)_timerNextMonthEvent:(CPEvent)anEvent
{
    if (_isMonthJustChanged)
    {
        _dragDate.setMonth(_date.getMonth() + 1);
        [_delegate _nextMonth:self];
    }
}

- (void)_timerPreviousMonthEvent:(CPEvent)anEvent
{
    if (_isMonthJustChanged)
    {
        _dragDate.setMonth(_date.getMonth() - 1);
        [_delegate _previousMonth:self];
    }
}


#pragma mark -
#pragma mark Date methods

- (CPDate)_hoursMinutesSecondsFromDatePickerForDate:(CPDate)aDate
{
    var dateValue = [_datePicker dateValue];

    aDate.setHours(dateValue.getHours());
    aDate.setMinutes(dateValue.getMinutes());
    aDate.setSeconds(dateValue.getSeconds());

    return aDate;
}

@end


@implementation _CPDatePickerDayView : CPControl
{
    CPDate          _date @accessors(property=date);

    BOOL            _isDisabled;
    BOOL            _isHighlighted;
    BOOL            _isSelected;
    CPDatePicker    _datePicker;
    CPTextField     _textField;
}


#pragma mark -
#pragma mark Init methods

/*! Create a new instance of _CPDatePickerDayView
    @param aFrame
    @param aDatePicker
    @return a new instance of _CPDatePickerDayView
*/
- (id)initWithFrame:(CGRect)aFrame withDatePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];

        _datePicker = aDatePicker;

        _textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeStateNormal] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeStateSelected] forThemeAttribute:@"font" inState:CPThemeStateSelected];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeStateDisabled] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)] forThemeAttribute:@"font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)] forThemeAttribute:@"text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeStateHighlighted] forThemeAttribute:@"font" inState:CPThemeStateHighlighted];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateHighlighted];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateHighlighted];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"font" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-color" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-color" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-offset" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateSelected)];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)] forThemeAttribute:@"text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected)];

        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)] forThemeAttribute:@"font" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)] forThemeAttribute:@"text-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)] forThemeAttribute:@"text-shadow-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];
        [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)] forThemeAttribute:@"text-shadow-offset" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];

        [self addSubview:_textField];

        [self setNeedsLayout];
    }

    return self;
}


#pragma mark -
#pragma mark Theme methods

/*! Set a theme
*/
- (BOOL)setThemeState:(CPThemeState)aState
{
    [_textField setThemeState:aState];
    [super setThemeState:aState];
}

/*! Unset a theme
*/
- (BOOL)unsetThemeState:(CPThemeState)aState
{
    [_textField unsetThemeState:aState];
    [super unsetThemeState:aState];
}


#pragma mark -
#pragma mark Getter methods

/*! Select the tile
*/
- (void)setSelected:(BOOL)shouldBeSelected
{
    if (_isSelected === shouldBeSelected)
        return;

    _isSelected = shouldBeSelected;

    if (_isSelected)
        [self setThemeState:CPThemeStateSelected];
    else
        [self unsetThemeState:CPThemeStateSelected];
}

/*! Disabled the tile (used for previous and next month tile)
*/
- (void)setDisabled:(BOOL)shouldBeDisabled
{
    if (_isDisabled === shouldBeDisabled)
        return;

    _isDisabled = shouldBeDisabled;

    if (_isDisabled)
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];
}

/*! Highlight the tile (used for current day)
*/
- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    if (_isHighlighted === shouldBeHighlighted)
        return;

    _isHighlighted = shouldBeHighlighted;

    if (_isHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

/*! Set the stringValue of the tile
    @param aStringValue
*/
- (void)setStringValue:(CPString)aStringValue
{
    [_textField setStringValue:aStringValue];
    [_textField sizeToFit];
}


#pragma mark -
#pragma mark Layout methods

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    var bounds = [self bounds];
    [_textField sizeToFit];
    [_textField setFrameOrigin:CGPointMake(bounds.size.width / 2 - [_textField frameSize].width / 2 + [_datePicker valueForThemeAttribute:@"border-width"], bounds.size.height / 2 - [_textField frameSize].height / 2)];
}

/*! Drawrect
*/
- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var themeState = [self themeState],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    if (themeState.hasThemeState(CPThemeStateSelected))
    {
        [self setBackgroundColor:[_datePicker valueForThemeAttribute:@"bezel-color-calendar" inState:themeState]];
        CGContextSetLineWidth(context, [_datePicker valueForThemeAttribute:@"border-width"]);
        CGContextSetStrokeColor(context, [_datePicker valueForThemeAttribute:@"border-color" inState:themeState]);
        CGContextAddRect(context, [self bounds]);
        CGContextStrokeRect(context, [self bounds]);
    }
    else
    {
        // Clear color, because the original color of a tile is handle by his superview
        [self setBackgroundColor:[CPColor clearColor]];
    }

}

@end


@implementation _DatePickerBox : CPView
{
    CPDatePicker _datePicker @accessors(property=datePicker);
}

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    if ([_datePicker isBordered])
    {
        var context = [[CPGraphicsContext currentContext] graphicsPort],
            borderWidth = [_datePicker valueForThemeAttribute:@"border-width"] / 2;

        CGContextBeginPath(context);
        CGContextSetStrokeColor(context, [_datePicker valueForThemeAttribute:@"border-color" inState:[_datePicker themeState]]);
        CGContextSetLineWidth(context,  [_datePicker valueForThemeAttribute:@"border-width"]);

        CGContextMoveToPoint(context, borderWidth,borderWidth);
        CGContextAddLineToPoint(context, aRect.size.width - borderWidth,borderWidth);
        CGContextAddLineToPoint(context, aRect.size.width - borderWidth,aRect.size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth,aRect.size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth,borderWidth);

        CGContextStrokePath(context);
        CGContextClosePath(context);
    }
}

- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    if ([_datePicker drawsBackground])
        [self setBackgroundColor:[_datePicker backgroundColor]];
    else
        [self setBackgroundColor:[CPColor clearColor]];
}


@end
