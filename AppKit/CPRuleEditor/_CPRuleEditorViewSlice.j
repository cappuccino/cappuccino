/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

@implementation _CPRuleEditorViewSlice : CPView
{
    CPRuleEditor _ruleEditor;
    int          _indentation           @accessors(property=indentation);
    int          _rowIndex              @accessors(property=rowIndex);
    CPRect       _animationTargetRect   @accessors(property=_animationTargetRect);
    BOOL         _selected              @accessors(getter=_isSelected, setter=_setSelected:);
    BOOL         _lastSelected          @accessors(getter=_isLastSelected, setter=_setLastSelected:);
    CPColor      _backgroundColor       @accessors(property=backgroundColor);
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
}

- (id)initWithFrame:(CGRect)frame ruleEditorView:(id)editor
{
    if (self = [super initWithFrame:frame])
    {
        _ruleEditor = editor;
        _selected = NO;
        _lastSelected = NO;
    }

    return self;
}

- (void)_setSelected:(BOOL)select
{
    if (select == _selected)
        return;

    var selector = select ? @"setThemeState:" : @"unsetThemeState:";
    [[self subviews] makeObjectsPerformSelector:CPSelectorFromString(selector)  withObject:CPThemeStateSelectedDataView];
    _selected = select;
}

- (void)drawRect:(CPRect)rect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        maxX = CGRectGetWidth(bounds) - 2,
        maxY = CGRectGetHeight(bounds);

// Draw background
    if ([self _isSelected])
        _backgroundColor = [_ruleEditor _selectedRowColor];
    else
    {
        var colors = [_ruleEditor _backgroundColors],
            count = [colors count];
        _backgroundColor = [colors objectAtIndex:(_rowIndex % count)];
    }

    CGContextSetFillColor(context, _backgroundColor);
    CGContextFillRect(context, rect);

// Draw Top Border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 1, 0);
    CGContextAddLineToPoint(context, maxX, 0);
    CGContextClosePath(context);
    CGContextSetStrokeColor(context, [_ruleEditor _sliceTopBorderColor]);
    CGContextStrokePath(context);

// Draw Bottom Border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 1, maxY - 0.5);
    CGContextAddLineToPoint(context, maxX, maxY - 0.5);
    CGContextClosePath(context);
    var bottomColor = (_rowIndex == [_ruleEditor _lastRow]) ? [_ruleEditor _sliceLastBottomBorderColor] : [_ruleEditor _sliceBottomBorderColor];
    CGContextSetStrokeColor(context, bottomColor);
    CGContextStrokePath(context);
}

- (void)mouseDown:(CPEvent)theEvent
{
    if (editable)
        [_ruleEditor _mouseDownOnSlice:self withEvent:theEvent];
}

- (void)mouseUp:(CPEvent)theEvent
{
    if (editable)
        [_ruleEditor _mouseUpOnSlice:self withEvent:theEvent];
}

/*
- (void)rightMouseDown:(CPEvent)theEvent
{
    [_ruleEditor _rightMouseDownOnSlice:self withEvent:theEvent];
}
*/

// =========
// ! DEBUG
// =========
- (CPString)description
{
    return [CPString stringWithFormat:@"<%@ %p index:%d indentation:%d>",[self className],self,[self rowIndex],[self indentation]];
}

@end