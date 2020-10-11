/* _CPDatePickerHeaderView.j
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
@import "CPTextField.j"
@import "CPButton.j"

@class CPDatePicker

var CPShortWeekDayNameArrayEn = [@"Mo", @"Tu", @"We", @"Th", @"Fr", @"Sa", @"Su"],
    CPShortWeekDayNameArrayUS = [@"Su", @"Mo", @"Tu", @"We", @"Th", @"Fr", @"Sa"],
    CPShortWeekDayNameArrayFr = [@"L", @"M", @"M", @"J", @"V", @"S", @"D"],
    CPShortWeekDayNameArrayDe = [@"M", @"D", @"M", @"D", @"F", @"S", @"S"],
    CPShortWeekDayNameArrayEs = [@"L", @"M", @"X", @"J", @"V", @"S", @"D"],
    CPShortMonthNameArrayEn = [@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"],
    CPShortMonthNameArrayFr = [@"janv.", String.fromCharCode(102, 233, 118, 46), @"mars", @"apr.", @"mai", @"juin", @"juil.", String.fromCharCode(97, 111, 251, 116), @"sept.", @"oct.", @"nov.", String.fromCharCode(100, 233, 99, 46)],
    CPShortMonthNameArrayDe = [@"Jan", @"Feb", String.fromCharCode(77, 228, 114), @"Apr", @"Mai", @"Jun", @"Jul", @"Aug", @"Sep", @"Okt", @"Nov", @"Dez"],
    CPShortMonthNameArrayEs = [@"ene", @"feb", @"mar", @"abr", @"may", @"jun", @"jul", @"ago", @"sep", @"oct", @"nov", @"dic"];

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
        for (var i = 0, count = [[self _dayNames] count]; i < count; i++)
        {
            var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            [label setValue:[_datePicker valueForThemeAttribute:@"tile-text-alignment"] forThemeAttribute:@"alignment"];

            var contentInset = [_datePicker valueForThemeAttribute:@"tile-content-inset"];

            if (contentInset)
                [label setValue:contentInset forThemeAttribute:@"content-inset"];

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
        var size = [_datePicker valueForThemeAttribute:@"previous-button-size"];

        _previousButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [_previousButton setButtonType:CPMomentaryChangeButton];
        [_previousButton setBordered:NO];
        [_previousButton setImage:[_datePicker valueForThemeAttribute:@"arrow-image-left"]];
        [_previousButton setAlternateImage:[_datePicker valueForThemeAttribute:@"arrow-image-left-highlighted"]];
        [self addSubview:_previousButton];

        size = [_datePicker valueForThemeAttribute:@"next-button-size"];

        _nextButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [_nextButton setButtonType:CPMomentaryChangeButton];
        [_nextButton setBordered:NO];
        [_nextButton setImage:[_datePicker valueForThemeAttribute:@"arrow-image-right"]];
        [_nextButton setAlternateImage:[_datePicker valueForThemeAttribute:@"arrow-image-right-highlighted"]];
        [self addSubview:_nextButton];

        size = [_datePicker valueForThemeAttribute:@"current-button-size"];

        _currentButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [_currentButton setButtonType:CPMomentaryChangeButton];
        [_currentButton setBordered:NO];
        [_currentButton setImage:[_datePicker valueForThemeAttribute:@"circle-image"]];
        [_currentButton setAlternateImage:[_datePicker valueForThemeAttribute:@"circle-image-highlighted"]];
        [self addSubview:_currentButton];

        [_previousButton setTarget:aDelegate];
        [_previousButton setAction:@selector(_clickArrowPrevious:)];
        [_previousButton setContinuous:YES];

        [_nextButton setTarget:aDelegate];
        [_nextButton setAction:@selector(_clickArrowNext:)];
        [_nextButton setContinuous:YES];

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
            return CPShortWeekDayNameArrayEn;
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
            return CPShortMonthNameArrayEn;
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
    var bounds = [self bounds],
        dayNames = [self _dayNames],
        width = CGRectGetWidth(bounds),
        buttonInset = [_datePicker valueForThemeAttribute:@"arrow-inset"],
        numberOfLabels = [_dayLabels count],
        labelWidth = width / numberOfLabels,
        sizeButtonLeft = [[_datePicker valueForThemeAttribute:@"arrow-image-left"] size],
        sizeButtonRight = [[_datePicker valueForThemeAttribute:@"arrow-image-right"] size],
        sizeButtonCircle = [[_datePicker valueForThemeAttribute:@"circle-image"] size],
        sizeTileWidth = [_datePicker valueForThemeAttribute:@"size-tile"].width,
        titleInset    = [_datePicker valueForThemeAttribute:@"title-inset"],
        dayLabelInset = [_datePicker valueForThemeAttribute:@"day-label-inset"];

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

        if (dayLabelInset) // Beginning with Aristo3
        {
            var thisWidth = ROUND((i+1) * sizeTileWidth) - ROUND(i * sizeTileWidth);

            [dayLabel sizeToFit];
            [dayLabel setFrame:CGRectMake(dayLabelInset.left + ROUND(i * sizeTileWidth), dayLabelInset.top, thisWidth, [dayLabel frameSize].height)];
        }
        else
        {
            [dayLabel sizeToFit];
            [dayLabel setFrameOrigin:CGPointMake(sizeTileWidth * (i + 1) - sizeTileWidth / 2 - [dayLabel frameSize].width / 2, 23)];

            if (i == 0)
                firstDayTileX = sizeTileWidth * (i + 1) - sizeTileWidth / 2 - [dayLabel frameSize].width / 2;
        }
    }

    // Title
    [_title setStringValue:[CPString stringWithFormat:@"%s %i", [self _monthNames][_date.getMonth()], _date.getFullYear()]];
    [_title sizeToFit];

    if (titleInset) // Beginning with Aristo3
        [_title setFrameOrigin:CGPointMake(titleInset.left, titleInset.top)];
    else
        [_title setFrameOrigin:CGPointMake(firstDayTileX, 6)];
}

@end
