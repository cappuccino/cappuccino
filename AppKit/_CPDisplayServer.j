/*
 * _CPDisplayServer.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPRunLoop.j>

PREPARE_DOM_OPTIMIZATION();

var displayObjects      = [],
    displayObjectsByUID = { },

    layoutObjects       = [],
    layoutObjectsByUID  = { },

    runLoop             = [CPRunLoop mainRunLoop];

function _CPDisplayServerAddDisplayObject(anObject)
{
    var UID = [anObject UID];

    if (typeof displayObjectsByUID[UID] !== "undefined")
        return;

    var index = displayObjects.length;

    displayObjectsByUID[UID] = index;
    displayObjects[index] = anObject;
}

function _CPDisplayServerAddLayoutObject(anObject)
{
    var UID = [anObject UID];

    if (typeof layoutObjectsByUID[UID] !== "undefined")
        return;

    var index = layoutObjects.length;

    layoutObjectsByUID[UID] = index;
    layoutObjects[index] = anObject;
}

@implementation _CPDisplayServer : CPObject
{
}

+ (void)run
{
    while (layoutObjects.length || displayObjects.length)
    {
        var index = 0;

        for (; index < layoutObjects.length; ++index)
        {
            var object = layoutObjects[index];

            delete layoutObjectsByUID[[object UID]];
            [object layoutIfNeeded];
        }

        layoutObjects = [];
        layoutObjectsByUID = { };

        index = 0;

        for (; index < displayObjects.length; ++index)
        {
            if (layoutObjects.length)
                break;

            var object = displayObjects[index];

            delete displayObjectsByUID[[object UID]];
            [object displayIfNeeded];
        }

        if (index === displayObjects.length)
        {
            displayObjects = [];
            displayObjectsByUID = { };
        }
        else
            displayObjects.splice(0, index);
    }

    [runLoop performSelector:@selector(run) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
}

@end

[_CPDisplayServer run];
