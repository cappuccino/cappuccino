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

@class CPRuleEditor

@implementation _CPRuleEditorViewSlice : CPView
{
    CPRuleEditor _ruleEditor;
    int          _indentation           @accessors(property=indentation);
    int          _rowIndex              @accessors(property=rowIndex);
    CGRect       _animationTargetRect   @accessors(property=_animationTargetRect);
    BOOL         _selected              @accessors(getter=_isSelected, setter=_setSelected:);
    BOOL         _lastSelected          @accessors(getter=_isLastSelected, setter=_setLastSelected:);
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

- (void)setRowIndex:(int)anIndex
{
    _rowIndex = anIndex;
    [self _updateBackgroundColor];
    [self setNeedsDisplay:YES];
}

- (void)_setSelected:(BOOL)select
{
    if (select == _selected)
        return;

    var selector = select ? @selector(setThemeState:) : @selector(unsetThemeState:);
    [[self subviews] makeObjectsPerformSelector:selector  withObject:CPThemeStateSelectedDataView];
    _selected = select;
    
    [self _updateBackgroundColor];
    [self setNeedsDisplay:YES];
}

- (void)_updateBackgroundColor
{
    var color = nil;

    if ([self _isSelected])
    {
        color = [_ruleEditor _selectedRowColor];
    }
    else
    {
        var colors = [_ruleEditor _backgroundColors],
            count = [colors count];
        
        if (count > 0)
            color = [colors objectAtIndex:(_rowIndex % count)];
    }

    [self setBackgroundColor:color];
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    [self _updateBackgroundColor];
}

- (void)setThemeState:(CPThemeState)aState
{
    [super setThemeState:aState];
    [self _updateBackgroundColor];
}

- (void)unsetThemeState:(CPThemeState)aState
{
    [super unsetThemeState:aState];
    [self _updateBackgroundColor];
}

- (void)drawRect:(CGRect)rect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds  = [self bounds],
        maxX    = CGRectGetWidth(bounds),
        maxY    = CGRectGetHeight(bounds);

    // Note: Background is now handled by setBackgroundColor in _updateBackgroundColor
    // to support CSS-based colors and transparency correctly.

    // Draw Top Border
    var topColor = [_ruleEditor _sliceTopBorderColor];
    if (topColor)
    {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, maxX, 0);
        CGContextSetStrokeColor(context, topColor);
        CGContextStrokePath(context);
    }

    // Draw Bottom Border
    var bottomColor = (_rowIndex == [_ruleEditor _lastRow]) ? [_ruleEditor _sliceLastBottomBorderColor] : [_ruleEditor _sliceBottomBorderColor];

    if (bottomColor)
    {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, maxY);
        CGContextAddLineToPoint(context, maxX, maxY);
        CGContextSetStrokeColor(context, bottomColor);
        CGContextStrokePath(context);
    }
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
