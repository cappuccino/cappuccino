/*
 * CPDOMWindowBridge.j
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

#import "../../CoreGraphics/CGGeometry.h"


CPSharedDOMWindowBridge = nil;

var ExcludedDOMElements = [];

// Define up here so compressor knows about em.
var CPDOMWindowGetFrame,
    CPDOMEventGetClickCount,
    CPDOMEventStop;

@implementation CPDOMWindowBridge : CPObject
{
    CPArray         _orderedWindows;
    CPWindow        _mouseDownWindow;
    
    DOMWindow       _DOMWindow;
    DOMElement      _DOMBodyElement;
    DOMElement      _DOMFocusElement;
    
    CPArray         _windowLevels;
    CPDictionary    _windowLayers;
    
    CPRect          _frame;
    CPRect          _contentBounds;
    
    BOOL            _mouseIsDown;
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

/*!
    Returns the shared DOMWindowBridge.  
*/
+ (id)sharedDOMWindowBridge
{
    if (!CPSharedDOMWindowBridge)
        CPSharedDOMWindowBridge = [[CPDOMWindowBridge alloc] _initWithDOMWindow:window];
        
    return CPSharedDOMWindowBridge;
}

- (id)initWithFrame:(CPRect)aFrame
{
    alert("unimplemented");
}

/* @ignore */
- (id)_initWithDOMWindow:(DOMWindow)aDOMWindow
{
    self = [super init];
    
    if (self)
    {
        _DOMWindow = aDOMWindow;
        
        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];
        
        // Do this before getting the frame of the window, because if not it will be wrong in IE.
        _DOMBodyElement = document.getElementsByTagName("body")[0];
        _DOMBodyElement.innerHTML = ""; // Get rid of anything that might be lingering in the body element.
        _DOMBodyElement.style.overflow = "hidden";
        _DOMBodyElement.style.webkitTouchCallout = "none";
        
        [CPString _resetSize];

        if (document.documentElement)
            document.documentElement.style.overflow = "hidden";
        
        _frame = CPDOMWindowGetFrame(_DOMWindow);
        _contentBounds = CGRectMake(0.0, 0.0, CPRectGetWidth(_frame), CPRectGetHeight(_frame));
        
        _DOMFocusElement = document.createElement("input");
        _DOMFocusElement.style.position = "absolute";
        _DOMFocusElement.style.zIndex = "-1000";
        _DOMFocusElement.style.opacity = "0";
        _DOMFocusElement.style.filter = "alpha(opacity=0)";
        _DOMBodyElement.appendChild(_DOMFocusElement);
            
        // Create Native Pasteboard handler.
        _DOMPasteboardElement = document.createElement("input");
        _DOMPasteboardElement.style.position = "absolute";
        _DOMPasteboardElement.style.top = "-10000px";
        _DOMPasteboardElement.style.zIndex = "99";
        
        _DOMBodyElement.appendChild(_DOMPasteboardElement);
        
        // Make sure the pastboard element is blurred.
        _DOMPasteboardElement.blur();

        _charCodes = {};
    
        // 
        var theClass = [self class],
            
            keyEventSelector = @selector(_bridgeKeyEvent:),
            keyEventImplementation = class_getMethodImplementation(theClass, keyEventSelector),
            keyEventCallback = function (anEvent) { keyEventImplementation(self, nil, anEvent); },
            
            mouseEventSelector = @selector(_bridgeMouseEvent:),
            mouseEventImplementation = class_getMethodImplementation(theClass, mouseEventSelector),
            mouseEventCallback = function (anEvent) { mouseEventImplementation(self, nil, anEvent); },
            
            scrollEventSelector = @selector(_bridgeScrollEvent:),
            scrollEventImplementation = class_getMethodImplementation(theClass, scrollEventSelector),
            scrollEventCallback = function (anEvent) { scrollEventImplementation(self, nil, anEvent); },
            
            resizeEventSelector = @selector(_bridgeResizeEvent:),
            resizeEventImplementation = class_getMethodImplementation(theClass, resizeEventSelector),
            resizeEventCallback = function (anEvent) { resizeEventImplementation(self, nil, anEvent); },
            
            touchEventSelector = @selector(_bridgeTouchEvent:),
            touchEventImplementation = class_getMethodImplementation(theClass, touchEventSelector),
            touchEventCallback = function (anEvent) { touchEventImplementation(self, nil, anEvent); },

            theDocument = _DOMWindow.document;
        
        if (document.addEventListener)
        {
            _DOMWindow.addEventListener("resize", resizeEventCallback, NO);

            theDocument.addEventListener(CPDOMEventMouseUp, mouseEventCallback, NO);
            theDocument.addEventListener(CPDOMEventMouseDown, mouseEventCallback, NO);
            theDocument.addEventListener(CPDOMEventMouseMoved, mouseEventCallback, NO);
            
            theDocument.addEventListener(CPDOMEventKeyUp, keyEventCallback, NO);
            theDocument.addEventListener(CPDOMEventKeyDown, keyEventCallback, NO);
            theDocument.addEventListener(CPDOMEventKeyPress, keyEventCallback, NO);
            
            
            theDocument.addEventListener(CPDOMEventTouchStart, touchEventCallback, NO);
            theDocument.addEventListener(CPDOMEventTouchEnd, touchEventCallback, NO);
            theDocument.addEventListener(CPDOMEventTouchMove, touchEventCallback, NO);
            theDocument.addEventListener(CPDOMEventTouchCancel, touchEventCallback, NO);
            
            //FIXME: does firefox really need a different value?
            _DOMWindow.addEventListener("DOMMouseScroll", scrollEventCallback, NO);
            _DOMWindow.addEventListener(CPDOMEventScrollWheel, scrollEventCallback, NO);
        }
        else if(document.attachEvent)
        {
            _DOMWindow.attachEvent("onresize", resizeEventCallback);
    
            theDocument.attachEvent("on" + CPDOMEventMouseUp, mouseEventCallback);
            theDocument.attachEvent("on" + CPDOMEventMouseDown, mouseEventCallback);
            theDocument.attachEvent("on" + CPDOMEventMouseMoved, mouseEventCallback);
            theDocument.attachEvent("on" + CPDOMEventDoubleClick, mouseEventCallback);
            
            theDocument.attachEvent("on" + CPDOMEventKeyUp, keyEventCallback);
            theDocument.attachEvent("on" + CPDOMEventKeyDown, keyEventCallback);
            theDocument.attachEvent("on" + CPDOMEventKeyPress, keyEventCallback);
            
            _DOMWindow.onmousewheel = scrollEventCallback;
            theDocument.onmousewheel = scrollEventCallback;
            
            theDocument.body.ondrag = function () { return NO; };
            theDocument.body.onselectstart = function () { return window.event.srcElement == _DOMPasteboardElement; };
        }

        ExcludedDOMElements["INPUT"]     = YES;
        ExcludedDOMElements["SELECT"]    = YES;
        ExcludedDOMElements["TEXTAREA"]  = YES;
        ExcludedDOMElements["OPTION"]    = YES;
    }

    return self;
}

- (CPRect)frame
{
    return CGRectMakeCopy(_frame);
}

- (CGRect)visibleFrame
{
    var frame = [self frame];
    
    frame.origin = CGPointMakeZero();
    
    if ([CPMenu menuBarVisible])
    {
        var menuBarHeight = [[CPApp mainMenu] menuBarHeight];
        
        frame.origin.y += menuBarHeight;
        frame.size.height -= menuBarHeight;
    }
    
    return frame;
}

- (CPRect)contentBounds
{
    return CPRectCreateCopy(_contentBounds);
}

- (CPArray)orderedWindowsAtLevel:(int)aLevel
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

@end

var CPDOMWindowGetFrame = function(_DOMWindow)
{
    var frame = nil;//CGRectMakeZero();
        
    // We will rarely be able to get all this information, but we do the best we can:
    if (_DOMWindow.outerWidth)
        frame = CGRectMake(0, 0, _DOMWindow.outerWidth, _DOMWindow.outerHeight);
        
    else /*if(self.outerWidth)*/ 
        frame = CGRectMake(0, 0, -1, -1);

    if (window.screenTop)
        frame.origin = CGPointMake(_DOMWindow.screenLeft, _DOMWindow.screenTop, 0);
    
    else if (window.screenX)
        frame.origin = CGPointMake(_DOMWindow.screenX, _DOMWindow.screenY, 0);

    // Safari, Mozilla, Firefox, and Opera
    if (_DOMWindow.innerWidth)
        frame.size = CGSizeMake(_DOMWindow.innerWidth, _DOMWindow.innerHeight);

    // Internet Explorer 6 in Strict Mode
    else if (document.documentElement && document.documentElement.clientWidth)
        frame.size = CGSizeMake(_DOMWindow.document.documentElement.clientWidth, _DOMWindow.document.documentElement.clientHeight);

    // Internet Explorer X
    else
        frame.size = CGSizeMake(_DOMWindow.document.body.clientWidth, _DOMWindow.document.body.clientHeight);
        
    return frame;
}

//right now we hard code q, w, r and t as keys to propogate
//these aren't normal keycodes, they are with modifier key codes
//might be mac only, we should investigate futher later.
var KeyCodesToPrevent = {},
    CharacterKeysToPrevent = {},
    KeyCodesWithoutKeyPressEvents = { '8':1, '9':1, '16':1, '37':1, '38':1, '39':1, '40':1, '46':1, '33':1, '34':1 };

var CTRL_KEY_CODE   = 17;

@implementation CPDOMWindowBridge (Events)

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

/* @ignore */
- (void)_bridgeMouseEvent:(DOMEvent)aDOMEvent
{
    var theType = _overriddenEventType || aDOMEvent.type;
    
    // IE's event order is down, up, up, dblclick, so we have create these events artificially.
    if (theType === CPDOMEventDoubleClick)
    {
        _overriddenEventType = CPDOMEventMouseDown;
        [self _bridgeMouseEvent:aDOMEvent];

        _overriddenEventType = CPDOMEventMouseUp;
        [self _bridgeMouseEvent:aDOMEvent];
        
        _overriddenEventType = nil;
        
        return;         
    }

#ifndef DEBUG
    try
    {
#endif
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
        
        switch (theType)
        {
            case CPDOMEventMouseUp:     if(_mouseIsDown)
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
                                        
                                        break;
                                        
            case CPDOMEventMouseDown:   if (ExcludedDOMElements[sourceElement.tagName] && sourceElement != _DOMFocusElement)
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
                                        
                                        break;
                                        
            case CPDOMEventMouseMoved:  if (_DOMEventMode)
                                            return;

                                        event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseIsDown ? CPLeftMouseDragged : CPMouseMoved, location, modifierFlags, timestamp, windowNumber, nil, -1, 1, 0);
                                        
                                        break;
        }
        
        if (event)
        {
            event._DOMEvent = aDOMEvent;
            
            [CPApp sendEvent:event];
        }
            
        if (StopDOMEventPropagation)
            CPDOMEventStop(aDOMEvent);
            
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
}

/* @ignore */
- (void)_bridgeKeyEvent:(DOMEvent)aDOMEvent
{
#ifndef DEBUG
    try
    {
#endif
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
            case CPDOMEventKeyDown:     // Grab and store the keycode now since it is correct and consistent at this point.
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
            case CPDOMEventKeyPress:    
                                        // If the source of this event is our pasteboard element, then simply let it continue 
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
            
            case CPDOMEventKeyUp:       var keyCode = aDOMEvent.keyCode,
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
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
}

/* @ignore */
- (void)_bridgeScrollEvent:(DOMEvent)aDOMEvent
{
    if(!aDOMEvent)
        aDOMEvent = window.event;

#ifndef DEBUG
    try
    {
#endif
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
		
            var location = _CGPointMake((x + ((aDOMEvent.clientX - 8) / 15)), (y + ((aDOMEvent.clientY - 8) / 15)));}
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
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
}

/* @ignore */
- (void)_bridgeResizeEvent:(DOMEvent)aDOMEvent
{
#ifndef DEBUG
    try
    {
#endif
        // FIXME: This is not the right way to do this.
        // We should pay attention to mouse down and mouse up in conjunction with this.
        //window.liveResize = YES;
        
        var oldSize = _frame.size;
        
        // window.liveResize = YES?
        _frame = CPDOMWindowGetFrame(_DOMWindow);
        _contentBounds.size = CGSizeCreateCopy(_frame.size);
            
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
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
}

// DOM event properties used in mouse bridge code

// type
// clientX
// clientY
// timestamp
// target/srcElement
// shiftKey,ctrlKey,altKey,metaKey

/* @ignore */
- (void)_bridgeTouchEvent:(DOMEvent)aDOMEvent
{        
#ifndef DEBUG
    try
    {
#endif
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
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
    // handle touch cases specifically
}

/* @ignore */
- (void)_checkPasteboardElement
{
#ifndef DEBUG
    try
    {
#endif
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
#ifndef DEBUG
    }
    catch (anException)
    {
        objj_exception_report(anException, {path:@"CPDOMWindowBridge.j"});
    }
#endif
}

/* @ignore */
- (void)_clearPasteboardElement
{
    _DOMPasteboardElement.value = "";
    _DOMPasteboardElement.blur();
}

@end

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
