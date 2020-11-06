/* _CPDatePickerMonthView.j
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

@import "CPControl.j"
@import "_CPDatePickerDayView.j"

@class CPDatePicker

@global CPSingleDateMode
@global CPRangeDateMode

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
        tileSize       = [self tileSize],
        borderWidth    = [_datePicker valueForThemeAttribute:@"border-width"],
        margin         = [_datePicker valueForThemeAttribute:@"tile-margin"] || CGSizeMakeZero(),
        tileInset      = [_datePicker valueForThemeAttribute:@"tile-inset"] || CGInsetMakeZero();

    // Get the week row
    var rowIndex    = FLOOR((locationInView.y - tileInset.top - margin.height) / (tileSize.height + 2 * margin.height + borderWidth)),
        columnIndex = FLOOR((locationInView.x - tileInset.left) / (tileSize.width + 2 * margin.width + borderWidth));

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
        [dayTile setDisabled:/*![self isEnabled] ||*/ currentDate.getMonth() !== currentMonth.getMonth() || currentDate < [_datePicker minDate] || currentDate > [_datePicker maxDate]];
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

    var firstSelected = NO;

    for (var i = 0; i < tilesCount; i++)
    {
        var tile = _dayTiles[i],
            tileDate = [[tile date] copy],
            selected = NO;

        [tileDate _resetToMidnight];

        if (aStartDate)
            selected = tileDate >= aStartDate && tileDate <= endDate;

        // Select a tile
        [tile setSelected:selected];

        // If we are disabled, we have to disable selected tiles so they will appear disabled
        [tile setDisabled:[tile isDisabled] || (selected && ![self isEnabled])];

        if (selected)
        {
            if (!firstSelected)
            {
                firstSelected = YES;
                [tile setFirstSelected:YES];
            }
            else
                [tile setFirstSelected:NO];

            [tile setLastSelected:NO];
        }
        else
        {
            if (firstSelected)
            {
                firstSelected = NO;

                // As there was a first selected and we are now on an unselected tile,
                // we are sure that i > 0
                [_dayTiles[i-1] setLastSelected:YES];
            }
        }
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
        margin = [_datePicker valueForThemeAttribute:@"tile-margin"],
        tileInset = [_datePicker valueForThemeAttribute:@"tile-inset"],
        thisWidth,
        thisX,
        dayInWeek,
        weekInMonth,
        tileFrame,
        tileIndex;

    // Set the frame of the tiles
    for (tileIndex = 0; tileIndex < tilesCount; tileIndex++)
    {
        dayInWeek   = tileIndex % 7;
        weekInMonth = (tileIndex - dayInWeek) / 7;
        tileFrame;

        if (margin) // Beginning with Aristo3
        {
            thisX     = ROUND(dayInWeek * (width + 2 * margin.width));
            thisWidth = ROUND((dayInWeek+1) * (width + 2 * margin.width)) - thisX;

            tileFrame = CGRectMake(tileInset.left + thisX, tileInset.top + margin.height + weekInMonth * (height + 2 * margin.height), thisWidth + borderWidth, height + borderWidth);
        }
        else
            tileFrame = CGRectMake(dayInWeek * width, weekInMonth * height, width + borderWidth, height + borderWidth);

        [_dayTiles[tileIndex] setFrame:tileFrame];
        [_dayTiles[tileIndex] setDayInWeek:dayInWeek];
    }

    [self reloadData];
}

/*! Layout the subviews
*/
- (void)layoutSubviews
{
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

    if ([_datePicker isCSSBased])
    {
        // We just have to draw the separator (if any)
        // No separator color means no separator
        var separatorColor       = [_datePicker valueForThemeAttribute:@"separator-color"],
            separatorHeight      = [_datePicker valueForThemeAttribute:@"separator-height"],
            separatorMarginWidth = [_datePicker valueForThemeAttribute:@"separator-margin-width"];

        if (separatorColor)
        {
            var context = [[CPGraphicsContext currentContext] graphicsPort],
                bounds  = [self bounds];

            CGContextBeginPath(context);
            CGContextSetStrokeColor(context, separatorColor);
            CGContextSetLineWidth(context, separatorHeight);
            CGContextMoveToPoint(context, separatorMarginWidth, 0.5);
            CGContextAddLineToPoint(context, bounds.size.width - separatorMarginWidth, 0.5);
            CGContextStrokePath(context);
            CGContextClosePath(context);
        }

        return;
    }

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
                y += 0.5;

            CGContextMoveToPoint(context, 0, y);
            CGContextAddLineToPoint(context, [self bounds].size.width, y);
        }

        for (var i = 0; i < 7; i++)
        {
            var x = i * width;

            // Very usefull to avoid to have a line of two pixels instead one
            if (!isBorderPair)
                x += 0.5;

            CGContextMoveToPoint(context, x, 0);
            CGContextAddLineToPoint(context, x, [self bounds].size.height);
        }
    }
    else
    {
        var y = 0;

        // Very usefull to avoid to have a line of two pixels instead one
        if (!isBorderPair)
            y += 0.5;

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
    _eventDragged = nil;

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = YES;
#endif

    // Check if we have to change or not the month of the component
    if ([dayTile date].getMonth() == _date.getMonth())
    {
        if ([_datePicker datePickerMode] == CPRangeDateMode && [anEvent modifierFlags] & CPShiftKeyMask)
        {
            var dateValueAtMidnight = [[_datePicker dateValue] copy];

            [dateValueAtMidnight _resetToMidnight];

            if (dateTile < dateValueAtMidnight)
            {
                var interval;

                if (dateTile == dateValueAtMidnight)
                    interval = [_datePicker timeInterval];
                else
                    interval = ([dateValueAtMidnight timeIntervalSinceDate:dateTile] + [_datePicker timeInterval]);

                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:interval];
            }
            else if ([[dayTile date] isEqualToDate:dateValueAtMidnight])
            {
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:0];
            }
            else
            {
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:[dateValueAtMidnight copy]] timeInterval:([dateTile timeIntervalSinceDate:dateValueAtMidnight])];
            }

            // Be sure to display the good month
            [_delegate setDateValue:dateTile];
        }
        else
        {
            var minDate = [[_datePicker minDate] copy],
                maxDate = [[_datePicker maxDate] copy];

            [minDate _resetToMidnight];
            [maxDate _resetToLastSeconds];

            if (dateTile >= minDate && dateTile <= maxDate)
                [_datePicker _setDateValue:[self _hoursMinutesSecondsFromDatePickerForDate:dateTile] timeInterval:0];
        }
    }
    else
    {
        // Check the year and the month. The year is usefull when changing from Jan to Dec.
        if (_date.getMonth() - [dayTile date].getMonth() == 1 || _date.getFullYear() - [dayTile date].getFullYear() == 1)
            [_delegate _displayPreviousMonth];
        else
            [_delegate _displayNextMonth];
    }

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = NO;
#endif
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

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = YES;
#endif

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
                [_delegate _displayPreviousMonth];
            else
                [_delegate _displayNextMonth];
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

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = NO;
#endif
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
        [_delegate _displayNextMonth];
    }
}

- (void)_timerPreviousMonthEvent:(CPEvent)anEvent
{
    if (_isMonthJustChanged)
    {
        _dragDate.setMonth(_date.getMonth() - 1);
        [_delegate _displayPreviousMonth];
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

