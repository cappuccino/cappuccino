
function Event(/*String*/ aType)
{
    this.type = aType;
}

function EventDispatcher(/*Object*/ anOwner)
{
    this._eventListenersForEventNames = { };
    this._owner = anOwner;
}

EventDispatcher.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;

    if (!hasOwnProperty.call(this._eventListenersForEventNames, anEventName))
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

    var eventListenersForEventName = eventListenersForEventNames[anEventName].
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
