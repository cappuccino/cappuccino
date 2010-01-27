/*
 * CPPlatformWindow+DOM.j
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
 
 
/*
 * THIS DOCUMENTATION STOLEN DIRECTLY FROM GOOGLE CLOSURE (licensed under Apache 2)
 * 
 * Different web browsers have very different keyboard event handling. Most
 * importantly is that only certain browsers repeat keydown events:
 * IE, Opera, FF/Win32, and Safari 3 repeat keydown events.
 * FF/Mac and Safari 2 do not.
 *
 * For the purposes of this code, "Safari 3" means WebKit 525+, when WebKit
 * decided that they should try to match IE's key handling behavior.
 * Safari 3.0.4, which shipped with Leopard (WebKit 523), has the
 * Safari 2 behavior.
 *
 * Firefox, Safari, Opera prevent on keypress
 *
 * IE prevents on keydown
 *
 * Firefox does not fire keypress for shift, ctrl, alt
 * Firefox does fire keydown for shift, ctrl, alt, meta
 * Firefox does not repeat keydown for shift, ctrl, alt, meta
 *
 * Firefox does not fire keypress for up and down in an input
 *
 * Opera fires keypress for shift, ctrl, alt, meta
 * Opera does not repeat keypress for shift, ctrl, alt, meta
 *
 * Safari 2 and 3 do not fire keypress for shift, ctrl, alt
 * Safari 2 does not fire keydown for shift, ctrl, alt
 * Safari 3 *does* fire keydown for shift, ctrl, alt
 *
 * IE provides the keycode for keyup/down events and the charcode (in the
 * keycode field) for keypress.
 *
 * Mozilla provides the keycode for keyup/down and the charcode for keypress
 * unless it's a non text modifying key in which case the keycode is provided.
 *
 * Safari 3 provides the keycode and charcode for all events.
 *
 * Opera provides the keycode for keyup/down event and either the charcode or
 * the keycode (in the keycode field) for keypress events.
 *
 * Firefox x11 doesn't fire keydown events if a another key is already held down
 * until the first key is released. This can cause a key event to be fired with
 * a keyCode for the first key and a charCode for the second key.
 *
 * Safari 2 in keypress (not supported)
 *
 *        charCode keyCode which
 * ENTER:       13      13    13
 * F1:       63236   63236 63236
 * F8:       63243   63243 63243
 * ...
 * p:          112     112   112
 * P:           80      80    80
 *
 * Firefox, keypress:
 *
 *        charCode keyCode which
 * ENTER:        0      13    13
 * F1:           0     112     0
 * F8:           0     119     0
 * ...
 * p:          112       0   112
 * P:           80       0    80
 *
 * Opera, Mac+Win32, keypress:
 *
 *         charCode keyCode which
 * ENTER: undefined      13    13
 * F1:    undefined     112     0
 * F8:    undefined     119     0
 * ...
 * p:     undefined     112   112
 * P:     undefined      80    80
 *
 * IE7, keydown
 *
 *         charCode keyCode     which
 * ENTER: undefined      13 undefined
 * F1:    undefined     112 undefined
 * F8:    undefined     119 undefined
 * ...
 * p:     undefined      80 undefined
 * P:     undefined      80 undefined
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

@import "CPEvent.j"
@import "CPCompatibility.j"

@import "CPDOMWindowLayer.j"

@import "CPPlatform.j"
@import "CPPlatformWindow.j"
@import "CPPlatformWindow+DOMKeys.j"

#import "../../CoreGraphics/CGGeometry.h"

// List of all open native windows
var PlatformWindows = [CPSet set];

// Define up here so compressor knows about em.
var CPDOMEventGetClickCount,
    CPDOMEventStop,
    StopDOMEventPropagation;

//right now we hard code q, w, r and t as keys to propogate
//these aren't normal keycodes, they are with modifier key codes
//might be mac only, we should investigate futher later.
var KeyCodesToPrevent = {},
    CharacterKeysToPrevent = {},
    MozKeyCodeToKeyCodeMap = {
        61: 187,  // =, equals
        59: 186   // ;, semicolon
    };

KeyCodesToPrevent[CPKeyCodes.A] = YES;

var supportsNativeDragAndDrop = [CPPlatform supportsDragAndDrop];

@implementation CPPlatformWindow (DOM)

- (id)_init
{
    self = [super init];

    if (self)
    {
        _DOMWindow = window;
        _contentRect = _CGRectMakeZero();

        _windowLevels = [];
        _windowLayers = [CPDictionary dictionary];

        [self registerDOMWindow];
        [self updateFromNativeContentRect];

        _charCodes = {};
    }

    return self;
}

- (CGRect)nativeContentRect
{
    if (!_DOMWindow)
        return [self contentRect];

    if (_DOMWindow.cpFrame)
        return _DOMWindow.cpFrame();

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

- (void)updateNativeContentRect
{
    if (!_DOMWindow)
        return;

    if (typeof _DOMWindow["cpSetFrame"] === "function")
        return _DOMWindow.cpSetFrame([self contentRect]);

    var origin = [self contentRect].origin,
        nativeOrigin = [self nativeContentRect].origin;

    if (origin.x !== nativeOrigin.x || origin.y !== nativeOrigin.y)
    {
        _DOMWindow.moveBy(origin.x - nativeOrigin.x, origin.y - nativeOrigin.y);
    }

    var size = [self contentRect].size,
        nativeSize = [self nativeContentRect].size;

    if (size.width !== nativeSize.width || size.height !== nativeSize.height)
    {
        _DOMWindow.resizeBy(size.width - nativeSize.width, size.height - nativeSize.height);
    }
}

- (void)orderBack:(id)aSender
{
    if (_DOMWindow)
        _DOMWindow.blur();
}

- (void)createDOMElements
{
    var theDocument = _DOMWindow.document;

    // This guy fixes an issue in Firefox where if you focus the URL field, we stop getting key events
    _DOMFocusElement = theDocument.createElement("input");

    _DOMFocusElement.style.position = "absolute";
    _DOMFocusElement.style.zIndex = "-1000";
    _DOMFocusElement.style.opacity = "0";
    _DOMFocusElement.style.filter = "alpha(opacity=0)";

    _DOMBodyElement.appendChild(_DOMFocusElement);

    // Create Native Pasteboard handler.
    _DOMPasteboardElement = theDocument.createElement("textarea");

    _DOMPasteboardElement.style.position = "absolute";
    _DOMPasteboardElement.style.top = "-10000px";
    _DOMPasteboardElement.style.zIndex = "999";

    _DOMBodyElement.appendChild(_DOMPasteboardElement);

    // Make sure the pastboard element is blurred.
    _DOMPasteboardElement.blur();
}

- (void)platformDidClearBodyElement:(CPNotification)aNotification
{
    [self createDOMElements];
}

- (void)registerDOMWindow
{
    var theDocument = _DOMWindow.document;

    _DOMBodyElement = theDocument.getElementById("cappuccino-body") || theDocument.body;

    // FIXME: Always do this?
    if ([CPPlatform supportsDragAndDrop])
        _DOMBodyElement.style["-khtml-user-select"] = "none";

    _DOMBodyElement.webkitTouchCallout = "none";

    [self createDOMElements];

    if (window === _DOMWindow)
        [[CPNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(platformDidClearBodyElement:)
                   name:CPPlatformDidClearBodyElementNotification
                 object:CPPlatform];

    [self _addLayers];

    var theClass = [self class],

        dragEventImplementation = class_getMethodImplementation(theClass, @selector(dragEvent:)),
        dragEventCallback = function (anEvent) { dragEventImplementation(self, nil, anEvent); },

        resizeEventSelector = @selector(resizeEvent:),
        resizeEventImplementation = class_getMethodImplementation(theClass, resizeEventSelector),
        resizeEventCallback = function (anEvent) { resizeEventImplementation(self, nil, anEvent); },

        copyEventSelector = @selector(copyEvent:),
        copyEventImplementation = class_getMethodImplementation(theClass, copyEventSelector),
        copyEventCallback = function (anEvent) {copyEventImplementation(self, nil, anEvent); },

        pasteEventSelector = @selector(pasteEvent:),
        pasteEventImplementation = class_getMethodImplementation(theClass, pasteEventSelector),
        pasteEventCallback = function (anEvent) {pasteEventImplementation(self, nil, anEvent); },

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
        if ([CPPlatform supportsDragAndDrop])
        {
            theDocument.addEventListener("dragstart", dragEventCallback, NO);
            theDocument.addEventListener("drag", dragEventCallback, NO);
            theDocument.addEventListener("dragend", dragEventCallback, NO);
            theDocument.addEventListener("dragover", dragEventCallback, NO);
            theDocument.addEventListener("dragleave", dragEventCallback, NO);
            theDocument.addEventListener("drop", dragEventCallback, NO);
        }

        theDocument.addEventListener("mouseup", mouseEventCallback, NO);
        theDocument.addEventListener("mousedown", mouseEventCallback, NO);
        theDocument.addEventListener("mousemove", mouseEventCallback, NO);

        theDocument.addEventListener("beforecopy", copyEventCallback, NO);
        theDocument.addEventListener("beforecut", copyEventCallback, NO);
        theDocument.addEventListener("beforepaste", pasteEventCallback, NO);

        theDocument.addEventListener("keyup", keyEventCallback, NO);
        theDocument.addEventListener("keydown", keyEventCallback, NO);
        theDocument.addEventListener("keypress", keyEventCallback, NO);

        theDocument.addEventListener("touchstart", touchEventCallback, NO);
        theDocument.addEventListener("touchend", touchEventCallback, NO);
        theDocument.addEventListener("touchmove", touchEventCallback, NO);
        theDocument.addEventListener("touchcancel", touchEventCallback, NO);

        _DOMWindow.addEventListener("DOMMouseScroll", scrollEventCallback, NO);
        _DOMWindow.addEventListener("mousewheel", scrollEventCallback, NO);

        _DOMWindow.addEventListener("resize", resizeEventCallback, NO);        

        _DOMWindow.addEventListener("unload", function()
        {
            [self updateFromNativeContentRect];
            [self _removeLayers];

            theDocument.removeEventListener("mouseup", mouseEventCallback, NO);
            theDocument.removeEventListener("mousedown", mouseEventCallback, NO);
            theDocument.removeEventListener("mousemove", mouseEventCallback, NO);

            theDocument.removeEventListener("keyup", keyEventCallback, NO);
            theDocument.removeEventListener("keydown", keyEventCallback, NO);
            theDocument.removeEventListener("keypress", keyEventCallback, NO);

            theDocument.removeEventListener("beforecopy", copyEventCallback, NO);
            theDocument.removeEventListener("beforecut", copyEventCallback, NO);
            theDocument.removeEventListener("beforepaste", pasteEventCallback, NO);

            theDocument.removeEventListener("touchstart", touchEventCallback, NO);
            theDocument.removeEventListener("touchend", touchEventCallback, NO);
            theDocument.removeEventListener("touchmove", touchEventCallback, NO);

            _DOMWindow.removeEventListener("resize", resizeEventCallback, NO);

            //FIXME: does firefox really need a different value?
            _DOMWindow.removeEventListener("DOMMouseScroll", scrollEventCallback, NO);
            _DOMWindow.removeEventListener("mousewheel", scrollEventCallback, NO);

            //_DOMWindow.removeEventListener("beforeunload", this, NO);

            [PlatformWindows removeObject:self];

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
        
        _DOMBodyElement.ondrag = function () { return NO; };
        _DOMBodyElement.onselectstart = function () { return _DOMWindow.event.srcElement === _DOMPasteboardElement; };

        _DOMWindow.attachEvent("onbeforeunload", function()
        {
            [self updateFromNativeContentRect];
            [self _removeLayers];

            theDocument.detachEvent("onmouseup", mouseEventCallback);
            theDocument.detachEvent("onmousedown", mouseEventCallback);
            theDocument.detachEvent("onmousemove", mouseEventCallback);
            theDocument.detachEvent("ondblclick", mouseEventCallback);

            theDocument.detachEvent("onkeyup", keyEventCallback);
            theDocument.detachEvent("onkeydown", keyEventCallback);
            theDocument.detachEvent("onkeypress", keyEventCallback);

            _DOMWindow.detachEvent("onresize", resizeEventCallback);

            _DOMWindow.onmousewheel = NULL;
            theDocument.onmousewheel = NULL;

            _DOMBodyElement.ondrag = NULL;
            _DOMBodyElement.onselectstart = NULL;

            //_DOMWindow.removeEvent("beforeunload", this);

            [PlatformWindows removeObject:self];

            self._DOMWindow = nil;
        }, NO);
    }
}

+ (CPSet)visiblePlatformWindows
{
    return PlatformWindows;
}

- (void)orderFront:(id)aSender
{
    if (_DOMWindow)
        return _DOMWindow.focus();

    _DOMWindow = window.open("", "_blank", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left=" + _CGRectGetMinX(_contentRect) + ",top=" + _CGRectGetMinY(_contentRect) + ",width=" + _CGRectGetWidth(_contentRect) + ",height=" + _CGRectGetHeight(_contentRect));

    [PlatformWindows addObject:self];

    // FIXME: cpSetFrame?
    _DOMWindow.document.write("<html><head></head><body style = 'background-color:transparent;'></body></html>");
    _DOMWindow.document.close();

    if (![CPPlatform isBrowser])
    {
        _DOMWindow.cpWindowNumber = [self._only windowNumber];
        _DOMWindow.cpSetFrame(_contentRect);
        _DOMWindow.cpSetLevel(_level);
        _DOMWindow.cpSetHasShadow(_hasShadow);
        _DOMWindow.cpSetShadowStyle(_shadowStyle);
    }

    _DOMBodyElement.style.cursor = [[CPCursor currentCursor] _cssString];

    [self registerDOMWindow];
}

- (void)orderOut:(id)aSender
{
    if (!_DOMWindow)
        return;

    _DOMWindow.close();
}

- (void)dragEvent:(DOMEvent)aDOMEvent
{
    var type = aDOMEvent.type,
        dragServer = [CPDragServer sharedDragServer],
        location = _CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY),
        pasteboard = [_CPDOMDataTransferPasteboard DOMDataTransferPasteboard];

    [pasteboard _setDataTransfer:aDOMEvent.dataTransfer];

    if (aDOMEvent.type === "dragstart")
    {
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

        [pasteboard _setPasteboard:[dragServer draggingPasteboard]];

        var draggedWindow = [dragServer draggedWindow],
            draggedWindowFrame = [draggedWindow frame],
            DOMDragElement = draggedWindow._DOMElement;

        DOMDragElement.style.left = -_CGRectGetWidth(draggedWindowFrame) + "px";
        DOMDragElement.style.top = -_CGRectGetHeight(draggedWindowFrame) + "px";

        _DOMBodyElement.appendChild(DOMDragElement);

        var draggingOffset = [dragServer draggingOffset];

        aDOMEvent.dataTransfer.setDragImage(DOMDragElement, draggingOffset.width, draggingOffset.height);
        aDOMEvent.dataTransfer.effectAllowed = "all";

        [dragServer draggingStartedInPlatformWindow:self globalLocation:[CPPlatform isBrowser] ? location : _CGPointMake(aDOMEvent.screenX, aDOMEvent.screenY)];
    }

    else if (type === "drag")
    {
        var y = aDOMEvent.screenY;

        if (CPFeatureIsCompatible(CPHTML5DragAndDropSourceYOffBy1))
            y -= 1;

        [dragServer draggingSourceUpdatedWithGlobalLocation:[CPPlatform isBrowser] ? location : _CGPointMake(aDOMEvent.screenX, y)];
    }

    else if (type === "dragover" || type === "dragleave")
    {
        if (aDOMEvent.preventDefault)
            aDOMEvent.preventDefault();

        var dropEffect = "none",
            dragOperation = [dragServer draggingUpdatedInPlatformWindow:self location:location];

        if (dragOperation === CPDragOperationMove || dragOperation === CPDragOperationGeneric || dragOperation === CPDragOperationPrivate)
            dropEffect = "move";

        else if (dragOperation === CPDragOperationCopy)
            dropEffect = "copy";

        else if (dragOperation === CPDragOperationLink)
            dropEffect = "link";

        aDOMEvent.dataTransfer.dropEffect = dropEffect;
    }

    else if (type === "dragend")
    {
        var dropEffect = aDOMEvent.dataTransfer.dropEffect;

        if (dropEffect === "move")
            dragOperation = CPDragOperationMove;
        else if (dropEffect === "copy")
            dragOperation = CPDragOperationCopy;
        else if (dropEffect === "link")
            dragOperation = CPDragOperationLink;
        else
            dragOperation = CPDragOperationNone;

        [dragServer draggingEndedInPlatformWindow:self globalLocation:[CPPlatform isBrowser] ? location : _CGPointMake(aDOMEvent.screenX, aDOMEvent.screenY) operation:dragOperation];
    }

    else //if (type === "drop")
    {
        [dragServer performDragOperationInPlatformWindow:self];

        // W3C Model
        if (aDOMEvent.preventDefault)
            aDOMEvent.preventDefault();

        if (aDOMEvent.stopPropagation)
            aDOMEvent.stopPropagation();
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
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

    //We want to stop propagation if this is a command key AND this character or keycode has been added to our blacklist    
    StopDOMEventPropagation = !!(!(modifierFlags & (CPControlKeyMask | CPCommandKeyMask)) ||
                              CharacterKeysToPrevent[String.fromCharCode(aDOMEvent.keyCode || aDOMEvent.charCode).toLowerCase()] ||
                              KeyCodesToPrevent[aDOMEvent.keyCode]);

    var isNativePasteEvent = NO,
        isNativeCopyOrCutEvent = NO,
        overrideCharacters = nil;

    switch (aDOMEvent.type)
    {
        case "keydown":     // Grab and store the keycode now since it is correct and consistent at this point.
                            if (aDOMEvent.keyCode.keyCode in MozKeyCodeToKeyCodeMap)
                                _keyCode = MozKeyCodeToKeyCodeMap[aDOMEvent.keyCode];
                            else
                                _keyCode = aDOMEvent.keyCode;

                            var characters = String.fromCharCode(_keyCode).toLowerCase();
                            overrideCharacters = (modifierFlags & CPShiftKeyMask || _capsLockActive) ? characters.toUpperCase() : characters;

                            // check for caps lock state
                            if (_keyCode === CPKeyCodes.CAPS_LOCK)
                                _capsLockActive = YES;

                            if (modifierFlags & (CPControlKeyMask | CPCommandKeyMask))
                            {
                                //we are simply going to skip all keypress events that use cmd/ctrl key
                                //this lets us be consistent in all browsers and send on the keydown
                                //which means we can cancel the event early enough, but only if sendEvent needs to

                                var eligibleForCopyPaste = [self _validateCopyCutOrPasteEvent:aDOMEvent flags:modifierFlags];

                                // If this could be a native PASTE event, then we need to further examine it before 
                                // sending a CPEvent.  Select our element to see if anything gets pasted in it.
                                if (characters === "v" && eligibleForCopyPaste)
                                {
                                    if (!_ignoreNativePastePreparation)
                                    {
                                        _DOMPasteboardElement.select();
                                        _DOMPasteboardElement.value = "";
                                    }

                                    isNativePasteEvent = YES;
                                }

                                // However, of this could be a native COPY event, we need to let the normal event-process take place so it 
                                // can capture our internal Cappuccino pasteboard.
                                else if ((characters == "c" || characters == "x") && eligibleForCopyPaste)
                                {
                                    isNativeCopyOrCutEvent = YES;

                                    if (_ignoreNativeCopyOrCutEvent)
                                        break;
                                }
                            }
                            else if (CPKeyCodes.firesKeyPressEvent(_keyCode, _lastKey, aDOMEvent.shiftKey, aDOMEvent.ctrlKey, aDOMEvent.altKey))
                            {
                                // this branch is taken by events which fire keydown, keypress, and keyup.
                                // this is the only time we'll ALLOW character keys to propagate (needed for text fields)
                                StopDOMEventPropagation = NO;
                                break;
                            }
                            else
                            {
                                //this branch is taken by "remedial" key events
                                // In this state we continue to keypress and send the CPEvent
                            }
                            
        case "keypress":
                            // we unconditionally break on keypress events with modifiers, 
                            // because we forced the event to be sent on the keydown 
                            if (aDOMEvent.type === "keypress" && (modifierFlags & (CPControlKeyMask | CPCommandKeyMask)))
                                break;

                            var keyCode = _keyCode,
                                charCode = aDOMEvent.keyCode || aDOMEvent.charCode,
                                isARepeat = (_charCodes[keyCode] != nil);

                            _lastKey = keyCode;
                            _charCodes[keyCode] = charCode;

                            var characters = overrideCharacters || String.fromCharCode(charCode),
                                charactersIgnoringModifiers = characters.toLowerCase();

                            // Safari won't send proper capitalization during cmd-key events
                            if (!overrideCharacters && (modifierFlags & CPCommandKeyMask) && ((modifierFlags & CPShiftKeyMask) || _capsLockActive))
                                characters = characters.toUpperCase();

                            event = [CPEvent keyEventWithType:CPKeyDown location:location modifierFlags:modifierFlags
                                        timestamp:timestamp windowNumber:windowNumber context:nil
                                        characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:keyCode];

                            if (isNativePasteEvent)
                            {
                                _pasteboardKeyDownEvent = event;
                                window.setNativeTimeout(function () { [self _checkPasteboardElement] }, 0);
                            }

                            break;
        
        case "keyup":       var keyCode = aDOMEvent.keyCode,
                                charCode = _charCodes[keyCode];
                            
                            _keyCode = -1;
                            _lastKey = -1;
                            _charCodes[keyCode] = nil;
                            _ignoreNativeCopyOrCutEvent = NO;
                            _ignoreNativePastePreparation = NO;

                            // check for caps lock state
                            if (keyCode === CPKeyCodes.CAPS_LOCK)
                                _capsLockActive = NO;

                            var characters = String.fromCharCode(charCode),
                                charactersIgnoringModifiers = characters.toLowerCase();
                                
                            if (!(modifierFlags & CPShiftKeyMask) && (modifierFlags & CPCommandKeyMask) && !_capsLockActive)
                                characters = charactersIgnoringModifiers;
                            
                            event = [CPEvent keyEventWithType:CPKeyUp location:location modifierFlags:modifierFlags
                                        timestamp: timestamp windowNumber:windowNumber context:nil
                                        characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:NO keyCode:keyCode];
                            break;
    }

    if (event && !isNativePasteEvent)
    {
        event._DOMEvent = aDOMEvent;

        [CPApp sendEvent:event];

        if (isNativeCopyOrCutEvent)
        {
            // If this is a native copy event, then check if the pasteboard has anything in it.
            [self _primePasteboardElement];
        }
    }

    if (StopDOMEventPropagation)
        CPDOMEventStop(aDOMEvent, self);

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)copyEvent:(DOMEvent)aDOMEvent
{
    if ([self _validateCopyCutOrPasteEvent:aDOMEvent flags:CPPlatformActionKeyMask] && !_ignoreNativeCopyOrCutEvent)
    {
        //we have to send out a fake copy or cut event so that we can force the copy/cut mechanisms to take place
        var cut = aDOMEvent.type === "beforecut",
            keyCode = cut ? CPKeyCodes.X : CPKeyCodes.C,
            characters = cut ? "x" : "c",
            timestamp = aDOMEvent.timeStamp ? aDOMEvent.timeStamp : new Date(),
            windowNumber = [[CPApp keyWindow] windowNumber],
            modifierFlags = CPPlatformActionKeyMask;

        event = [CPEvent keyEventWithType:CPKeyDown location:location modifierFlags:modifierFlags
                    timestamp:timestamp windowNumber:windowNumber context:nil
                    characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];

        event._DOMEvent = aDOMEvent;
        [CPApp sendEvent:event];

        [self _primePasteboardElement];

        //then we have to IGNORE the real keyboard event to prevent a double copy
        //safari also sends the beforecopy event twice, so we additionally check here and prevent two events
        _ignoreNativeCopyOrCutEvent = YES;
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)pasteEvent:(DOMEvent)aDOMEvent
{
    if ([self _validateCopyCutOrPasteEvent:aDOMEvent flags:CPPlatformActionKeyMask])
    {
        _DOMPasteboardElement.focus();
        _DOMPasteboardElement.select();
        _DOMPasteboardElement.value = "";
        _ignoreNativePastePreparation = YES;
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)_validateCopyCutOrPasteEvent:(DOMEvent)aDOMEvent flags:(unsigned)modifierFlags
{
    return (
            ((aDOMEvent.target || aDOMEvent.srcElement).nodeName.toUpperCase() !== "INPUT" &&
             (aDOMEvent.target || aDOMEvent.srcElement).nodeName.toUpperCase() !== "TEXTAREA"
            ) || aDOMEvent.target === _DOMPasteboardElement
           ) &&
            (modifierFlags & CPPlatformActionKeyMask);
}

- (void)_primePasteboardElement
{
    var pasteboard = [CPPasteboard generalPasteboard],
        types = [pasteboard types];

    if (types.length)
    {
        if ([types indexOfObjectIdenticalTo:CPStringPboardType] != CPNotFound)
            _DOMPasteboardElement.value = [pasteboard stringForType:CPStringPboardType];
        else
            _DOMPasteboardElement.value = [pasteboard _generateStateUID];

        _DOMPasteboardElement.focus();
        _DOMPasteboardElement.select();

        window.setNativeTimeout(function() { [self _clearPasteboardElement]; }, 0);
    }
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

    var theWindow = [self hitTest:location];

    if (!theWindow)
        return;

    var windowNumber = [theWindow windowNumber];

    location = [theWindow convertBridgeToBase:location];

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
        CPDOMEventStop(aDOMEvent, self);

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)resizeEvent:(DOMEvent)aDOMEvent
{
    // FIXME: This is not the right way to do this.
    // We should pay attention to mouse down and mouse up in conjunction with this.
    //window.liveResize = YES;

    if ([CPPlatform isBrowser])
        [CPApp._activeMenu cancelTracking];

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
            [windows[windowCount] resizeWithOldPlatformWindowSize:oldSize];
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
        
        [self mouseEvent:newEvent];
    
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
    if (type === @"dblclick")
    {
        _overriddenEventType = CPDOMEventMouseDown;
        [self mouseEvent:aDOMEvent];

        _overriddenEventType = CPDOMEventMouseUp;
        [self mouseEvent:aDOMEvent];

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
        location = [CPApp._windows[windowNumber] convertPlatformWindowToBase:location];

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
        if (sourceElement.tagName === "INPUT" && sourceElement != _DOMFocusElement)
        {
            if ([CPPlatform supportsDragAndDrop])
            {
                _DOMBodyElement.setAttribute("draggable", "false");
                _DOMBodyElement.style["-khtml-user-drag"] = "none";
            }

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
        else if ([CPPlatform supportsDragAndDrop])
        {
            _DOMBodyElement.setAttribute("draggable", "true");
            _DOMBodyElement.style["-khtml-user-drag"] = "element";
        }

        event = _CPEventFromNativeMouseEvent(aDOMEvent, CPLeftMouseDown, location, modifierFlags, timestamp, windowNumber, nil, -1, CPDOMEventGetClickCount(_lastMouseDown, timestamp, location), 0);
                    
        _mouseIsDown = YES;
        _lastMouseDown = event;
    }
    
    else // if (type === "mousemove" || type === "drag")
    {
        if (_DOMEventMode)
            return;

        event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseIsDown ? CPLeftMouseDragged : CPMouseMoved, location, modifierFlags, timestamp, windowNumber, nil, -1, 1, 0);
    }

    var isDragging = [[CPDragServer sharedDragServer] isDragging];

    if (event && (!isDragging || !supportsNativeDragAndDrop))
    {
        event._DOMEvent = aDOMEvent;
        
        [CPApp sendEvent:event];
    }

    if (StopDOMEventPropagation && (!supportsNativeDragAndDrop || type !== "mousedown" && !isDragging))
        CPDOMEventStop(aDOMEvent, self);

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
    [CPPlatform initializeScreenIfNecessary];

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

- (void)_removeLayers
{
    var levels = _windowLevels,
        layers = _windowLayers,
        levelCount = levels.length;

    while (levelCount--)
    {
        var layer = [layers objectForKey:levels[levelCount]];

        _DOMBodyElement.removeChild(layer._DOMElement);
    }
}

- (void)_addLayers
{
    var levels = _windowLevels,
        layers = _windowLayers,
        levelCount = levels.length;

    while (levelCount--)
    {
        var layer = [layers objectForKey:levels[levelCount]];

        _DOMBodyElement.appendChild(layer._DOMElement);
    }
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

            if ([theWindow _sharesChromeWithPlatformWindow])
                return [theWindow _dragHitTest:aPoint pasteboard:aPasteboard];

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

- (BOOL)_willPropagateCurrentDOMEvent
{
    return !StopDOMEventPropagation;
}

- (CPWindow)hitTest:(CPPoint)location
{
    if (self._only) 
        return self._only;

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

/*!
    When using command (mac) or control (windows), keys are propagated to the browser by default.  
    To prevent a character key from propagating (to prevent its default action, and instead use it
    in your own application), use these methods. These methods are additive -- the list builds until you clear it.
    
    @param characters a list of characters to stop propagating keypresses to the browser.
*/
+ (void)preventCharacterKeysFromPropagating:(CPArray)characters
{
    for(var i=characters.length; i>0; i--)
        CharacterKeysToPrevent[""+characters[i-1].toLowerCase()] = YES;
}

/*!
    @param character a character to stop propagating keypresses to the browser.
*/
+ (void)preventCharacterKeyFromPropagating:(CPString)character
{
    CharacterKeysToPrevent[character.toLowerCase()] = YES;
}

/*!
    Clear the list of characters for which we are not sending keypresses to the browser.
*/
+ (void)clearCharacterKeysToPreventFromPropagating
{
    CharacterKeysToPrevent = {};
}

/*!
    Prevent these keyCodes from sending their keypresses to the browser.
    @param keyCodes an array of keycodes to prevent propagation.
*/
+ (void)preventKeyCodesFromPropagating:(CPArray)keyCodes
{
    for(var i=keyCodes.length; i>0; i--)
        KeyCodesToPrevent[keyCodes[i-1]] = YES;
}

/*!
    Prevent this keyCode from sending its key events to the browser.
    @param keyCode a keycode to prevent propagation.
*/
+ (void)preventKeyCodeFromPropagating:(CPString)keyCode
{
    KeyCodesToPrevent[keyCode] = YES;
}

/*!
    Clear the list of keyCodes for which we are not sending keypresses to the browser.
*/
+ (void)clearKeyCodesToPreventFromPropagating
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

var CPDOMEventStop = function(aDOMEvent, aPlatformWindow)
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
        aPlatformWindow._DOMFocusElement.focus();
        aPlatformWindow._DOMFocusElement.blur();
    }
}

function CPWindowObjectList()
{
    var platformWindow = [CPPlatformWindow primaryPlatformWindow],
        levels = platformWindow._windowLevels,
        layers = platformWindow._windowLayers,
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
    var platformWindow = [CPPlatformWindow primaryPlatformWindow],
        levels = platformWindow._windowLevels,
        layers = platformWindow._windowLayers,
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
