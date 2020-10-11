/* _CPDatePickerDayView.j
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

@import "_CPDatePickerDayViewTextField.j"

@class CPDatePicker

@implementation _CPDatePickerDayView : CPControl
{
    CPDate          _date @accessors(property=date);

    BOOL            _isDisabled;
    BOOL            _isHighlighted;
    BOOL            _isSelected;
    CPDatePicker    _datePicker;
    CPTextField     _textField;

    CPInteger       _dayInWeek      @accessors(property=dayInWeek);
    BOOL            _firstSelected  @accessors(property=firstSelected);
    BOOL            _lastSelected   @accessors(property=lastSelected);
}


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

        // FIXME: Beginning with Aristo3, the text field is directly themed based on a new class _CPDatePickerDayViewTextField
        if ([self isCSSBased])
        {
            _textField = [[_CPDatePickerDayViewTextField alloc] initWithFrame:aFrame];
        }
        else
        {
            _textField = [[CPTextField alloc] initWithFrame:aFrame];

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-alignment"] forThemeAttribute:@"alignment"];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-vertical-alignment"] forThemeAttribute:@"vertical-alignment"];

            var contentInset = [_datePicker valueForThemeAttribute:@"tile-content-inset"];

            if (contentInset)
                [_textField setValue:contentInset forThemeAttribute:@"content-inset"];

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

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inStates:[CPThemeStateDisabled, CPThemeStateSelected]] forThemeAttribute:@"font" inStates:[CPThemeStateDisabled, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inStates:[CPThemeStateDisabled, CPThemeStateSelected]]forThemeAttribute:@"text-color" inStates:[CPThemeStateDisabled, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateSelected]];

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inState:CPThemeStateHighlighted] forThemeAttribute:@"font" inState:CPThemeStateHighlighted];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateHighlighted];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inState:CPThemeStateHighlighted] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateHighlighted];

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"font" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-color" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-color" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-offset" inStates:[CPThemeStateHighlighted, CPThemeStateSelected]];

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"font" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]] forThemeAttribute:@"text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateSelected]];

            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-font" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]] forThemeAttribute:@"font" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]] forThemeAttribute:@"text-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]] forThemeAttribute:@"text-shadow-color" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
            [_textField setValue:[_datePicker valueForThemeAttribute:@"tile-text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]] forThemeAttribute:@"text-shadow-offset" inStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
        }

        [self addSubview:_textField];

        [self setNeedsLayout];
    }

    return self;
}


#pragma mark -
#pragma mark Theme methods

/*! Set a theme
*/
- (BOOL)setThemeState:(ThemeState)aState
{
    [_textField setThemeState:aState];
    [super setThemeState:aState];
}

/*! Unset a theme
*/
- (BOOL)unsetThemeState:(ThemeState)aState
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

- (BOOL)isDisabled
{
    return _isDisabled;
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
}


#pragma mark -
#pragma mark Layout methods

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    if ([_datePicker isCSSBased])
    {
        var attributeName = @"bezel-color-calendar";

        if (_isSelected)
        {
            if (_firstSelected && !_lastSelected)
                attributeName = @"bezel-color-calendar-left";
            else if (_lastSelected && !_firstSelected)
                attributeName = @"bezel-color-calendar-right";
            else if (!_firstSelected && !_lastSelected)
            {
                if (_dayInWeek == 0)
                    attributeName = @"bezel-color-calendar-left";
                else if (_dayInWeek == 6)
                    attributeName = @"bezel-color-calendar-right";
                else
                    attributeName = @"bezel-color-calendar-middle";
            }
        }

        [self setBackgroundColor:[_datePicker valueForThemeAttribute:attributeName inState:[self themeState]]];
        return;
    }

    var bounds = [self bounds];
    [_textField sizeToFit];
    [_textField setFrameOrigin:CGPointMake(bounds.size.width / 2 - [_textField frameSize].width / 2 + [_datePicker valueForThemeAttribute:@"border-width"], bounds.size.height / 2 - [_textField frameSize].height / 2)];
}

- (void)setFrame:(CGRect)aFrame
{
    [super setFrame:aFrame];
    [_textField setFrame:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height)];
}

/*! Drawrect
*/
- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    if ([_datePicker isCSSBased])
        return;

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

