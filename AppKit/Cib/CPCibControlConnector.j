/*
 * CPCibControlConnector.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "CPCibConnector.j"


@implementation CPCibControlConnector : CPCibConnector
{
}

- (void)establishConnection
{
    var selectorName = _label,
        selectorNameLength = [selectorName length];

    if (selectorNameLength && selectorName.charAt(selectorNameLength - 1) !== ':')
        selectorName += ':';

    var selector = CPSelectorFromString(selectorName);

    // Not having a selector is a fatal error.
    if (!selector)
    {
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] selector "  + selectorName + @" does not exist."];
    }

    // If the destination doesn't respond to this selector, warn but don't die.
    if (_destination && ![_destination respondsToSelector:selector])
        CPLog.warn(@"Could not connect the action " + selector + @" to target of class " + [_destination className]);

    // Not being able to set the action is a fatal error.
    if ([_source respondsToSelector:@selector(setAction:)])
        [_source setAction:selector];

    else
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] " + [_source description] + @" does not respond to setAction:"];

    // Not being able to set the target is a fatal error.
    if ([_source respondsToSelector:@selector(setTarget:)])
        [_source setTarget:_destination];

    else
        [CPException
            raise:CPInvalidArgumentException
           reason:@"-[" + [self className] + ' ' + _cmd + @"] " + [_source description] + @" does not respond to setTarget:"];
}

@end

@implementation _CPCibControlConnector : CPCibControlConnector
{
}

@end

