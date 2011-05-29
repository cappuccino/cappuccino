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

var _CPLevelIndicatorBezelColor = nil,
    _CPLevelIndicatorSegmentEmptyColor = nil,
    _CPLevelIndicatorSegmentNormalColor = nil,
    _CPLevelIndicatorSegmentWarningColor = nil,
    _CPLevelIndicatorSegmentCriticalColor = nil,

    _CPLevelIndicatorSpacing = 1;

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
}

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:CPLevelIndicator];

    _CPLevelIndicatorBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-bezel-left.png"] size:CGSizeMake(3.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-bezel-center.png"] size:CGSizeMake(1.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-bezel-right.png"] size:CGSizeMake(3.0, 18.0)]
        ]
        isVertical:NO
    ]];

    _CPLevelIndicatorSegmentEmptyColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-empty-left.png"] size:CGSizeMake(3.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-empty-center.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-empty-right.png"] size:CGSizeMake(3.0, 17.0)]
        ]
        isVertical:NO
    ]];

    _CPLevelIndicatorSegmentNormalColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-normal-left.png"] size:CGSizeMake(3.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-normal-center.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-normal-right.png"] size:CGSizeMake(3.0, 17.0)]
        ]
        isVertical:NO
    ]];

    _CPLevelIndicatorSegmentWarningColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-warning-left.png"] size:CGSizeMake(3.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-warning-center.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-warning-right.png"] size:CGSizeMake(3.0, 17.0)]
        ]
        isVertical:NO
    ]];

    _CPLevelIndicatorSegmentCriticalColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-critical-left.png"] size:CGSizeMake(3.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-critical-center.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPLevelIndicator/level-indicator-segment-critical-right.png"] size:CGSizeMake(3.0, 17.0)]
        ]
        isVertical:NO
    ]];
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

        [self _init];
    }

    return self;
}

- (void)_init
{
    // TODO Make themable and style dependent.
    [self setBackgroundColor:_CPLevelIndicatorBezelColor];
}

- (void)layoutSubviews
{
    var segmentCount = _maxValue - _minValue;

    if (segmentCount <= 0)
        return;

    var filledColor = _CPLevelIndicatorSegmentNormalColor,
        value = [self doubleValue];

    if (value < _criticalValue)
        filledColor = _CPLevelIndicatorSegmentCriticalColor;
    else if (value < _warningValue)
        filledColor = _CPLevelIndicatorSegmentWarningColor;

    for (var i = 0; i < segmentCount; i++)
    {
        var bezelView = [self layoutEphemeralSubviewNamed:"segment-bezel-" + i
                                               positioned:CPWindowAbove
                          relativeToEphemeralSubviewNamed:nil];

        [bezelView setBackgroundColor:(_minValue + i) < value ? filledColor : _CPLevelIndicatorSegmentEmptyColor];
    }
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    return [[CPView alloc] initWithFrame:_CGRectMakeZero()];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aViewName
{
    if (aViewName.indexOf("segment-bezel") === 0)
    {
        var segment = parseInt(aViewName.substring("segment-bezel-".length), 10),
            segmentCount = _maxValue - _minValue;

        if (segment >= segmentCount)
            return _CGRectMakeZero();

        var bounds = [self bounds],
            segmentWidth = FLOOR(bounds.size.width / segmentCount),
            segmentFrame = CGRectCreateCopy([self bounds]);

        segmentFrame.size.height -= 1;
        segmentFrame.origin.x = segmentWidth * segment;
        // Make the last segment use up the remaining space.
        segmentFrame.size.width = segment < segmentCount - 1 ? segmentWidth - _CPLevelIndicatorSpacing : bounds.size.width - segmentFrame.origin.x;

        return segmentFrame;
    }

    return _CGRectMakeZero();
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

        [self _init];

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
