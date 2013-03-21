/*
 * Created by cacaodev@gmail.com.
 * Copyright (c) 2011 Pear, Inc. All rights reserved.
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

@import "CPView.j"

@implementation _CPRuleEditorViewSlice : CPView
{
    CPRuleEditor _ruleEditor;
    int          _indentation           @accessors(property=indentation);
    int          _rowIndex              @accessors(property=rowIndex);
    CGRect       _animationTargetRect   @accessors(property=_animationTargetRect);
    BOOL         _selected              @accessors(getter=_isSelected, setter=_setSelected:);
    BOOL         _lastSelected          @accessors(getter=_isLastSelected, setter=_setLastSelected:);
    CPColor      _backgroundColor       @accessors(property=backgroundColor);
    BOOL         _editable              @accessors(getter=isEditable, setter=setEditable:);
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

    var selector = select ? @selector(setThemeState:) : @selector(unsetThemeState:);
    [[self subviews] makeObjectsPerformSelector:selector  withObject:CPThemeStateSelectedDataView];
    _selected = select;
}

- (void)drawRect:(CGRect)rect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        maxX = CGRectGetWidth(bounds),
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
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, maxX, 0);
    CGContextSetStrokeColor(context, [_ruleEditor _sliceTopBorderColor]);
    CGContextStrokePath(context);

    // Draw Bottom Border
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, maxY);
    CGContextAddLineToPoint(context, maxX, maxY);

    var bottomColor = (_rowIndex == [_ruleEditor _lastRow]) ? [_ruleEditor _sliceLastBottomBorderColor] : [_ruleEditor _sliceBottomBorderColor];

    CGContextSetStrokeColor(context, bottomColor);
    CGContextStrokePath(context);
}

- (void)mouseDown:(CPEvent)theEvent
{
    if (_editable)
        [_ruleEditor _mouseDownOnSlice:self withEvent:theEvent];
}

- (void)mouseUp:(CPEvent)theEvent
{
    if (_editable)
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
