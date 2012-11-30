/*
 * CPMatrix.j
 * AppKit
 *
 * Created by Martin Carlberg.
 * Copyright 2012, Martin Carlberg.
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

@import <Foundation/CPObject.j>

@import "CPControl.j"


/*!
    @ingroup appkit

    This class only implements a very simple Full Keyboard Access for
    radio buttons. All other radio group functionality is implemented
    in the CPRadioGroup class
*/

@implementation CPMatrix : CPControl
{
}

- (BOOL)becomeFirstResponder
{
    [self setupNextAndPreviousKeyView];
    var becomeFirst = [super becomeFirstResponder];

    if (becomeFirst)
    {
        var subviews = [self subviews];

        if ([subviews count])
        {
            var firstCell = [subviews objectAtIndex:0],
                radioGroup = [firstCell radioGroup];

            if (radioGroup)
            {
                firstCell = [radioGroup selectedRadio];
            }
            window.setTimeout(function()
            {
                [[firstCell window] makeFirstResponder:firstCell];
            }, 0);
        }
    }

    return becomeFirst;
}

- (void)setupNextAndPreviousKeyView
{
    var subviews = [self subviews],
        subviewSize = [subviews count];

    for (var i = 0; i < subviewSize; i++)
    {
        var subview = [subviews objectAtIndex:i];
        subview._nextKeyView = [self nextKeyView];
        subview._previousKeyView = [self previousKeyView];
    }
}

- (void)selectNextCell:(CPView)currentCell
{
    var cells = [self subviews],
        indexOfCell = [cells indexOfObject:currentCell];

    if (++indexOfCell === [cells count])
        indexOfCell = 0;

    [[self window] makeFirstResponder:[cells objectAtIndex:indexOfCell]];
}

- (void)selectPreviousCell:(CPView)currentCell
{
    var cells = [self subviews],
        indexOfCell = [cells indexOfObject:currentCell];

    if (!indexOfCell)
        indexOfCell = [cells count];

    [[self window] makeFirstResponder:[cells objectAtIndex:--indexOfCell]];
}

- (CPRadio)selectedRadio
{
    var cells = [self subviews];
    return [cells count] ? [[[cells objectAtIndex:0] radioGroup] selectedRadio] : nil;
}

/*!
An CPMatrix object adds to the target-action paradigm implemented by its subviews by maintaining its own target and action in addition to the targets and actions of its subviews. A matrix's target and action are used if one of its subviews doesn't have a target or action set. This design allows for common usage patterns, including the following:

If none of the subviews of the CPMatrix object has either target or action set, the target and action of the CPMatrix object is always used.
If only the actions of each of the subviews is set, they share the target specified by their CPMatrix object, but send different messages to it.
If only the targets of each of the subviews is set, they all send the action message specified by the NSMatrix object, but to different targets.

This is the exact same behaviour as Cocoa has on Mac OS X.
*/
- (void)sendAction:(SEL)theAction to:(id)theTarget
{
    if (theAction)
        if (theTarget)
            [super sendAction:theAction to:theTarget];
        else
            [super sendAction:theAction to:_target];
    else
        [super sendAction:_action to:_target];
}

@end
