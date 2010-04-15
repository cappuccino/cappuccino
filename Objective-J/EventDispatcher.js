/*
 * EventDispatcher.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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

function EventDispatcher(/*Object*/ anOwner)
{
    this._eventListenersForEventNames = { };
    this._owner = anOwner;
}

EventDispatcher.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;

    if (!hasOwnProperty.call(eventListenersForEventNames, anEventName))
    {
        var eventListenersForEventName = [];
        eventListenersForEventNames[anEventName] = eventListenersForEventName;
    }
    else
        var eventListenersForEventName = eventListenersForEventNames[anEventName];

    var index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return;

    eventListenersForEventName.push(anEventListener);
}

EventDispatcher.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;

    if (!hasOwnProperty.call(eventListenersForEventNames, anEventName))
        return;

    var eventListenersForEventName = eventListenersForEventNames[anEventName],
        index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return eventListenersForEventName.splice(index, 1);
}

EventDispatcher.prototype.dispatchEvent = function(/*Event*/ anEvent)
{
    var type = anEvent.type,
        eventListenersForEventNames = this._eventListenersForEventNames;

    if (hasOwnProperty.call(eventListenersForEventNames, type))
    {
        var eventListenersForEventName = this._eventListenersForEventNames[type],
            index = 0,
            count = eventListenersForEventName.length;

        for (; index < count; ++index)
            eventListenersForEventName[index](anEvent);
    }

    var manual = (this._owner || this)["on" + type];

    if (manual)
        manual(anEvent);
}
