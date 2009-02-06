
@import "CPControl.j"
@import "CPThemedValue.j"

#include "CoreGraphics/CGGeometry.h"
#include "CPThemedValue.h"


@implementation CPSlider : CPControl
{
    double  _minValue;
    double  _maxValue;
    double  _altIncrementValue;
    
    CPThemedValue   _verticalTrackColor;    // vertical-track-color
    CPThemedValue   _horizontalTrackColor;  // horizontal-track-color
    
    CPThemedValue   _knobColor;
    
    CPThemedValue   _trackWidth;            // track-width
    CPThemedValue   _knobSize;              // knob-size
    
    CPView  _trackView;
    CPView  _knobView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _minValue = 0.0;
        _maxValue = 100.0;
        
        var theme = [self theme],
            theClass = [self class];
        
        _knobColor = CPThemedValueMake(nil, "knob-color", theme, theClass);
        _knobSize = CPThemedValueMake(_CGSizeMakeZero(), "knob-size", theme, theClass);
        
        _trackWidth = CPThemedValueMake(0.0, "track-width", theme, theClass);
        _verticalTrackColor = CPThemedValueMake(nil, "vertical-track-color", theme, theClass);
        _horizontalTrackColor = CPThemedValueMake(nil, "horizonal-track-color", theme, theClass);
        
        [self setObjectValue:50.0];
        
        [self setContinuous:YES];
    }
    
    return self;
}

- (void)setMinValue:(float)aMinimumValue
{
    if (_minValue === aMinimumValue)
        return;
    
    _minValue = aMinimumValue;

    var doubleValue = [self doubleValue];
    
    if (doubleValue < _minValue)
        [self setDoubleValue:_minValue];
}

- (float)minValue
{
    return _minValue;
}

- (void)setMaxValue:(float)aMaximumValue
{
    if (_maxValue === aMaximumValue)
        return;
    
    _maxValue = aMaximumValue;
    
    var doubleValue = [self doubleValue];
    
    if (doubleValue > _maxValue)
        [self setDoubleValue:_maxValue];
}

- (float)maxValue
{
    return _maxValue;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:MIN(MAX(aValue, _minValue), _maxValue)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    var trackWidth = [self currentTrackWidth];
    
    if (trackWidth <= 0)
        return _CGRectMakeZero();
    
    if ([self isVertical])
    {
        bounds.origin.x = (_CGRectGetWidth(bounds) - trackWidth) / 2.0;
        bounds.size.width = trackWidth;
    }
    else
    {
        bounds.origin.y = (_CGRectGetHeight(bounds) - trackWidth) / 2.0;
        bounds.size.height = trackWidth;
    }
    
    return bounds;
}

THEMED_STATED_VALUE(KnobColor, knobColor)
THEMED_STATED_VALUE(KnobSize, knobSize)
THEMED_STATED_VALUE(TrackWidth, trackWidth)
THEMED_STATED_VALUE(HorizontalTrackColor, horizontalTrackColor)
THEMED_STATED_VALUE(VerticalTrackColor, verticalTrackColor)

- (CGRect)knobRectForBounds:(CGRect)bounds
{
    var knobSize = [self currentKnobSize];
    
    if (knobSize.width <= 0 || knobSize.height <= 0)
        return _CGRectMakeZero();
    
    var knobRect = _CGRectMake(0.0, 0.0, knobSize.width, knobSize.height),
        trackRect = [self trackRectForBounds:bounds];
    
    // No track, do our best to approximate a place for this thing.
    if (!trackRect || _CGRectIsEmpty(trackRect))
        trackRect = bounds;

    if ([self isVertical])
    {
        knobRect.origin.x = _CGRectGetMidX(trackRect) - knobSize.width / 2.0; 
        knobRect.origin.y = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetHeight(trackRect) - knobSize.height);
    }
    else
    {
        knobRect.origin.x = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetWidth(trackRect) - knobSize.width);
        knobRect.origin.y = _CGRectGetMidY(trackRect) - knobSize.height / 2.0;   
    }
    
    return knobRect;
}

- (int)isVertical
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);
    
    return width < height ? 1 : (width > height ? 0 : -1);
}

- (CPView)createTrackView
{
    var trackView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
            
    [trackView setHitTests:NO];

    return trackView;
}

- (CPView)createKnobView
{
    var knobView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [knobView setHitTests:NO];
    
    return knobView;
}

- (void)layoutSubviews
{
    var bounds = [self bounds],
        isVertical = [self isVertical],
        trackRect = nil;

    if ((trackRect = [self trackRectForBounds:_CGRectMakeCopy(bounds)]) && !_CGRectIsEmpty(trackRect))
    {
        if (!_trackView)
        {
            _trackView = [self createTrackView];
            
            if (_trackView)
                [self addSubview:_trackView positioned:CPWindowBelow relativeTo:_knobView];
        }
        
        if (_trackView)
        {
            [_trackView setFrame:trackRect];        
            
            if ([self isVertical])
            {
                if (_verticalTrackColor)
                    [_trackView setBackgroundColor:[self currentVerticalTrackColor]];
            }
            else
            {
                if (_horizontalTrackColor)
                    [_trackView setBackgroundColor:[self currentHorizontalTrackColor]];
            }
        }
    }
    else if (_trackView)
    {
        [_trackView removeFromSuperview];
        
        _trackView = nil;
    }
    
    var knobRect = nil;
    
    if ((knobRect = [self knobRectForBounds:bounds]) && !_CGRectIsEmpty(knobRect))
    {
        if (!_knobView)
        {
            _knobView = [self createKnobView];
            
            if (_knobView)
                [self addSubview:_knobView positioned:CPWindowAbove relativeTo:_trackView];
        }
        
        if (_knobView)
        {        
            [_knobView setFrame:knobRect];
          
            var knobColor = [self currentKnobColor];
            
            if (knobColor)
                [_knobView setBackgroundColor:knobColor];
        }
    }
    else if (_knobView)
    {
        [_knobView removeFromSuperview];
        
        _knobView = nil;
    }
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (float)_valueAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:bounds],
        trackRect = [self trackRectForBounds:bounds];

    if ([self isVertical])
    {
        var knobHeight = _CGRectGetHeight(knobRect);
        
        trackRect.origin.y += knobHeight / 2;
        trackRect.size.height -= knobHeight;
        
        var minValue = [self minValue];
        
        return MAX(0.0, MIN(1.0, (aPoint.y - _CGRectGetMinY(trackRect)) / _CGRectGetHeight(trackRect))) * ([self maxValue] - minValue) + minValue;
    }
    else

    var knobWidth = _CGRectGetWidth(knobRect);
    
    trackRect.origin.x += knobWidth / 2;
    trackRect.size.width -= knobWidth;
    
    var minValue = [self minValue];
    
    return MAX(0.0, MIN(1.0, (aPoint.x - _CGRectGetMinX(trackRect)) / _CGRectGetWidth(trackRect))) * ([self maxValue] - minValue) + minValue;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:_CGRectMakeCopy(bounds)];
    
    if (_CGRectContainsPoint(knobRect, aPoint))
        _dragOffset = _CGSizeMake(_CGRectGetMidX(knobRect) - aPoint.x, _CGRectGetMidY(knobRect) - aPoint.y);
    
    else 
    {
        var trackRect = [self trackRectForBounds:bounds];
        
        if (trackRect && _CGRectContainsPoint(trackRect, aPoint))
        {
            _dragOffset = _CGSizeMakeZero();
            
            [self setObjectValue:[self _valueAtPoint:aPoint]];
        }
    
        else
            return NO;
    }
    
    [self setHighlighted:YES];
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
    
    return YES;   
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self setObjectValue:[self _valueAtPoint:_CGPointMake(aPoint.x + _dragOffset.width, aPoint.y + _dragOffset.height)]];
    
    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self setHighlighted:NO];
    
    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
    shoudl we have _continuous?
*/
- (void)setContinuous:(BOOL)flag
{
    if (flag)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else 
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

@end

@implementation CPSlider (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    if (!theme)
        return;
    
    [_knobColor setTheme:theme];
    [_knobSize setTheme:theme];
    
    [_trackWidth setTheme:theme];
    [_horizontalTrackColor setTheme:theme];
    [_verticalTrackColor setTheme:theme];
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues];
    
    [values setObject:_knobSize forKey:@"knob-size"];
    [values setObject:_knobColor forKey:@"knob-color"];
    [values setObject:_trackWidth forKey:@"track-width"];
    [values setObject:_verticalTrackColor forKey:@"vertical-track-color"];
    [values setObject:_horizontalTrackColor forKey:@"horizontal-track-color"];

    return values;
}

@end

var CPSliderMinValueKey             = "CPSliderMinValueKey",
    CPSliderMaxValueKey             = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey         = "CPSliderAltIncrValueKey",
    
    CPSliderKnobColorKey            = "CPSliderKnobColorKey",
    CPSliderKnobSizeKey             = "CPSliderKnobSizeKey";
    CPSliderTrackWidthKey           = "CPSliderTrackWidthKey";
    CPSliderHorizontalTrackColorKey = "CPSliderHorizontalTrackColorKey";
    CPSliderVerticalTrackColorKey   = "CPSliderVerticalTrackColorKey";

@implementation CPSlider (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
        _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];
        _altIncrementValue = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];
    
        var theme = [self theme],
            theClass = [self class];
    
        _knobColor = CPThemedValueDecode(aCoder, CPSliderKnobColorKey, nil, "knob-color", theme, theClass);
        _knobSize = CPThemedValueDecode(aCoder, CPSliderKnobSizeKey, nil, "knob-size", theme, theClass);

        _trackWidth = CPThemedValueDecode(aCoder, CPSliderKnobColorKey, nil, "track-width", theme, theClass);
        _horizontalTrackColor = CPThemedValueDecode(aCoder, CPSliderHorizontalTrackColorKey, nil, "horizontal-track-color", theme, theClass);
        _verticalTrackColor = CPThemedValueDecode(aCoder, CPSliderVerticalTrackColorKey, nil, "vertical-track-color", theme, theClass);
        
        [self setContinuous:YES];
        
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    /*
    var count = [_subviews count],
        subviews = nil;
    
    if (count)
    {
        subviews = _subviews;
            
        if (count === 2 && _trackView && _knobView)
            _subviews = [];
        else
        {
            if (_trackView)
                [_subviews removeObjectIdenticalTo:_trackView];
            if (_knobView)
                [_subviews removeObjectIdenticalTo:_knobView];
        }
    }*/
    
    [super encodeWithCoder:aCoder];
    
//    _subviews = subviews;
    
    [aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue forKey:CPSliderAltIncrValueKey];
    
    CPThemedValueEncode(aCoder, CPSliderKnobColorKey, _knobColor);
    CPThemedValueEncode(aCoder, CPSliderKnobSizeKey, _knobSize);

    CPThemedValueEncode(aCoder, CPSliderTrackWidthKey, _trackWidth);
    CPThemedValueEncode(aCoder, CPSliderHorizontalTrackColorKey, _horizontalTrackColor);
    CPThemedValueEncode(aCoder, CPSliderVerticalTrackColorKey, _verticalTrackColor);
}

@end

@implementation CPSlider (Deprecated)

- (id)value
{
    CPLog.warn("[CPSlider value] is deprecated, use doubleValue or objectValue instead.");
    
    return [self doubleValue];    
}

- (void)setValue:(id)aValue
{
    CPLog.warn("[CPSlider setValue:] is deprecated, use setDoubleValue: or setObjectValue: instead.");
    
    [self setObjectValue:aValue];
}

@end
