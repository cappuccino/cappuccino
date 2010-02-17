
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
    var eventListenersForEventName = this._eventListenersForEventNames[anEventName];

    if (!eventListenersForEventName)
    {
        eventListenersForEventName = [];
        this._eventListenersForEventNames[anEventName] = eventListenersForEventName;
    }

    var index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return;  

    eventListenersForEventName.push(anEventListener);        
}

EventDispatcher.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventName = this._eventListenersForEventNames[anEventName];

    if (!eventListenersForEventName)
        return;

    var index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return eventListenersForEventName.splice(index, 1);       
}

EventDispatcher.prototype.dispatchEvent = function(/*Event*/ anEvent)
{
    var type = anEvent.type,
        eventListenersForEventName = this._eventListenersForEventNames[type];

    if (eventListenersForEventName)
    {
        var index = 0,
            count = eventListenersForEventName.length;
    
        for (; index < count; ++index)
            eventListenersForEventName[index](anEvent);
    }

    var manual = (this._owner || this)["on" + type];

    if (manual)
        manual(anEvent);
}
