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
@import "CPWindow_Constants.j"

@global CPApp

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
    CPLevelIndicator    _levelIndicatorStyle    @accessors(property=levelIndicatorStyle);
    double              _minValue               @accessors(property=minValue);
    double              _maxValue               @accessors(property=maxValue);
    double              _warningValue           @accessors(property=warningValue);
    double              _criticalValue          @accessors(property=criticalValue);
    CPTickMarkPosition  _tickMarkPosition       @accessors(property=tickMarkPosition);
    int                 _numberOfTickMarks      @accessors(property=numberOfTickMarks);
    int                 _numberOfMajorTickMarks @accessors(property=numberOfMajorTickMarks);

    BOOL                _isEditable;

    BOOL                _isTracking;
}

+ (CPString)defaultThemeClass
{
    return "level-indicator";
}

+ (id)themeAttributes
{
    return @{
            @"bezel-color": [CPNull null],
            @"color-empty": [CPNull null],
            @"color-normal": [CPNull null],
            @"color-warning": [CPNull null],
            @"color-critical": [CPNull null],
            @"spacing": 1.0,
        };
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

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:"bezel"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:nil];
    // TODO Make themable.
    [bezelView setBackgroundColor:[self valueForThemeAttribute:@"bezel-color"]];

    var segmentCount = _maxValue - _minValue;

    if (segmentCount <= 0)
        return;

    var filledColor = [self valueForThemeAttribute:@"color-normal"],
        value = [self doubleValue];

    if (value <= _criticalValue)
        filledColor = [self valueForThemeAttribute:@"color-critical"];
    else if (value <= _warningValue)
        filledColor = [self valueForThemeAttribute:@"color-warning"];

    for (var i = 0; i < segmentCount; i++)
    {
        var segmentView = [self layoutEphemeralSubviewNamed:"segment-bezel-" + i
                                               positioned:CPWindowAbove
                          relativeToEphemeralSubviewNamed:bezelView];

        [segmentView setBackgroundColor:(_minValue + i) < value ? filledColor : [self valueForThemeAttribute:@"color-empty"]];
    }
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    return [[CPView alloc] initWithFrame:CGRectMakeZero()];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aViewName
{
    // TODO Put into theme attributes.
    var bezelHeight = 18,
        segmentHeight = 17,
        bounds = CGRectCreateCopy([self bounds]);

    if (aViewName == "bezel")
    {
        bounds.origin.y = (CGRectGetHeight(bounds) - bezelHeight) / 2.0;
        bounds.size.height = bezelHeight;
        return bounds;
    }
    else if (aViewName.indexOf("segment-bezel") === 0)
    {
        var segment = parseInt(aViewName.substring("segment-bezel-".length), 10),
            segmentCount = _maxValue - _minValue;

        if (segment >= segmentCount)
            return CGRectMakeZero();

        var basicSegmentWidth = bounds.size.width / segmentCount,
            segmentFrame = CGRectCreateCopy([self bounds]),
            spacing = [self valueForThemeAttribute:@"spacing"];

        segmentFrame.origin.y = (CGRectGetHeight(bounds) - bezelHeight) / 2.0;
        segmentFrame.origin.x =  FLOOR(segment * basicSegmentWidth);
        segmentFrame.size.width = (segment == segmentCount - 1) ? bounds.size.width - segmentFrame.origin.x : FLOOR(((segment + 1) * basicSegmentWidth)) - FLOOR((segment * basicSegmentWidth)) - spacing;
        segmentFrame.size.height = segmentHeight;

        return segmentFrame;
    }

    return CGRectMakeZero();
}

/*!
    Sets whether or not the receiver level indicator can be edited.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    if (_isEditable === shouldBeEditable)
        return;

    _isEditable = shouldBeEditable;
}

/*!
    Returns \c YES if the textfield is currently editable by the user.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

- (CPView)hitTest:(CGPoint)aPoint
{
    // Don't swallow clicks when displayed in a table.
    if (![self isEditable])
        return nil;

    return [super hitTest:aPoint];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEditable] || ![self isEnabled])
        return;

    [self _trackMouse:anEvent];
}

- (void)_trackMouse:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type == CPLeftMouseDown || type == CPLeftMouseDragged)
    {
        var segmentCount = _maxValue - _minValue;

        if (segmentCount <= 0)
            return;

        var location = [self convertPoint:[anEvent locationInWindow] fromView:nil],
            bounds = [self bounds],
            oldValue = [self doubleValue],
            newValue = oldValue;

        // Moving the mouse outside of the widget to the left sets it
        // to its minimum, and moving outside on the right sets it to
        // its maximum.
        if (type == CPLeftMouseDragged && location.x < 0)
        {
            newValue = _minValue;
        }
        else if (type == CPLeftMouseDragged && location.x > bounds.size.width)
        {
            newValue = _maxValue;
        }
        else
        {
            for (var i = 0; i < segmentCount; i++)
            {
                var rect = [self rectForEphemeralSubviewNamed:"segment-bezel-" + i];

                // Once we're tracking the mouse, we only care about horizontal mouse movement.
                if (location.x >= CGRectGetMinX(rect) && location.x < CGRectGetMaxX(rect))
                {
                    newValue = (_minValue + i + 1);
                    break;
                }
            }
        }

        if (newValue != oldValue)
            [self setDoubleValue:newValue];

        // Track the mouse to support click and slide value editing.
        _isTracking = YES;
        [CPApp setTarget:self selector:@selector(_trackMouse:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];

        if ([self isContinuous])
            [self sendAction:[self action] to:[self target]];
    }
    else if (_isTracking)
    {
        _isTracking = NO;
        [self sendAction:[self action] to:[self target]];
    }
}

/*
- (CPLevelIndicatorStyle)style;
- (void)setLevelIndicatorStyle:(CPLevelIndicatorStyle)style;
*/

- (void)setMinValue:(double)minValue
{
    if (_minValue === minValue)
        return;
    _minValue = minValue;

    [self setNeedsLayout];
}

- (void)setMaxValue:(double)maxValue
{
    if (_maxValue === maxValue)
        return;
    _maxValue = maxValue;

    [self setNeedsLayout];
}

- (void)setWarningValue:(double)warningValue;
{
    if (_warningValue === warningValue)
        return;
    _warningValue = warningValue;

    [self setNeedsLayout];
}

- (void)setCriticalValue:(double)criticalValue;
{
    if (_criticalValue === criticalValue)
        return;
    _criticalValue = criticalValue;

    [self setNeedsLayout];
}

/*
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
    CPLevelIndicatorNumberOfMajorTickMarksKey   = "CPLevelIndicatorNumberOfMajorTickMarksKey",
    CPLevelIndicatorIsEditableKey               = "CPLevelIndicatorIsEditableKey";

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

        _isEditable = [aCoder decodeBoolForKey:CPLevelIndicatorIsEditableKey];

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
    [aCoder encodeBool:_isEditable forKey:CPLevelIndicatorIsEditableKey];
}

@end
