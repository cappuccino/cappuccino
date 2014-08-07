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

@import "CPPopUpButton.j"

@class _CPRuleEditorViewSlice

@implementation _CPRuleEditorPopUpButton : CPPopUpButton
{
    CPInteger radius;
}

- (CPView)hitTest:(CGPoint)point
{
    if (!CGRectContainsPoint([self frame], point) || ![self sliceIsEditable])
        return nil;

    return self;
}

- (BOOL)sliceIsEditable
{
    var superview = [self superview];
    return ![superview isKindOfClass:[_CPRuleEditorViewSlice]] || [superview isEditable];
}

- (void)trackMouse:(CPEvent)theEvent
{
    if (![self sliceIsEditable])
        return;

    [super trackMouse:theEvent];
}

@end
