/*
 * _CPDOMWindow.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

@import "CPEvent.j"
@import "CPCompatibility.j"

@import "CPDOMWindowLayer.j"

@import "CPPlatformWindow.j"

#import "../../CoreGraphics/CGGeometry.h"


var DoubleClick = "dblclick",
    MouseDown   = "mousedown",
    MouseUp     = "mouseup",
    MouseMove   = "mousemove",
    MouseDrag   = "mousedrag",
    KeyUp       = "keyup",
    KeyDown     = "keydown",
    KeyPress    = "keypress",
    Copy        = "copy",
    Paste       = "paste",
    Resize      = "resize",
    ScrollWheel = "mousewheel",
    TouchStart  = "touchstart",
    TouchMove   = "touchmove",
    TouchEnd    = "touchend",
    TouchCancel = "touchcancel";

var ExcludedDOMElements = [];

ExcludedDOMElements["INPUT"]     = YES;
ExcludedDOMElements["SELECT"]    = YES;
ExcludedDOMElements["TEXTAREA"]  = YES;
ExcludedDOMElements["OPTION"]    = YES;

// Define up here so compressor knows about em.
var CPDOMEventGetClickCount,
    CPDOMEventStop;

//right now we hard code q, w, r and t as keys to propogate
//these aren't normal keycodes, they are with modifier key codes
//might be mac only, we should investigate futher later.
var KeyCodesToPrevent = {},
    CharacterKeysToPrevent = {},
    KeyCodesWithoutKeyPressEvents = { '8':1, '9':1, '16':1, '37':1, '38':1, '39':1, '40':1, '46':1, '33':1, '34':1 };

var CTRL_KEY_CODE   = 17;

@implementation _CPDOMWindow : CPPlatformWindow
{
    DOMWindow       _DOMWindow;

    DOMElement      _DOMBodyElement;
    DOMElement      _DOMFocusElement;
    
    CPArray         _windowLevels;
    CPDictionary    _windowLayers;
    
    BOOL            _mouseIsDown;
    CPWindow        _mouseDownWindow;
    CPTimeInterval  _lastMouseUp;
    CPTimeInterval  _lastMouseDown;
    
    JSObject        _charCodes;
    unsigned        _keyCode;
    
    BOOL            _DOMEventMode;
    
    // Native Pasteboard Support
    DOMElement      _DOMPasteboardElement;
    CPEvent         _pasteboardKeyDownEvent;
    
    CPString        _overriddenEventType;
}

- (id)_init
{
    self = [super init];

    if (self)
    {
        _DOMWindow = window;

        [self registerDOMWindow];
        [self updateFromNativeContentRect];

        _charCodes = {};

        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];
    }

    return self;
}

- (id)initWithContentRect:(CGRect)aRect
{
    self = [super initWithContentRect:aRect];

    if (self)
    {
        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];
        
        _charCodes = {};
    }

    return self;
}

- (CGRect)nativeContentRect
{
    if (!_DOMWindow)
        return [self contentRect];

    var contentRect = _CGRectMakeZero();

    if (window.screenTop)
        contentRect.origin = _CGPointMake(_DOMWindow.screenLeft, _DOMWindow.screenTop);

    else if (window.screenX)
        contentRect.origin = _CGPointMake(_DOMWindow.screenX, _DOMWindow.screenY);

    // Safari, Mozilla, Firefox, and Opera
    if (_DOMWindow.innerWidth)
        contentRect.size = _CGSizeMake(_DOMWindow.innerWidth, _DOMWindow.innerHeight);

    // Internet Explorer 6 in Strict Mode
    else if (document.documentElement && document.documentElement.clientWidth)
        contentRect.size = _CGSizeMake(_DOMWindow.document.documentElement.clientWidth, _DOMWindow.document.documentElement.clientHeight);

    // Internet Explorer X
    else
        contentRect.size = _CGSizeMake(_DOMWindow.document.body.clientWidth, _DOMWindow.document.body.clientHeight);

    return contentRect;
}

- (void)updateNativeContentOrigin
{
    if (!_DOMWindow)
        return;

    var origin = [self contentRect].origin,
        nativeOrigin = [self nativeContentRect].origin;

    _DOMWindow.moveBy(origin.x - nativeOrigin.x, origin.y - nativeOrigin.y);
}

- (void)updateNativeContentSize
{
    if (!_DOMWindow)
        return;

    var size = [self contentRect].size,
        nativeSize = [self nativeContentRect].size;

    _DOMWindow.resizeBy(size.width - nativeSize.width, size.height - nativeSize.height);
}

- (void)orderBack:(id)aSender
{
    if (_DOMWindow)
        _DOMWindow.blur();
}

- (void)registerDOMWindow
{
    var theDocument = _DOMWindow.document;

    _DOMBodyElement = theDocument.getElementsByTagName("body")[0];

    _DOMBodyElement.webkitTouchCallout = "none";

    _DOMFocusElement = theDocument.createElement("input");

    _DOMFocusElement.style.position = "absolute";
    _DOMFocusElement.style.zIndex = "-1000";
    _DOMFocusElement.style.opacity = "0";
    _DOMFocusElement.style.filter = "alpha(opacity=0)";
    
    _DOMBodyElement.appendChild(_DOMFocusElement);

    // Create Native Pasteboard handler.
    _DOMPasteboardElement = theDocument.createElement("input");

    _DOMPasteboardElement.style.position = "absolute";
    _DOMPasteboardElement.style.top = "-10000px";
    _DOMPasteboardElement.style.zIndex = "99";

    _DOMBodyElement.appendChild(_DOMPasteboardElement);

    // Make sure the pastboard element is blurred.
    _DOMPasteboardElement.blur();

    var theClass = [self class],

        resizeEventSelector = @selector(resizeEvent:),
        resizeEventImplementation = class_getMethodImplementation(theClass, resizeEventSelector),
        resizeEventCallback = function (anEvent) { resizeEventImplementation(self, nil, anEvent); },

        keyEventSelector = @selector(keyEvent:),
        keyEventImplementation = class_getMethodImplementation(theClass, keyEventSelector),
        keyEventCallback = function (anEvent) { keyEventImplementation(self, nil, anEvent); },
        
        mouseEventSelector = @selector(mouseEvent:),
        mouseEventImplementation = class_getMethodImplementation(theClass, mouseEventSelector),
        mouseEventCallback = function (anEvent) { mouseEventImplementation(self, nil, anEvent); },
        
        scrollEventSelector = @selector(scrollEvent:),
        scrollEventImplementation = class_getMethodImplementation(theClass, scrollEventSelector),
        scrollEventCallback = function (anEvent) { scrollEventImplementation(self, nil, anEvent); },
        
        touchEventSelector = @selector(touchEvent:),
        touchEventImplementation = class_getMethodImplementation(theClass, touchEventSelector),
        touchEventCallback = function (anEvent) { touchEventImplementation(self, nil, anEvent); };

    if (theDocument.addEventListener)
    {
        theDocument.addEventListener("mouseup", mouseEventCallback, NO);
        theDocument.addEventListener("mousedown", mouseEventCallback, NO);
        theDocument.addEventListener("mousemove", mouseEventCallback, NO);

        theDocument.addEventListener("keyup", keyEventCallback, NO);
        theDocument.addEventListener("keydown", keyEventCallback, NO);
        theDocument.addEventListener("keypress", keyEventCallback, NO);

        theDocument.addEventListener("touchstart", touchEventCallback, NO);
        theDocument.addEventListener("touchend", touchEventCallback, NO);
        theDocument.addEventListener("touchmove", touchEventCallback, NO);
        theDocument.addEventListener("touchcancel", touchEventCallback, NO);

        _DOMWindow.addEventListener("resize", resizeEventCallback, NO);        

        _DOMWindow.addEventListener("beforeunload", function()
        {
            [self updateFromNativeContentRect];

            theDocument.removeEventListener("mouseup", mouseEventCallback, NO);
            theDocument.removeEventListener("mousedown", mouseEventCallback, NO);
            theDocument.removeEventListener("mousemove", mouseEventCallback, NO);

            theDocument.removeEventListener("keyup", keyEventCallback, NO);
            theDocument.removeEventListener("keydown", keyEventCallback, NO);
            theDocument.removeEventListener("keypress", keyEventCallback, NO);

            theDocument.removeEventListener("touchstart", touchEventCallback, NO);
            theDocument.removeEventListener("touchend", touchEventCallback, NO);
            theDocument.removeEventListener("touchmove", touchEventCallback, NO);

            _DOMWindow.removeEventListener("resize", resizeEventCallback, NO);

            //FIXME: does firefox really need a different value?
            _DOMWindow.removeEventListener("DOMMouseScroll", scrollEventCallback, NO);
            _DOMWindow.removeEventListener("mousewheel", scrollEventCallback, NO);

            //_DOMWindow.removeEventListener("beforeunload", this, NO);

            self._DOMWindow = nil;
        }, NO);
    }
    else
    {
        theDocument.attachEvent("onmouseup", mouseEventCallback);
        theDocument.attachEvent("onmousedown", mouseEventCallback);
        theDocument.attachEvent("onmousemove", mouseEventCallback);
        theDocument.attachEvent("ondblclick", mouseEventCallback);
        
        theDocument.attachEvent("onkeyup", keyEventCallback);
        theDocument.attachEvent("onkeydown", keyEventCallback);
        theDocument.attachEvent("onkeypress", keyEventCallback);
        
        _DOMWindow.attachEvent("onresize", resizeEventCallback);
        
        _DOMWindow.onmousewheel = scrollEventCallback;
        theDocument.onmousewheel = scrollEventCallback;
        
        theDocument.body.ondrag = function () { return NO; };
        theDocument.body.onselectstart = function () { return _DOMWindow.event.srcElement === _DOMPasteboardElement; };

        _DOMWindow.attachEvent("onbeforeunload", function()
        {
            [self updateFromNativeContentRect];

            theDocument.removeEvent("onmouseup", mouseEventCallback);
            theDocument.removeEvent("onmousedown", mouseEventCallback);
            theDocument.removeEvent("onmousemove", mouseEventCallback);
            theDocument.removeEvent("ondblclick", mouseEventCallback);

            theDocument.removeEvent("onkeyup", keyEventCallback);
            theDocument.removeEvent("onkeydown", keyEventCallback);
            theDocument.removeEvent("onkeypress", keyEventCallback);

            _DOMWindow.removeEvent("onresize", resizeEventCallback);

            _DOMWindow.onmousewheel = NULL;
            theDocument.onmousewheel = NULL;

            theDocument.body.ondrag = NULL;
            theDocument.body.onselectstart = NULL;

            //_DOMWindow.removeEvent("beforeunload", this);

            self._DOMWindow = nil;
        }, NO);
    }
}

- (void)orderFront:(id)aSender
{
    if (_DOMWindow)
        return _DOMWindow.focus();

    _DOMWindow = window.open("", "", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left=" + _CGRectGetMinX(_contentRect) + ",top=" + _CGRectGetMinY(_contentRect) + ",width=" + _CGRectGetWidth(_contentRect) + ",height=" + _CGRectGetHeight(_contentRect));

    [self registerDOMWindow];
}

- (void)orderOut:(id)aSender
{
    _DOMWindow.close();
}

- (void)keyEvent:(DOMEvent)aDOMEvent
{
    var event,
        timestamp = aDOMEvent.timeStamp ? aDOMEvent.timeStamp : new Date(),
        sourceElement = (aDOMEvent.target || aDOMEvent.srcElement),
        windowNumber = [[CPApp keyWindow] windowNumber],
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) | 
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) | 
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) | 
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);
                        
    if (ExcludedDOMElements[sourceElement.tagName] && sourceElement != _DOMFocusElement && sourceElement != _DOMPasteboardElement)
        return;
        
    //We want to stop propagation if this is a command key AND this character or keycode has been added to our blacklist
    StopDOMEventPropagation = !(modifierFlags & (CPControlKeyMask | CPCommandKeyMask)) ||
                              CharacterKeysToPrevent[String.fromCharCode(aDOMEvent.keyCode || aDOMEvent.charCode).toLowerCase()] ||
                              KeyCodesToPrevent[aDOMEvent.keyCode];

    var isNativePasteEvent = NO,
        isNativeCopyOrCutEvent = NO;
    
    switch (aDOMEvent.type)
    {
        case "keydown":     // Grab and store the keycode now since it is correct and consistent at this point.
                            _keyCode = aDOMEvent.keyCode;
                            
                            var characters = String.fromCharCode(_keyCode).toLowerCase();
                            
                            // If this could be a native PASTE event, then we need to further examine it before 
                            // sending a CPEvent.  Select our element to see if anything gets pasted in it.
                            if (characters == "v" && (modifierFlags & CPPlatformActionKeyMask))
                            {
                                _DOMPasteboardElement.select();
                                _DOMPasteboardElement.value = "";
    
                                isNativePasteEvent = YES;
                            }
                            
                            // Normally we return now because we let keypress send the actual CPEvent keyDown event, since we don't have
                            // a complete set of information yet.
                            
                            // However, of this could be a native COPY event, we need to let the normal event-process take place so it 
                            // can capture our internal Cappuccino pasteboard.
                            else if ((characters == "c" || characters == "x") && (modifierFlags & CPPlatformActionKeyMask))
                                isNativeCopyOrCutEvent = YES;
    
                            // Also, certain browsers (IE and Safari), have broken keyboard supportwhere they don't send keypresses for certain events.
                            // So, allow the keypress event to handle the event if we are not a browser with broken (remedial) key support...
                            else if (!CPFeatureIsCompatible(CPJavascriptRemedialKeySupport))
                                return;
                            
                            // Or, if this is not one of those special keycodes, and also not a ctrl+event
                            else if (!KeyCodesWithoutKeyPressEvents[_keyCode] && (_keyCode == CTRL_KEY_CODE || !(modifierFlags & CPControlKeyMask)))
                                return;
                                    
                            // If this is in fact our broke state, continue to keypress and send the keydown.
        case "keypress":    // If the source of this event is our pasteboard element, then simply let it continue 
                            // as normal, so that the paste event can successfully complete.
                            if ((aDOMEvent.target || aDOMEvent.srcElement) == _DOMPasteboardElement)
                                return;
                            
                            var keyCode = _keyCode,
                                charCode = aDOMEvent.keyCode || aDOMEvent.charCode,
                                isARepeat = (_charCodes[keyCode] != nil);

                            _charCodes[keyCode] = charCode;
                                
                            var characters = String.fromCharCode(charCode),
                                charactersIgnoringModifiers = characters.toLowerCase();
                                                                        
                            event = [CPEvent keyEventWithType:CPKeyDown location:location modifierFlags:modifierFlags
                                        timestamp:timestamp windowNumber:windowNumber context:nil
                                        characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:keyCode];
                            
                            if (isNativePasteEvent)
                            {
                                _pasteboardKeyDownEvent = event;
                                
                                window.setNativeTimeout(function () { [self _checkPasteboardElement] }, 0);
                                
                                return;
                            }

                            break;
        
        case "keyup":       var keyCode = aDOMEvent.keyCode,
                                charCode = _charCodes[keyCode];
                            
                            _charCodes[keyCode] = nil;
                                
                            var characters = String.fromCharCode(charCode),
                                charactersIgnoringModifiers = characters.toLowerCase();
                                
                            if (!(modifierFlags & CPShiftKeyMask))
                                characters = charactersIgnoringModifiers;
                            
                            event = [CPEvent keyEventWithType:CPKeyUp location:location modifierFlags:modifierFlags
                                        timestamp: timestamp windowNumber:windowNumber context:nil
                                        characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:NO keyCode:keyCode];
                            break;
    }
    
    if (event)
    {
        event._DOMEvent = aDOMEvent;
        
        [CPApp sendEvent:event];
        
        if (isNativeCopyOrCutEvent)
        {
            var pasteboard = [CPPasteboard generalPasteboard],
                types = [pasteboard types];
            
            // If this is a native copy event, then check if the pasteboard has anything in it.
            if (types.length)
            {
                if ([types indexOfObjectIdenticalTo:CPStringPboardType] != CPNotFound)
                    _DOMPasteboardElement.value = [pasteboard stringForType:CPStringPboardType];
                else
                    _DOMPasteboardElement.value = [pasteboard _generateStateUID];

                _DOMPasteboardElement.select();
                
                window.setNativeTimeout(function() { [self _clearPasteboardElement]; }, 0);
            }
            
            return;
        }
    }
        
    if (StopDOMEventPropagation)
        CPDOMEventStop(aDOMEvent);
        
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

}

- (void)scrollEvent:(DOMEvent)aDOMEvent
{
    if(!aDOMEvent)
        aDOMEvent = window.event;

    if (CPFeatureIsCompatible(CPJavaScriptMouseWheelValues_8_15))
    {
        var x = 0.0,
            y = 0.0,
            element = aDOMEvent.target;
        
        while (element.nodeType !== 1)
            element = element.parentNode;

        if (element.offsetParent)
        {
            do
            {
                x += element.offsetLeft;
                y += element.offsetTop;
    
            } while (element = element.offsetParent);
        }
    
        var location = _CGPointMake((x + ((aDOMEvent.clientX - 8) / 15)), (y + ((aDOMEvent.clientY - 8) / 15)));
    }
    else
        var location = _CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY);
        
    var deltaX = 0.0,
        deltaY = 0.0,
        windowNumber = 0,
        timestamp = aDOMEvent.timeStamp ? aDOMEvent.timeStamp : new Date(),
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) | 
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) | 
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) | 
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);
          
    StopDOMEventPropagation = YES;
    
    windowNumber = [[self hitTest:location] windowNumber];

    if (!windowNumber)
        return;

    var windowFrame = CPApp._windows[windowNumber]._frame;
        
    location.x -= CGRectGetMinX(windowFrame);
    location.y -= CGRectGetMinY(windowFrame);

    if(typeof aDOMEvent.wheelDeltaX != "undefined")
    {
        deltaX = aDOMEvent.wheelDeltaX / 120.0;
        deltaY = aDOMEvent.wheelDeltaY / 120.0;
    }
    
    else if (aDOMEvent.wheelDelta)
        deltaY = aDOMEvent.wheelDelta / 120.0;
    
    else if (aDOMEvent.detail) 
        deltaY = -aDOMEvent.detail / 3.0;
    
    else
        return;        

    if(!CPFeatureIsCompatible(CPJavaScriptNegativeMouseWheelValues))
    {
        deltaX = -deltaX;
        deltaY = -deltaY;
    }
    
    var event = [CPEvent mouseEventWithType:CPScrollWheel location:location modifierFlags:modifierFlags
            timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0 ];
    
    event._DOMEvent = aDOMEvent;
    event._deltaX = deltaX;
    event._deltaY = deltaY;
    
    [CPApp sendEvent:event];
        
    if (StopDOMEventPropagation)
        CPDOMEventStop(aDOMEvent);
        
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)resizeEvent:(DOMEvent)aDOMEvent
{
    // FIXME: This is not the right way to do this.
    // We should pay attention to mouse down and mouse up in conjunction with this.
    //window.liveResize = YES;

    var oldSize = [self contentRect].size;

    [self updateFromNativeContentRect];

    var levels = _windowLevels,
        layers = _windowLayers,
        levelCount = levels.length;

    while (levelCount--)
    {
        var windows = [layers objectForKey:levels[levelCount]]._windows,
            windowCount = windows.length;

        while (windowCount--)
            [windows[windowCount] resizeWithOldBridgeSize:oldSize];
    }

    //window.liveResize = NO;

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)touchEvent:(DOMEvent)aDOMEvent
{
    if (aDOMEvent.touches && (aDOMEvent.touches.length == 1 || (aDOMEvent.touches.length == 0 && aDOMEvent.changedTouches.length == 1)))
    {
        var newEvent = {};
        
        switch(aDOMEvent.type)
        {
            case CPDOMEventTouchStart:  newEvent.type = CPDOMEventMouseDown;
                                        break;
            case CPDOMEventTouchEnd:    newEvent.type = CPDOMEventMouseUp;
                                        break;
            case CPDOMEventTouchMove:   newEvent.type = CPDOMEventMouseMoved;
                                        break;
            case CPDOMEventTouchCancel: newEvent.type = CPDOMEventMouseUp;
                                        break;
        }

        var touch = aDOMEvent.touches.length ? aDOMEvent.touches[0] : aDOMEvent.changedTouches[0];
        
        newEvent.clientX = touch.clientX;
        newEvent.clientY = touch.clientY;
        
        newEvent.timestamp = aDOMEvent.timestamp;
        newEvent.target = aDOMEvent.target;
        
        newEvent.shiftKey = newEvent.ctrlKey = newEvent.altKey = newEvent.metaKey = false;
        
        newEvent.preventDefault = function(){if(aDOMEvent.preventDefault) aDOMEvent.preventDefault()};
        newEvent.stopPropagation = function(){if(aDOMEvent.stopPropagation) aDOMEvent.stopPropagation()};
        
        [self _bridgeMouseEvent:newEvent];
    
        return;
    }
    else
    {
        if (aDOMEvent.preventDefault)
            aDOMEvent.preventDefault();
        
        if (aDOMEvent.stopPropagation)
            aDOMEvent.stopPropagation();
    }
    // handle touch cases specifically
}

- (void)mouseEvent:(DOMEvent)aDOMEvent
{
    var type = _overriddenEventType || aDOMEvent.type;

    // IE's event order is down, up, up, dblclick, so we have create these events artificially.
    if (type === CPDOMEventDoubleClick)
    {
        _overriddenEventType = CPDOMEventMouseDown;
        [self _bridgeMouseEvent:aDOMEvent];

        _overriddenEventType = CPDOMEventMouseUp;
        [self _bridgeMouseEvent:aDOMEvent];

        _overriddenEventType = nil;

        return;         
    }

    var event,
        location = _CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY),
        timestamp = aDOMEvent.timeStamp ? aDOMEvent.timeStamp : new Date(),
        sourceElement = (aDOMEvent.target || aDOMEvent.srcElement),
        windowNumber = 0,
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) | 
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) | 
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) | 
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);

    StopDOMEventPropagation = YES;

    if (_mouseDownWindow)
        windowNumber = [_mouseDownWindow windowNumber];

    else
    {
        var theWindow = [self hitTest:location];

        if ((aDOMEvent.type === CPDOMEventMouseDown) && theWindow)
            _mouseDownWindow = theWindow;

        windowNumber = [theWindow windowNumber];
    }

    if (windowNumber)
    {
        var windowFrame = CPApp._windows[windowNumber]._frame;

        location.x -= _CGRectGetMinX(windowFrame);
        location.y -= _CGRectGetMinY(windowFrame);
    }

    if (type === "mouseup")
    {
        if(_mouseIsDown)
        {
            event = _CPEventFromNativeMouseEvent(aDOMEvent, CPLeftMouseUp, location, modifierFlags, timestamp, windowNumber, nil, -1, CPDOMEventGetClickCount(_lastMouseUp, timestamp, location), 0);
        
            _mouseIsDown = NO;
            _lastMouseUp = event;
            _mouseDownWindow = nil;
        }

        if(_DOMEventMode)
        {
            _DOMEventMode = NO;
            return;
        }
    }
    
    else if (type === "mousedown")
    {                               
        if (ExcludedDOMElements[sourceElement.tagName] && sourceElement != _DOMFocusElement)
        {
            _DOMEventMode = YES;
            _mouseIsDown = YES;

            //fake a down and up event so that event tracking mode will work correctly
            [CPApp sendEvent:[CPEvent mouseEventWithType:CPLeftMouseDown location:location modifierFlags:modifierFlags
                    timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1 
                    clickCount:CPDOMEventGetClickCount(_lastMouseDown, timestamp, location) pressure:0]];

            [CPApp sendEvent:[CPEvent mouseEventWithType:CPLeftMouseUp location:location modifierFlags:modifierFlags
                    timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1 
                    clickCount:CPDOMEventGetClickCount(_lastMouseDown, timestamp, location) pressure:0]];

            return;
        }

        event = _CPEventFromNativeMouseEvent(aDOMEvent, CPLeftMouseDown, location, modifierFlags, timestamp, windowNumber, nil, -1, CPDOMEventGetClickCount(_lastMouseDown, timestamp, location), 0);
                    
        _mouseIsDown = YES;
        _lastMouseDown = event;
    }
    
    else // if (type === "mousemove")                    
    {
        if (_DOMEventMode)
            return;

        event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseIsDown ? CPLeftMouseDragged : CPMouseMoved, location, modifierFlags, timestamp, windowNumber, nil, -1, 1, 0);
    }

    if (event)
    {
        event._DOMEvent = aDOMEvent;
        
        [CPApp sendEvent:event];
    }

    if (StopDOMEventPropagation)
        CPDOMEventStop(aDOMEvent);

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

 (CPArray)orderedWindowsAtLevel:(int)aLevel
{
    var layer = [self layerAtLevel:aLevel create:NO];
    
    if (!layer)
        return [];
    
    return [layer orderedWindows];
}

- (CPDOMWindowLayer)layerAtLevel:(int)aLevel create:(BOOL)aFlag
{
    var layer = [_windowLayers objectForKey:aLevel];
    
    // If the layer doesn't currently exist, and the create flag is true,
    // create the layer.
    if (!layer && aFlag)
    {
        layer = [[CPDOMWindowLayer alloc] initWithLevel:aLevel];
        
        [_windowLayers setObject:layer forKey:aLevel];
        
        // Find the nearest layer.  This is similar to a binary search, 
        // only we know we won't find the value.
        var low = 0,
            high = _windowLevels.length - 1,
            middle;
            
        while (low <= high)
        {
            middle = FLOOR((low + high) / 2);
            
            if (_windowLevels[middle] > aLevel)
                high = middle - 1;
            else
                low = middle + 1;
        }

        [_windowLevels insertObject:aLevel atIndex:_windowLevels[middle] > aLevel ? middle : middle + 1];
        layer._DOMElement.style.zIndex = aLevel;
        _DOMBodyElement.appendChild(layer._DOMElement);
    }
    
    return layer;
}

- (void)order:(CPWindowOrderingMode)aPlace window:(CPWindow)aWindow relativeTo:(CPWindow)otherWindow
{
    // Grab the appropriate level for the layer, and create it if 
    // necessary (if we are not simply removing the window).
    var layer = [self layerAtLevel:[aWindow level] create:aPlace != CPWindowOut];
        
    // Ignore otherWindow, simply remove this window from it's level.  
    // If layer is nil, this will be a no-op.
    if (aPlace == CPWindowOut)
        return [layer removeWindow:aWindow];

    // Place the window at the appropriate index.
    [layer insertWindow:aWindow atIndex:(otherWindow ? (aPlace == CPWindowAbove ? otherWindow._index + 1 : otherWindow._index) : CPNotFound)];
}

/* @ignore */
- (id)_dragHitTest:(CPPoint)aPoint pasteboard:(CPPasteboard)aPasteboard
{
    var levels = _windowLevels,
        layers = _windowLayers,
        levelCount = levels.length;

    while (levelCount--)
    {
        // Skip any windows above or at the dragging level.
        if (levels[levelCount] >= CPDraggingWindowLevel)
            continue;
        
        var windows = [layers objectForKey:levels[levelCount]]._windows,
            windowCount = windows.length;
        
        while (windowCount--)
        {
            var theWindow = windows[windowCount];
            
            if ([theWindow containsPoint:aPoint])
                return [theWindow _dragHitTest:aPoint pasteboard:aPasteboard];
        }
    }
    
    return nil;
}

/* @ignore */
- (void)_propagateCurrentDOMEvent:(BOOL)aFlag
{
    StopDOMEventPropagation = !aFlag;
}

- (CPWindow)hitTest:(CPPoint)location
{
    var levels = _windowLevels,
        layers = _windowLayers,
        levelCount = levels.length,
        theWindow = nil;

    while (levelCount-- && !theWindow)
    {
        var windows = [layers objectForKey:levels[levelCount]]._windows,
            windowCount = windows.length;

        while (windowCount-- && !theWindow)
        {
            var candidateWindow = windows[windowCount];
            
            if (!candidateWindow._ignoresMouseEvents && [candidateWindow containsPoint:location])
                theWindow = candidateWindow;
        }
    }

    return theWindow;
}

- (void)_checkPasteboardElement
{
    var value = _DOMPasteboardElement.value;

    if ([value length])
    {
        var pasteboard = [CPPasteboard generalPasteboard];
        
        if ([pasteboard _stateUID] != value)
        {            
            [pasteboard declareTypes:[CPStringPboardType] owner:self];
        
            [pasteboard setString:value forType:CPStringPboardType];
        }
    }
    
    [self _clearPasteboardElement];

    [CPApp sendEvent:_pasteboardKeyDownEvent];
    
    _pasteboardKeyDownEvent = nil;
    
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)_clearPasteboardElement
{
    _DOMPasteboardElement.value = "";
    _DOMPasteboardElement.blur();
}

/*!
    When using command (mac) or control (windows), keys are propagated to the browser by default.  
    To prevent a character key from propagating (to prevent its default action, and instead use it
    in your own application), use these methods. These methods are additive -- the list builds until you clear it.
    
    @param characters a list of characters to stop propagating keypresses to the browser.
*/
- (void)preventCharacterKeysFromPropagating:(CPArray)characters
{
    for(var i=characters.length; i>0; i--)
        CharacterKeysToPrevent[""+characters[i-1].toLowerCase()] = YES;
}

/*!
    @param character a character to stop propagating keypresses to the browser.
*/
- (void)preventCharacterKeyFromPropagating:(CPString)character
{
    CharacterKeysToPrevent[character.toLowerCase()] = YES;
}

/*!
    Clear the list of characters for which we are not sending keypresses to the browser.
*/
- (void)clearCharacterKeysToPreventFromPropagating
{
    CharacterKeysToPrevent = {};
}

/*!
    Prevent these keyCodes from sending their keypresses to the browser.
    @param keyCodes an array of keycodes to prevent propagation.
*/
- (void)preventKeyCodesFromPropagating:(CPArray)keyCodes
{
    for(var i=keyCodes.length; i>0; i--)
        KeyCodesToPrevent[keyCodes[i-1]] = YES;
}

/*!
    Prevent this keyCode from sending its key events to the browser.
    @param keyCode a keycode to prevent propagation.
*/
- (void)preventKeyCodeFromPropagating:(CPString)keyCode
{
    KeyCodesToPrevent[keyCode] = YES;
}

/*!
    Clear the list of keyCodes for which we are not sending keypresses to the browser.
*/
- (void)clearKeyCodesToPreventFromPropagating
{
    KeyCodesToPrevent = {};
}


@end

var CPEventClass = [CPEvent class];

var _CPEventFromNativeMouseEvent = function(aNativeEvent, anEventType, aPoint, modifierFlags, aTimestamp, aWindowNumber, aGraphicsContext, anEventNumber, aClickCount, aPressure)
{
    aNativeEvent.isa = CPEventClass;

    aNativeEvent._type = anEventType;
    aNativeEvent._location = aPoint;
    aNativeEvent._modifierFlags = modifierFlags;
    aNativeEvent._timestamp = aTimestamp;
    aNativeEvent._windowNumber = aWindowNumber;
    aNativeEvent._window = nil;
    aNativeEvent._context = aGraphicsContext;
    aNativeEvent._eventNumber = anEventNumber;
    aNativeEvent._clickCount = aClickCount;
    aNativeEvent._pressure = aPressure;

    return aNativeEvent;
}

var CLICK_SPACE_DELTA   = 5.0,
    CLICK_TIME_DELTA    = (typeof document != "undefined" && document.addEventListener) ? 350.0 : 1000.0;

var CPDOMEventGetClickCount = function(aComparisonEvent, aTimestamp, aLocation)
{
    if (!aComparisonEvent)
        return 1;
    
    var comparisonLocation = [aComparisonEvent locationInWindow];
    
    return (aTimestamp - [aComparisonEvent timestamp] < CLICK_TIME_DELTA && 
        ABS(comparisonLocation.x - aLocation.x) < CLICK_SPACE_DELTA && 
        ABS(comparisonLocation.y - aLocation.y) < CLICK_SPACE_DELTA) ? [aComparisonEvent clickCount] + 1 : 1;
}

var CPDOMEventStop = function(aDOMEvent)
{
    // IE Model
    aDOMEvent.cancelBubble = true;
    aDOMEvent.returnValue = false;

    // W3C Model
    if (aDOMEvent.preventDefault)
        aDOMEvent.preventDefault();

    if (aDOMEvent.stopPropagation)
        aDOMEvent.stopPropagation();

    if (aDOMEvent.type === CPDOMEventMouseDown)
    {
        CPSharedDOMWindowBridge._DOMFocusElement.focus();
        CPSharedDOMWindowBridge._DOMFocusElement.blur();
    }
}

function CPWindowObjectList()
{
    var bridge = [CPDOMWindowBridge sharedDOMWindowBridge],
        levels = bridge._windowLevels,
        layers = bridge._windowLayers,
        levelCount = levels.length,
        windowObjects = [];

    while (levelCount--)
    {
        var windows = [layers objectForKey:levels[levelCount]]._windows,
            windowCount = windows.length;

        while (windowCount--)
            windowObjects.push(windows[windowCount]);
    }

    return windowObjects;
}

function CPWindowList()
{
    var bridge = [CPDOMWindowBridge sharedDOMWindowBridge],
        levels = bridge._windowLevels,
        layers = bridge._windowLayers,
        levelCount = levels.length,
        windowNumbers = [];

    while (levelCount--)
    {
        var windows = [layers objectForKey:levels[levelCount]]._windows,
            windowCount = windows.length;

        while (windowCount--)
            windowNumbers.push([windows[windowCount] windowNumber]);
    }

    return windowNumbers;
}
