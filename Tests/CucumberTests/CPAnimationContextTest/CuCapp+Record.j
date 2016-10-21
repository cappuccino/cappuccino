@import <AppKit/CPApplication.j>

function start_record(path)
{
    [CPWindow start_record];
}

function stop_record()
{
    [CPWindow stop_record];
}

function save_record(fileName)
{
    if (!fileName)
        fileName = @"record"

    var eventRecords =  [CPWindow eventRecords],
        JSONEvents = [];

    for (var i = 0; i < [eventRecords count]; i++)
    {
        var eventRecord = eventRecords[i];
        [JSONEvents addObject:[eventRecord objectToJSON]];
    }

    var pom = document.createElement('a');
    pom.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(JSON.stringify(JSONEvents, null, 4)));
    pom.setAttribute('download', fileName + ".json");
    pom.click();
}

function play_record(file_name, cucumber_path)
{
    if (!cucumber_path)
        cucumber_path = path = "../../Cucapp/lib/Cucumber.j";

    load_cucapp_CLI(cucumber_path);

    setTimeout(function(){
        _load_javascript_file(file_name)
    },1000);
}

function _load_javascript_file(file_name)
{
    var AJAX_req = new XMLHttpRequest();
    AJAX_req.open( "GET", file_name, true );
    AJAX_req.setRequestHeader("Content-type", "application/json");

    AJAX_req.onreadystatechange = function()
    {
        if (AJAX_req.readyState == 4)
        {
            var recordingEvents = JSON.parse(AJAX_req.responseText);

            for (var i = 0; i < [recordingEvents count]; i++)
            {
                var recordingEvent = JSON.parse(recordingEvents[i]),
                    type = recordingEvent["event"]["type"];

                if (type == CPLeftMouseDown && i < [recordingEvents count] - 1)
                {
                    var nextRecordingEvent = JSON.parse(recordingEvents[i + 1]),
                        nextType = nextRecordingEvent["event"]["type"];

                    if (nextType == CPMouseMoved)
                    {
                        for (var j = i; j < [recordingEvents count]; j++)
                        {
                            var tmpRecordingEvent = JSON.parse(recordingEvents[j]),
                                tmpType = tmpRecordingEvent["event"]["type"];

                            if (tmpType == CPLeftMouseUp)
                            {
                                setTimeout(_simulate_drag_event, recordingEvent["event"]["timestamp"] * 1000, recordingEvent, tmpRecordingEvent);
                                i = j;
                                break;
                            }
                        }

                        continue;
                    }
                }

                setTimeout(_simulate_event, recordingEvent["event"]["timestamp"] * 1000, recordingEvent);
            }
        }
    }

    AJAX_req.send();
}

function _simulate_drag_event(event1, event2)
{
    var keyView1 = event1["keyView"],
        valueView1 = event1["valueView"],
        keyView2 = event2["keyView"],
        valueView2 = event2["valueView"],
        locationInWindow1 = CGPointMake(event1["event"]["locationInWindow"]["x"], event1["event"]["locationInWindow"]["y"]);
        locationInWindow2 = CGPointMake(event2["event"]["locationInWindow"]["x"], event2["event"]["locationInWindow"]["y"]);

        if (keyView1 && valueView1 && keyView2 && valueView2)
            simulate_dragged_click_view_to_view(keyView1, valueView1, keyView2, valueView2);
        else if (keyView1 && valueView1)
            simulate_dragged_click_view_to_point(keyView1, valueView1, locationInWindow1.x, locationInWindow1.y);
        else
            simulate_dragged_click_point_to_point(locationInWindow1.x, locationInWindow1.y, locationInWindow2.x, locationInWindow2.y);
}

function _simulate_event(event)
{
    var type = event["event"]["type"],
        keyView = event["keyView"],
        valueView = event["valueView"],
        characters = event["event"]["characters"],
        deltaX = event["event"]["deltaX"],
        deltaY = event["event"]["deltaY"],
        deltaZ = event["event"]["deltaZ"],
        deltaZ = event["event"]["deltaZ"],
        locationInWindow = CGPointMake(event["event"]["locationInWindow"]["x"], event["event"]["locationInWindow"]["y"]);

    switch (type)
    {
        case CPScrollWheel:

            if (keyView && valueView)
                simulate_scroll_wheel_on_view(keyView, valueView, deltaX, deltaY)

            break;

        case CPLeftMouseDown:

            if (keyView && valueView)
                simulate_left_click_on_view(keyView, valueView);
            else
                simulate_left_click_on_point(locationInWindow.x, locationInWindow.y)

            break;

        case CPRightMouseDown:

            if (keyView && valueView)
                simulate_right_click_on_view(keyView, valueView);
            else
                simulate_right_click_on_point(locationInWindow.x, locationInWindow.y)

            break;

        case CPKeyDown:
            simulate_keyboard_event(characters);
            break;
    }
}


var eventRecords,
    recording = NO;

@implementation CPWindow (cucappRecord)

+ (CPArray)eventRecords
{
    return eventRecords;
}

+ (void)start_record
{
    eventRecords = [];
    recording = YES;
}

+ (void)stop_record
{
    recording = NO;
}

/*!
    Dispatches events that are sent to it from CPApplication.
    @param anEvent the event to be dispatched
*/
- (void)sendEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        sheet = [self attachedSheet],
        recordingEvent = [[RecordingEvent alloc] initWithEvent:anEvent];

    if (recordingEvent && type != CPFlagsChanged && type != CPMouseMoved)
        [eventRecords addObject:recordingEvent];

    // If a sheet is attached events get filtered here.
    // It is not clear what events should be passed to the view, perhaps all?
    // CPLeftMouseDown is needed for window moving and resizing to work.
    // CPMouseMoved is needed for rollover effects on title bar buttons.

    if (sheet)
    {
        switch (type)
        {
            case CPLeftMouseDown:

                // This is needed when a doubleClick occurs when the sheet is closing or opening
                if (!_parentWindow)
                    return;

                [recordingEvent setView:_windowView];

                [_windowView mouseDown:anEvent];

                // -dw- if the window is clicked, the sheet should come to front, and become key,
                // and the window should be immediately behind
                [sheet makeKeyAndOrderFront:self];

                return;

            case CPMouseMoved:
                // Allow these through to the parent
                break;

            default:
                // Everything else is filtered
                return;
        }
    }

    var point = [anEvent locationInWindow];

    switch (type)
    {
        case CPFlagsChanged:
            return [[self firstResponder] flagsChanged:anEvent];

        case CPKeyUp:
            return [[self firstResponder] keyUp:anEvent];

        case CPKeyDown:
            if ([anEvent charactersIgnoringModifiers] === CPTabCharacter)
            {
                if ([anEvent modifierFlags] & CPShiftKeyMask)
                    [self selectPreviousKeyView:self];
                else
                    [self selectNextKeyView:self];

                // Make sure the browser doesn't try to do its own tab handling.
                // This is important or the browser might blur the shared text field or token field input field,
                // even that we just moved it to a new first responder.
                [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO]
                return;
            }
            else if ([anEvent charactersIgnoringModifiers] === CPBackTabCharacter)
            {
                var didTabBack = [self selectPreviousKeyView:self];

                if (didTabBack)
                {
                    // Make sure the browser doesn't try to do its own tab handling.
                    // This is important or the browser might blur the shared text field or token field input field,
                    // even that we just moved it to a new first responder.
                    [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO]
                }
                return didTabBack;
            }
            else if ([anEvent charactersIgnoringModifiers] == CPEscapeFunctionKey && [self _processKeyboardUIKey:anEvent])
            {
                return;
            }

            [[self firstResponder] keyDown:anEvent];

            // Trigger the default button if needed
            // FIXME: Is this only applicable in a sheet? See isse: #722.
            if (![self disableKeyEquivalentForDefaultButton])
            {
                var defaultButton = [self defaultButton],
                    keyEquivalent = [defaultButton keyEquivalent],
                    modifierMask = [defaultButton keyEquivalentModifierMask];

                if ([anEvent _triggersKeyEquivalent:keyEquivalent withModifierMask:modifierMask])
                    [[self defaultButton] performClick:self];
            }

            return;

        case CPScrollWheel:
            [recordingEvent setView:[_windowView hitTest:point]];

            return [[_windowView hitTest:point] scrollWheel:anEvent];

        case CPLeftMouseUp:
        case CPRightMouseUp:
            var hitTestedView = _leftMouseDownView,
                selector = type == CPRightMouseUp ? @selector(rightMouseUp:) : @selector(mouseUp:);

            if (!hitTestedView)
                hitTestedView = [_windowView hitTest:point];

            [recordingEvent setView:hitTestedView];

            [hitTestedView performSelector:selector withObject:anEvent];

            _leftMouseDownView = nil;

            return;

        case CPLeftMouseDown:
        case CPRightMouseDown:
            // This will return _windowView if it is within a resize region
            _leftMouseDownView = [_windowView hitTest:point];

            [recordingEvent setView:_leftMouseDownView];

            if (_leftMouseDownView !== _firstResponder && [_leftMouseDownView acceptsFirstResponder])
                [self makeFirstResponder:_leftMouseDownView];

            [CPApp activateIgnoringOtherApps:YES];

            var theWindow = [anEvent window],
                selector = type == CPRightMouseDown ? @selector(rightMouseDown:) : @selector(mouseDown:);

            if ([theWindow isKeyWindow] || ([theWindow becomesKeyOnlyIfNeeded] && ![_leftMouseDownView needsPanelToBecomeKey]))
                return [_leftMouseDownView performSelector:selector withObject:anEvent];
            else
            {
                // FIXME: delayed ordering?
                [self makeKeyAndOrderFront:self];

                if ([_leftMouseDownView acceptsFirstMouse:anEvent])
                    return [_leftMouseDownView performSelector:selector withObject:anEvent];
            }
            break;

        case CPLeftMouseDragged:
        case CPRightMouseDragged:
            if (!_leftMouseDownView)
            {
                [recordingEvent setView:[_windowView hitTest:point]];
                return [[_windowView hitTest:point] mouseDragged:anEvent];
            }

            [recordingEvent setView:_leftMouseDownView];

            var selector;

            if (type == CPRightMouseDragged)
            {
                selector = @selector(rightMouseDragged:)
                if (![_leftMouseDownView respondsToSelector:selector])
                    selector = nil;
            }

            if (!selector)
                selector = @selector(mouseDragged:)

            return [_leftMouseDownView performSelector:selector withObject:anEvent];

        case CPMouseMoved:
            [_windowView setCursorForLocation:point resizing:NO];

            // Ignore mouse moves for parents of sheets
            if (!_acceptsMouseMovedEvents || sheet)
                return;

            if (!_mouseEnteredStack)
                _mouseEnteredStack = [];

            var hitTestView = [_windowView hitTest:point];

            if ([_mouseEnteredStack count] && [_mouseEnteredStack lastObject] === hitTestView)
                return [hitTestView mouseMoved:anEvent];

            var view = hitTestView,
                mouseEnteredStack = [];

            while (view)
            {
                mouseEnteredStack.unshift(view);

                view = [view superview];
            }

            var deviation = MIN(_mouseEnteredStack.length, mouseEnteredStack.length);

            while (deviation--)
                if (_mouseEnteredStack[deviation] === mouseEnteredStack[deviation])
                    break;

            var index = deviation + 1,
                count = _mouseEnteredStack.length;

            if (index < count)
            {
                var event = [CPEvent mouseEventWithType:CPMouseExited location:point modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0];

                for (; index < count; ++index)
                    [_mouseEnteredStack[index] mouseExited:event];
            }

            index = deviation + 1;
            count = mouseEnteredStack.length;

            if (index < count)
            {
                var event = [CPEvent mouseEventWithType:CPMouseEntered location:point modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:_windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0];

                for (; index < count; ++index)
                    [mouseEnteredStack[index] mouseEntered:event];
            }

            _mouseEnteredStack = mouseEnteredStack;

            [hitTestView mouseMoved:anEvent];
    }
}

@end


@implementation RecordingEvent : CPObject
{
    CPEvent     _event                  @accessors(property=event);
    CPString    _keyView                @accessors(property=keyView);
    CPString    _valueView              @accessors(property=valueView);
    CGPoint     _offsetView             @accessors(property=offsetView);
    int         _offsetXPercentage      @accessors(property=offsetXPercentage);
    int         _offsetYPercentage      @accessors(property=offsetYPercentage);
}

- (id)initWithEvent:(CPEvent)anEvent
{
    if (self = [super init])
    {
        _event = anEvent;
        _offsetView = CGPointMakeZero();
        _keyView = @"";
        _valueView = @"";
    }

    return self;
}

- (void)setView:(CPView)aView
{
    if ([aView respondsToSelector:@selector(cucappIdentifier)])
    {
        _keyView = @"cucappIdentifier";
        _valueView = [aView cucappIdentifier];
    }
    else if ([aView respondsToSelector:@selector(identifier)])
    {
        _keyView = @"identifier";
        _valueView = [aView identifier];
    }
    else if ([aView respondsToSelector:@selector(title)])
    {
        _keyView = @"title";
        _valueView = [aView title];
    }
    else if ([aView respondsToSelector:@selector(placeholderString)])
    {
        _keyView = @"placeholderString";
        _valueView = [aView placeholderString];
    }
    else if ([aView respondsToSelector:@selector(text)])
    {
        _keyView = @"text";
        _valueView = [aView text];
    }
    else if ([aView respondsToSelector:@selector(tag)])
    {
        _keyView = @"tag";
        _valueView = [aView tag];
    }
    else if ([aView respondsToSelector:@selector(label)])
    {
        _keyView = @"label";
        _valueView = [aView label];
    }
    else if ([aView respondsToSelector:@selector(objectValue)])
    {
        _keyView = @"objectValue";
        _valueView = [aView objectValue];
    }

    var globalPoint = [[aView superview] convertPointToBase:[aView frameOrigin]],
        globalEventPoint = [_event locationInWindow];

    _offsetView = CGPointMake(globalEventPoint.x - globalPoint.x, globalEventPoint.y - globalPoint.y);

    _offsetXPercentage = _offsetView.x * 100 / [aView frameSize].width;
    _offsetYPercentage = _offsetView.y * 100 / [aView frameSize].height;
}

- (CPString)objectToJSON
{
    var json = {};

    json["keyView"] = _keyView;
    json["valueView"] = _valueView;
    json["offsetXPercentage"] = _offsetXPercentage;
    json["offsetYPercentage"] = _offsetYPercentage;
    json["offsetView"] = {"x" : _offsetView.x, "y" : _offsetView.y};

    var event = {};
    event["type"] = [_event type];
    event["deltaX"] = [_event deltaX];
    event["deltaY"] = [_event deltaY];
    event["deltaZ"] = [_event deltaZ];
    event["characters"] = [_event characters];
    event["charactersIgnoringModifiers"] = [_event charactersIgnoringModifiers];
    event["clickCount"] = [_event clickCount];
    event["modifierFlags"] = [_event modifierFlags];
    event["locationInWindow"] = {"x" : [_event locationInWindow].x, "y" : [_event locationInWindow].y};
    event["keyCode"] = [_event keyCode];
    event["timestamp"] = [_event timestamp];

    json["event"] = event;

    return JSON.stringify(json, null, 4);
}

@end


@implementation CPApplication (cucappRecord)

/*!
    Dispatches events to other objects.
    @param anEvent the event to dispatch
*/
- (void)sendEvent:(CPEvent)anEvent
{
    _currentEvent = anEvent;
    CPEventModifierFlags = [anEvent modifierFlags];

    var theWindow = [anEvent window];

    // Check if this is a candidate for key equivalent...
    if ([anEvent _couldBeKeyEquivalent] && [self _handleKeyEquivalent:anEvent])
        // The key equivalent was handled.
        return;

    if ([anEvent type] == CPMouseMoved)
    {
        if (theWindow !== _lastMouseMoveWindow)
            [_lastMouseMoveWindow _mouseExitedResizeRect];

        _lastMouseMoveWindow = theWindow;
    }

    /*
        Event listeners are processed from back to front so that newer event listeners normally take
        precedence. If during the execution of a callback a new event listener is added, it should
        be inserted after the current callback but before any higher priority callbacks. This makes
        repeating event listeners (those that reinsert themselves) stable relative to each other.
    */
    for (var i = _eventListeners.length - 1; i >= 0; i--)
    {
        var listener = _eventListeners[i];

        if (listener._mask & (1 << [anEvent type]))
        {
            _eventListeners.splice(i, 1);
            // In case the callback wants to add more listeners.
            _eventListenerInsertionIndex = i;
            listener._callback(anEvent);

            var type = [anEvent type],
                recordingEvent = [[RecordingEvent alloc] initWithEvent:anEvent];

            if (recordingEvent && type != CPFlagsChanged && type != CPMouseMoved)
                [eventRecords addObject:recordingEvent];

            if (theWindow)
                [recordingEvent setView:[theWindow._windowView hitTest:[anEvent locationInWindow]]];

            if (listener._dequeue)
            {
                // Don't process the event normally and don't send it to any other listener.
                _eventListenerInsertionIndex = _eventListeners.length;
                return;
            }
        }
    }

    _eventListenerInsertionIndex = _eventListeners.length;

    if (theWindow)
        [theWindow sendEvent:anEvent];
}

@end
