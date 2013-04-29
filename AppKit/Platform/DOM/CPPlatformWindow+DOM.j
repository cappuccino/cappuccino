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
@import <Foundation/CPSet.j>
@import <Foundation/CPTimer.j>

@import "CPCursor.j"
@import "CPCompatibility.j"
@import "CPDOMWindowLayer.j"
@import "CPDragServer_Constants.j"
@import "CPEvent.j"
@import "CPPasteboard.j"
@import "CPPlatform.j"
@import "CPPlatformWindow.j"
@import "CPPlatformWindow+DOMKeys.j"
@import "CPText.j"
@import "CPWindow_Constants.j"

@class CPDragServer
@class _CPToolTip

@global CPApp
@global _CPRunModalLoop

// List of all open native windows
var PlatformWindows = [CPSet set];

// Define up here so compressor knows about them.
var CPDOMEventGetClickCount,
    CPDOMEventStop,
    StopDOMEventPropagation,
    StopContextMenuDOMEventPropagation;

var KeyCodesToPrevent = {},
    CharacterKeysToPrevent = {},
    KeyCodesToAllow = {},
    MozKeyCodeToKeyCodeMap = {
        61: 187,  // =, equals
        59: 186   // ;, semicolon
    },
    KeyCodesToUnicodeMap = {};

KeyCodesToPrevent[CPKeyCodes.A] = YES;

KeyCodesToAllow[CPKeyCodes.F1] = YES;
KeyCodesToAllow[CPKeyCodes.F2] = YES;
KeyCodesToAllow[CPKeyCodes.F3] = YES;
KeyCodesToAllow[CPKeyCodes.F4] = YES;
KeyCodesToAllow[CPKeyCodes.F5] = YES;
KeyCodesToAllow[CPKeyCodes.F6] = YES;
KeyCodesToAllow[CPKeyCodes.F7] = YES;
KeyCodesToAllow[CPKeyCodes.F8] = YES;
KeyCodesToAllow[CPKeyCodes.F9] = YES;
KeyCodesToAllow[CPKeyCodes.F10] = YES;
KeyCodesToAllow[CPKeyCodes.F11] = YES;
KeyCodesToAllow[CPKeyCodes.F12] = YES;

KeyCodesToUnicodeMap[CPKeyCodes.BACKSPACE]              = CPDeleteCharacter;
KeyCodesToUnicodeMap[CPKeyCodes.DELETE]                 = CPDeleteFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.TAB]                    = CPTabCharacter;
KeyCodesToUnicodeMap[CPKeyCodes.ENTER]                  = CPCarriageReturnCharacter;
KeyCodesToUnicodeMap[CPKeyCodes.ESC]                    = CPEscapeFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.PAGE_UP]                = CPPageUpFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.PAGE_DOWN]              = CPPageDownFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.LEFT]                   = CPLeftArrowFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.UP]                     = CPUpArrowFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.RIGHT]                  = CPRightArrowFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.DOWN]                   = CPDownArrowFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.HOME]                   = CPHomeFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.END]                    = CPEndFunctionKey;
KeyCodesToUnicodeMap[CPKeyCodes.SEMICOLON]              = ";";
KeyCodesToUnicodeMap[CPKeyCodes.DASH]                   = "-";
KeyCodesToUnicodeMap[CPKeyCodes.EQUALS]                 = "=";
KeyCodesToUnicodeMap[CPKeyCodes.COMMA]                  = ",";
KeyCodesToUnicodeMap[CPKeyCodes.PERIOD]                 = ".";
KeyCodesToUnicodeMap[CPKeyCodes.SLASH]                  = "/";
KeyCodesToUnicodeMap[CPKeyCodes.APOSTROPHE]             = "`";
KeyCodesToUnicodeMap[CPKeyCodes.SINGLE_QUOTE]           = "'";
KeyCodesToUnicodeMap[CPKeyCodes.OPEN_SQUARE_BRACKET]    = "[";
KeyCodesToUnicodeMap[CPKeyCodes.BACKSLASH]              = "\\";
KeyCodesToUnicodeMap[CPKeyCodes.CLOSE_SQUARE_BRACKET]   = "]";

var ModifierKeyCodes = [
        CPKeyCodes.META,
        CPKeyCodes.WEBKIT_RIGHT_META,
        CPKeyCodes.MAC_FF_META,
        CPKeyCodes.CTRL,
        CPKeyCodes.ALT,
        CPKeyCodes.SHIFT
    ],
    supportsNativeDragAndDrop = [CPPlatform supportsDragAndDrop];

var resizeTimer = nil;

#if PLATFORM(DOM)
@implementation CPPlatformWindow (DOM)

- (id)_init
{
    self = [super init];

    if (self)
    {
        _DOMWindow = window;
        _contentRect = CGRectMakeZero();

        _windowLevels = [];
        _windowLayers = @{};

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

    var contentRect = CGRectMakeZero();

    if (window.screenTop)
        contentRect.origin = CGPointMake(_DOMWindow.screenLeft, _DOMWindow.screenTop);

    else if (window.screenX)
        contentRect.origin = CGPointMake(_DOMWindow.screenX, _DOMWindow.screenY);

    // Safari, Mozilla, Firefox, and Opera
    if (_DOMWindow.innerWidth)
        contentRect.size = CGSizeMake(_DOMWindow.innerWidth, _DOMWindow.innerHeight);

    // Internet Explorer 6 in Strict Mode
    else if (document.documentElement && document.documentElement.clientWidth)
        contentRect.size = CGSizeMake(_DOMWindow.document.documentElement.clientWidth, _DOMWindow.document.documentElement.clientHeight);

    // Internet Explorer X
    else
        contentRect.size = CGSizeMake(_DOMWindow.document.body.clientWidth, _DOMWindow.document.body.clientHeight);

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

- (void)orderBack:(CPWindow)aWindow
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
    _DOMFocusElement.className = "cpdontremove";

    _DOMBodyElement.appendChild(_DOMFocusElement);

    // Create Native Pasteboard handler.
    _DOMPasteboardElement = theDocument.createElement("textarea");

    _DOMPasteboardElement.style.position = "absolute";
    _DOMPasteboardElement.style.top = "-10000px";
    _DOMPasteboardElement.style.zIndex = "999";
    _DOMPasteboardElement.className = "cpdontremove";

    _DOMBodyElement.appendChild(_DOMPasteboardElement);

    // Make sure the pastboard element is blurred.
    _DOMPasteboardElement.blur();

    // Create a full screen div to protect against iframes and other elements
    // from consuming events during tracking
    // FIXME: multiple windows
    _DOMEventGuard = theDocument.createElement("div");
    _DOMEventGuard.style.position = "absolute";
    _DOMEventGuard.style.top = "0px";
    _DOMEventGuard.style.left = "0px";
    _DOMEventGuard.style.width = "100%";
    _DOMEventGuard.style.height = "100%";
    _DOMEventGuard.style.zIndex = "999";
    _DOMEventGuard.style.display = "none";
    _DOMEventGuard.className = "cpdontremove";
    _DOMBodyElement.appendChild(_DOMEventGuard);

    // We get scrolling deltas from this element
    _DOMScrollingElement = theDocument.createElement("div");
    _DOMScrollingElement.style.position = "absolute";
    _DOMScrollingElement.style.visibility = "hidden";
    _DOMScrollingElement.style.zIndex = @"999";
    _DOMScrollingElement.style.height = "60px";
    _DOMScrollingElement.style.width = "60px";
    _DOMScrollingElement.style.overflow = "scroll";
    //_DOMScrollingElement.style.backgroundColor = "rgba(0,0,0,1.0)"; // debug help.
    _DOMScrollingElement.style.opacity = "0";
    _DOMScrollingElement.style.filter = "alpha(opacity=0)";
    _DOMScrollingElement.className = "cpdontremove";
    _DOMBodyElement.appendChild(_DOMScrollingElement);

    var _DOMInnerScrollingElement = theDocument.createElement("div");
    _DOMInnerScrollingElement.style.width = "400px";
    _DOMInnerScrollingElement.style.height = "400px";
    _DOMScrollingElement.appendChild(_DOMInnerScrollingElement);

    // Set an initial scroll offset
    _DOMScrollingElement.scrollTop = 150;
    _DOMScrollingElement.scrollLeft = 150;
}

- (void)registerDOMWindow
{
    var theDocument = _DOMWindow.document;

    _DOMBodyElement = theDocument.getElementById("cappuccino-body") || theDocument.body;

    // FIXME: Always do this?
    if (supportsNativeDragAndDrop)
        _DOMBodyElement.style["-khtml-user-select"] = "none";

    _DOMBodyElement.webkitTouchCallout = "none";

    [self createDOMElements];
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

        contextMenuEventSelector = @selector(contextMenuEvent:),
        contextMenuEventImplementation = class_getMethodImplementation(theClass, contextMenuEventSelector),
        contextMenuEventCallback = function (anEvent) { return contextMenuEventImplementation(self, nil, anEvent); },

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
        theDocument.addEventListener("contextmenu", contextMenuEventCallback, NO);

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
        _DOMWindow.addEventListener("wheel", scrollEventCallback, NO);
        _DOMWindow.addEventListener("mousewheel", scrollEventCallback, NO);

        _DOMWindow.addEventListener("resize", resizeEventCallback, NO);

        _DOMWindow.addEventListener("unload", function()
        {
            [self updateFromNativeContentRect];
            [self _removeLayers];

            theDocument.removeEventListener("mouseup", mouseEventCallback, NO);
            theDocument.removeEventListener("mousedown", mouseEventCallback, NO);
            theDocument.removeEventListener("mousemove", mouseEventCallback, NO);
            theDocument.removeEventListener("contextmenu", contextMenuEventCallback, NO);

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
            _DOMWindow.removeEventListener("wheel", scrollEventCallback, NO);
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
        theDocument.attachEvent("oncontextmenu", contextMenuEventCallback);

        theDocument.attachEvent("onkeyup", keyEventCallback);
        theDocument.attachEvent("onkeydown", keyEventCallback);
        theDocument.attachEvent("onkeypress", keyEventCallback);

        _DOMWindow.attachEvent("onresize", resizeEventCallback);

        _DOMWindow.onmousewheel = scrollEventCallback;
        theDocument.onmousewheel = scrollEventCallback;

        _DOMBodyElement.ondrag = function () { return NO; };
        _DOMBodyElement.onselectstart = function () { return _DOMWindow.event.srcElement === _DOMPasteboardElement; };

        _DOMWindow.attachEvent("onunload", function()
        {
            [self updateFromNativeContentRect];
            [self _removeLayers];

            theDocument.detachEvent("onmouseup", mouseEventCallback);
            theDocument.detachEvent("onmousedown", mouseEventCallback);
            theDocument.detachEvent("onmousemove", mouseEventCallback);
            theDocument.detachEvent("ondblclick", mouseEventCallback);
            theDocument.detachEvent("oncontextmenu", contextMenuEventCallback);

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
    if ([[CPPlatformWindow primaryPlatformWindow] isVisible])
    {
        var set = [CPSet setWithSet:PlatformWindows];
        [set addObject:[CPPlatformWindow primaryPlatformWindow]];
        return set;
    }
    else
        return PlatformWindows;
}

- (void)orderFront:(CPWindow)aWindow
{
    if ([aWindow parentWindow])
        return;

    if (_DOMWindow)
        return _DOMWindow.focus();

    _DOMWindow = window.open("about:blank", "_blank", "menubar=no,location=no,resizable=yes,scrollbars=no,status=no,left=" + CGRectGetMinX(_contentRect) + ",top=" + CGRectGetMinY(_contentRect) + ",width=" + CGRectGetWidth(_contentRect) + ",height=" + CGRectGetHeight(_contentRect));

    [PlatformWindows addObject:self];

    // FIXME: cpSetFrame?
    _DOMWindow.document.write('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"></head><body style="background-color:transparent;"></body></html>');
    _DOMWindow.document.close();

    if (self != [CPPlatformWindow primaryPlatformWindow])
        _DOMWindow.document.title = _title;

    if (![CPPlatform isBrowser])
    {
        _DOMWindow.cpWindowNumber = [self._only windowNumber];
        _DOMWindow.cpSetFrame(_contentRect);
        _DOMWindow.cpSetLevel(_level);
        _DOMWindow.cpSetHasShadow(_hasShadow);
        _DOMWindow.cpSetShadowStyle(_shadowStyle);
    }

    [self registerDOMWindow];

    _DOMBodyElement.style.cursor = [[CPCursor currentCursor] _cssString];
}

- (void)orderOut:(CPWindow)aWindow
{
    if (!_DOMWindow)
        return;

    _DOMWindow.close();
}

- (void)dragEvent:(DOMEvent)aDOMEvent
{
    var type = aDOMEvent.type,
        dragServer = [CPDragServer sharedDragServer],
        location = CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY),
        pasteboard = [_CPDOMDataTransferPasteboard DOMDataTransferPasteboard];

    [pasteboard _setDataTransfer:aDOMEvent.dataTransfer];

    if (aDOMEvent.type === "dragstart")
    {
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

        [pasteboard _setPasteboard:[dragServer draggingPasteboard]];

        var draggedWindow = [dragServer draggedWindow],
            draggedWindowFrame = [draggedWindow frame],
            DOMDragElement = draggedWindow._DOMElement;

        DOMDragElement.style.left = -CGRectGetWidth(draggedWindowFrame) + "px";
        DOMDragElement.style.top = -CGRectGetHeight(draggedWindowFrame) + "px";

        var parentNode = DOMDragElement.parentNode;

        if (parentNode)
            parentNode.removeChild(DOMDragElement);

        _DOMBodyElement.appendChild(DOMDragElement);

        var draggingOffset = [dragServer draggingOffset];

        aDOMEvent.dataTransfer.setDragImage(DOMDragElement, draggingOffset.width, draggingOffset.height);
        aDOMEvent.dataTransfer.effectAllowed = "all";

        [dragServer draggingStartedInPlatformWindow:self globalLocation:[CPPlatform isBrowser] ? location : CGPointMake(aDOMEvent.screenX, aDOMEvent.screenY)];
    }
    else if (type === "drag")
    {
        var y = aDOMEvent.screenY;

        if (CPFeatureIsCompatible(CPHTML5DragAndDropSourceYOffBy1))
            y -= 1;

        [dragServer draggingSourceUpdatedWithGlobalLocation:[CPPlatform isBrowser] ? location : CGPointMake(aDOMEvent.screenX, y)];
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

        [dragServer draggingEndedInPlatformWindow:self globalLocation:[CPPlatform isBrowser] ? location : CGPointMake(aDOMEvent.screenX, aDOMEvent.screenY) operation:dragOperation];
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
        location = _lastMouseEventLocation || CGPointMakeZero(),
        timestamp = [CPEvent currentTimestamp],
        sourceElement = aDOMEvent.target || aDOMEvent.srcElement,
        windowNumber = [[CPApp keyWindow] windowNumber],
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) |
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) |
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) |
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);

    // With a few exceptions, all key events are blocked from propagating to
    // the browser.  Here the following exceptions are being allowed:
    //
    //   - All keys pressed along with a ctrl or cmd key _unless_ they are in
    //     one of the two blacklists.
    //   - Any key listed in the whitelist.
    //
    // The ctrl/cmd keys are used for browser hotkeys as are the keys listed in
    // the whitelist (F1-F12 at the time of writing).
    //
    // If a key is listed in both the blacklist and whitelist, the blacklist is
    // checked first.  The key will be blocked from propagating in that case.

    StopDOMEventPropagation = YES;

    // Make sure it is not in the blacklists.
    if (!(CharacterKeysToPrevent[String.fromCharCode(aDOMEvent.keyCode || aDOMEvent.charCode).toLowerCase()] || KeyCodesToPrevent[aDOMEvent.keyCode]))
    {
        // It is not in the blacklist, let it through if the ctrl/cmd key is
        // also down or it's in the whitelist.
        if ((modifierFlags & (CPControlKeyMask | CPCommandKeyMask)) || KeyCodesToAllow[aDOMEvent.keyCode])
            StopDOMEventPropagation = NO;
    }

    var isNativePasteEvent = NO,
        isNativeCopyOrCutEvent = NO,
        overrideCharacters = nil,
        charactersIgnoringModifiers = @"";

    switch (aDOMEvent.type)
    {
        case "keydown":
            // Grab and store the keycode now since it is correct and consistent at this point.
            if (aDOMEvent.keyCode in MozKeyCodeToKeyCodeMap)
                _keyCode = MozKeyCodeToKeyCodeMap[aDOMEvent.keyCode];
            else
                _keyCode = aDOMEvent.keyCode;

            var characters;

            // Handle key codes for which String.fromCharCode won't work.
            // Refs #1036: In Internet Explorer, both 'which' and 'charCode' are undefined for special keys.
            if (aDOMEvent.which === 0 || aDOMEvent.charCode === 0 || (aDOMEvent.which === undefined && aDOMEvent.charCode === undefined))
                characters = KeyCodesToUnicodeMap[_keyCode];

            if (!characters)
                characters = String.fromCharCode(_keyCode).toLowerCase();

            overrideCharacters = (modifierFlags & CPShiftKeyMask || _capsLockActive) ? characters.toUpperCase() : characters;

            // check for caps lock state
            if (_keyCode === CPKeyCodes.CAPS_LOCK)
                _capsLockActive = YES;

            if ([ModifierKeyCodes containsObject:_keyCode])
            {
                // A modifier key will never fire keypress. We don't need to do any other processing so we just fire it here and break.
                event = [CPEvent keyEventWithType:CPFlagsChanged location:location modifierFlags:modifierFlags
                            timestamp:timestamp windowNumber:windowNumber context:nil
                            characters:nil charactersIgnoringModifiers:nil isARepeat:NO keyCode:_keyCode];

                break;
            }
            else if (modifierFlags & (CPControlKeyMask | CPCommandKeyMask))
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

            var characters = overrideCharacters;
            // Is this a special key?
            if (!characters && (aDOMEvent.which === 0 || aDOMEvent.charCode === 0))
                characters = KeyCodesToUnicodeMap[charCode];

            if (!characters)
                characters = String.fromCharCode(charCode);

            charactersIgnoringModifiers = characters.toLowerCase(); // FIXME: This isn't correct. It SHOULD include Shift.

            // Safari won't send proper capitalization during cmd-key events
            if (!overrideCharacters && (modifierFlags & CPCommandKeyMask) && ((modifierFlags & CPShiftKeyMask) || _capsLockActive))
                characters = characters.toUpperCase();

            event = [CPEvent keyEventWithType:CPKeyDown location:location modifierFlags:modifierFlags
                        timestamp:timestamp windowNumber:windowNumber context:nil
                        characters:characters charactersIgnoringModifiers:charactersIgnoringModifiers isARepeat:isARepeat keyCode:charCode];

            if (isNativePasteEvent)
            {
                _pasteboardKeyDownEvent = event;
                window.setNativeTimeout(function () { [self _checkPasteboardElement] }, 0);
            }

            break;

        case "keyup":
            var keyCode = aDOMEvent.keyCode,
                charCode = _charCodes[keyCode];

            _keyCode = -1;
            _lastKey = -1;
            _charCodes[keyCode] = nil;
            _ignoreNativeCopyOrCutEvent = NO;
            _ignoreNativePastePreparation = NO;

            // check for caps lock state
            if (keyCode === CPKeyCodes.CAPS_LOCK)
                _capsLockActive = NO;

            if ([ModifierKeyCodes containsObject:keyCode])
            {
                // A modifier key will never fire keypress. We don't need to do any other processing so we just fire it here and break.
                event = [CPEvent keyEventWithType:CPFlagsChanged location:location modifierFlags:modifierFlags
                            timestamp:timestamp windowNumber:windowNumber context:nil
                            characters:nil charactersIgnoringModifiers:nil isARepeat:NO keyCode:_keyCode];

                break;
            }

            var characters = KeyCodesToUnicodeMap[charCode] || String.fromCharCode(charCode);
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
        // we have to send out a fake copy or cut event so that we can force the copy/cut mechanisms to take place
        var cut = aDOMEvent.type === "beforecut",
            keyCode = cut ? CPKeyCodes.X : CPKeyCodes.C,
            characters = cut ? "x" : "c",
            timestamp = [CPEvent currentTimestamp],  // fake event, might as well use current timestamp
            windowNumber = [[CPApp keyWindow] windowNumber],
            modifierFlags = CPPlatformActionKeyMask,
            location = _lastMouseEventLocation || CGPointMakeZero(),
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
    if (_hideDOMScrollingElementTimeout)
    {
        clearTimeout(_hideDOMScrollingElementTimeout);
        _hideDOMScrollingElementTimeout = nil;
    }

    if (!aDOMEvent)
        aDOMEvent = window.event;

    var location = nil;

    if (CPFeatureIsCompatible(CPJavaScriptMouseWheelValues_8_15))
    {
        var x = aDOMEvent._offsetX || 0.0,
            y = aDOMEvent._offsetY || 0.0,
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

        location = CGPointMake((x + ((aDOMEvent.clientX - 8) / 15)), (y + ((aDOMEvent.clientY - 8) / 15)));
    }
    else if (aDOMEvent._overrideLocation)
        location = aDOMEvent._overrideLocation;
    else
        location = CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY);

    var deltaX = 0.0,
        deltaY = 0.0,
        windowNumber = 0,
        timestamp = [CPEvent currentTimestamp],
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) |
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) |
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) |
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);

    // Show the dom element
    _DOMScrollingElement.style.visibility = "visible";
    _DOMScrollingElement.style.top = (location.y - 15) + @"px";
    _DOMScrollingElement.style.left = (location.x - 15) + @"px";

    // We let the browser handle the scrolling
    StopDOMEventPropagation = NO;

    var theWindow = [self hitTest:location];

    if (!theWindow)
        return;

    var windowNumber = [theWindow windowNumber];

    location = [theWindow convertBridgeToBase:location];

    var event = [CPEvent mouseEventWithType:CPScrollWheel location:location modifierFlags:modifierFlags
                                  timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1 clickCount:1 pressure:0];
    event._DOMEvent = aDOMEvent;

    // We lag 1 event behind without this timeout.
    setTimeout(function()
    {
        // Find the scroll delta
        var deltaX = _DOMScrollingElement.scrollLeft - 150,
            deltaY = (_DOMScrollingElement.scrollTop - 150) || (aDOMEvent.deltaY===undefined?0: aDOMEvent.deltaY);

        // If we scroll super with momentum,
        // there are so many events going off that
        // a tiny percent don't actually have any deltas.
        //
        // This does *not* make scrolling appear sluggish,
        // it just seems like that is something that happens.
        //
        // We get free performance boost if we skip sending these events,
        // as sending a scroll event with no deltas doesn't do anything.
        if (deltaX || deltaY)
        {
            event._deltaX = deltaX;
            event._deltaY = deltaY;

            [CPApp sendEvent:event];
        }

        // We set StopDOMEventPropagation = NO on line 1008
        //if (StopDOMEventPropagation)
        //    CPDOMEventStop(aDOMEvent, self);

        // Reset the DOM elements scroll offset
        _DOMScrollingElement.scrollLeft = 150;
        _DOMScrollingElement.scrollTop = 150;

        // Is this needed?
        //[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    }, 0);

    // We hide the dom element after a little bit
    // so that other DOM elements such as inputs
    // can receive events.
    _hideDOMScrollingElementTimeout = setTimeout(function()
    {
        _DOMScrollingElement.style.visibility = "hidden";
    }, 300);
}

- (void)resizeEvent:(DOMEvent)aDOMEvent
{
    // This is a hack for the browser resize bug in safari.
    // See bug ID: 1325
    // https://github.com/cappuccino/cappuccino/issues/1325
    // Addendum by Antoine Mercadal : I also noticed that reszing is causing
    // problem under latest Firefox 13.0. Let's just use this hack
    // for all browser now.

    [resizeTimer invalidate];
    resizeTimer = [CPTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(_actualResizeEvent) userInfo:nil repeats:NO];
}

- (void)_actualResizeEvent
{
    resizeTimer = nil;

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

        switch (aDOMEvent.type)
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

        newEvent.timestamp = [CPEvent currentTimestamp];
        newEvent.target = aDOMEvent.target;

        newEvent.shiftKey = newEvent.ctrlKey = newEvent.altKey = newEvent.metaKey = false;

        newEvent.preventDefault = function() { if (aDOMEvent.preventDefault) aDOMEvent.preventDefault() };
        newEvent.stopPropagation = function() { if (aDOMEvent.stopPropagation) aDOMEvent.stopPropagation() };

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
        location = CGPointMake(aDOMEvent.clientX, aDOMEvent.clientY),
        timestamp = [CPEvent currentTimestamp],
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
        var theWindow = [self _mouseHitTest:location];

        if ((aDOMEvent.type === CPDOMEventMouseDown) && theWindow)
            _mouseDownWindow = theWindow;

        windowNumber = [theWindow windowNumber];
    }

    if (windowNumber)
        location = [CPApp._windows[windowNumber] convertPlatformWindowToBase:location];

    if (type === "mouseup")
    {
        if (_mouseIsDown)
        {
            event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseDownIsRightClick ? CPRightMouseUp : CPLeftMouseUp, location, modifierFlags, timestamp, windowNumber, nil, -1, CPDOMEventGetClickCount(_lastMouseUp, timestamp, location), 0, nil);

            _mouseIsDown = NO;
            _lastMouseUp = event;
            _mouseDownWindow = nil;
            _mouseDownIsRightClick = NO;
        }

        if (_DOMEventMode)
        {
            _DOMEventMode = NO;
            return;
        }
    }

    else if (type === "mousedown")
    {
        // If we receive a click event, then we invalidate any scheduled
        // or visible tooltips
        [_CPToolTip invalidateCurrentToolTipIfNeeded];

        var button = aDOMEvent.button;

        _mouseDownIsRightClick = button == 2 || (CPBrowserIsOperatingSystem(CPMacOperatingSystem) && button == 0 && modifierFlags & CPControlKeyMask);

        if (sourceElement.tagName === "INPUT" && sourceElement != _DOMFocusElement)
        {
            if ([CPPlatform supportsDragAndDrop])
            {
                _DOMBodyElement.setAttribute("draggable", "false");
                _DOMBodyElement.style["-khtml-user-drag"] = "none";
            }

            _DOMEventMode = YES;
            _mouseIsDown = YES;

            // Fake a down and up event so that event tracking mode will work correctly
            [CPApp sendEvent:[CPEvent mouseEventWithType:_mouseDownIsRightClick ? CPRightMouseDown : CPLeftMouseDown location:location modifierFlags:modifierFlags
                    timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1
                    clickCount:CPDOMEventGetClickCount(_lastMouseDown, timestamp, location) pressure:0]];

            [CPApp sendEvent:[CPEvent mouseEventWithType:_mouseDownIsRightClick ? CPRightMouseUp : CPLeftMouseUp location:location modifierFlags:modifierFlags
                    timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1
                    clickCount:CPDOMEventGetClickCount(_lastMouseDown, timestamp, location) pressure:0]];

            return;
        }
        else if ([CPPlatform supportsDragAndDrop])
        {
            _DOMBodyElement.setAttribute("draggable", "true");
            _DOMBodyElement.style["-khtml-user-drag"] = "element";
        }

        StopContextMenuDOMEventPropagation = YES;

        event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseDownIsRightClick ? CPRightMouseDown : CPLeftMouseDown, location, modifierFlags, timestamp, windowNumber, nil, -1, CPDOMEventGetClickCount(_lastMouseDown, timestamp, location), 0, nil);

        _mouseIsDown = YES;
        _lastMouseDown = event;
    }

    else // if (type === "mousemove" || type === "drag")
    {
        if (_DOMEventMode)
            return;

        // _lastMouseEventLocation might be nil on the very first mousemove event. Just send in the current location
        // in this case - this will result in a delta x and delta y of 0 which seems natural for the first event.
        event = _CPEventFromNativeMouseEvent(aDOMEvent, _mouseIsDown ? (_mouseDownIsRightClick ? CPRightMouseDragged : CPLeftMouseDragged) : CPMouseMoved, location, modifierFlags, timestamp, windowNumber, nil, -1, 1, 0, _lastMouseEventLocation || location);
    }

    var isDragging = [[CPDragServer sharedDragServer] isDragging];

    if (event && (!isDragging || !supportsNativeDragAndDrop))
    {
        event._DOMEvent = aDOMEvent;

        [CPApp sendEvent:event];
    }

    if (StopDOMEventPropagation && (!supportsNativeDragAndDrop || type !== "mousedown" && !isDragging))
        CPDOMEventStop(aDOMEvent, self);

    // If there are any tracking event listeners (listening for CPLeftMouseDraggedMask)
    // then show the event guard so we don't lose events to iframes
    var hasTrackingEventListener = NO;

    for (var i = 0; i < CPApp._eventListeners.length; i++)
    {
        var listener = CPApp._eventListeners[i];

        if (listener._callback !== _CPRunModalLoop && (listener._mask & CPLeftMouseDraggedMask))
        {
            hasTrackingEventListener = YES;
            break;
        }
    }

    _lastMouseEventLocation = location;

    _DOMEventGuard.style.display = hasTrackingEventListener ? "" : "none";

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)contextMenuEvent:(DOMEvent)aDOMEvent
{
    if (StopContextMenuDOMEventPropagation)
        CPDOMEventStop(aDOMEvent, self);

    return !StopContextMenuDOMEventPropagation;
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

        var insertionIndex = 0;

        if (middle !== undefined)
            insertionIndex = _windowLevels[middle] > aLevel ? middle : middle + 1

        [_windowLevels insertObject:aLevel atIndex:insertionIndex];
        layer._DOMElement.style.zIndex = aLevel;

        _DOMBodyElement.appendChild(layer._DOMElement);
    }

    return layer;
}

- (void)order:(CPWindowOrderingMode)orderingMode window:(CPWindow)aWindow relativeTo:(CPWindow)otherWindow
{
    [CPPlatform initializeScreenIfNecessary];

    // Grab the appropriate level for the layer, and create it if
    // necessary (if we are not simply removing the window).
    var layer = [self layerAtLevel:[aWindow level] create:orderingMode !== CPWindowOut];

    // When ordering out, ignore otherWindow, simply remove aWindow from its level.
    // If layer is nil, this will be a no-op.
    if (orderingMode === CPWindowOut)
        return [layer removeWindow:aWindow];

    /*
        If aWindow is a child of otherWindow and is not yet visible,
        aWindow must actually be ordered relative to:

        - otherWindow's last child which is not aWindow, or
        - the furthest parent of aWindow

        whichever is frontmost (orderingMode === CPWindowAbove) or rearmost
        (orderingMode === CPWindowBelow).
    */

    if (![aWindow isVisible] && otherWindow && [aWindow parentWindow] === otherWindow)
    {
        var children = [otherWindow childWindows],
            lastChild = [children lastObject];

        if (lastChild === aWindow)
        {
            if ([children count] > 1)
                otherWindow = [children objectAtIndex:[children count] - 2];
        }
        else if (lastChild)
            otherWindow = lastChild;

        var furthestParent = [self _furthestParentOf:otherWindow];

        if ((orderingMode === CPWindowAbove && furthestParent._index > otherWindow._index) ||
            (orderingMode === CPWindowBelow && furthestParent._index < otherWindow._index))
            otherWindow = furthestParent;
    }

    /*
        If a child window is ordered front, the furthest parent is actually
        the one that is ordered front, and all of the descendent children
        are ordered after it.
    */
    else if (orderingMode === CPWindowAbove && !otherWindow)
        aWindow = [self _furthestParentOf:aWindow];

    var insertionIndex = CPNotFound;

    if (otherWindow)
        insertionIndex = orderingMode === CPWindowAbove ? otherWindow._index + 1 : otherWindow._index;

    // Place the window at the appropriate index.
    [layer insertWindow:aWindow atIndex:insertionIndex];

    // If aWindow is a parent, recursively order all of its children after it
    if ([[aWindow childWindows] count])
        [self _orderChildWindowsOf:aWindow furthestParent:[self _furthestParentOf:aWindow] layer:layer];

    [aWindow _setHasBeenOrderedIn:YES];
}

- (CPWindow)_furthestParentOf:(CPWindow)aWindow
{
    var parent;

    while ((parent = [aWindow parentWindow]))
        aWindow = parent;

    return aWindow;
}

- (void)_orderChildWindowsOf:(CPWindow)aWindow furthestParent:(CPWindow)furthestParent layer:(CPDOMWindowLayer)aLayer
{
    // When a parent window is ordered, Cocoa orders its child windows
    // relative to it or the furthest parent.
    var children = [aWindow childWindows],
        count = [children count],
        parent = aWindow,
        parentLevel = [parent level];

    for (var i = 0; i < count; ++i)
    {
        var child = children[i],
            childWasVisible = [child isVisible];

        // If a child is not visible and has not yet been ordered in, skip it
        if (!childWasVisible && ![child _hasBeenOrderedIn])
            continue;

        // If a user moved level of the child window, we should respect that
        if ([child level] !== parentLevel)
            continue;

        var ordering = [child _childOrdering];

        if ((ordering === CPWindowAbove && furthestParent._index > parent._index) ||
            (ordering === CPWindowBelow && furthestParent._index < parent._index))
            parent = furthestParent;

        var index = ordering === CPWindowAbove ? parent._index + 1 : parent._index;

        [aLayer insertWindow:child atIndex:index];

        if (!childWasVisible)
            [child _parentDidOrderInChild];

        if ([[child childWindows] count])
            [self _orderChildWindowsOf:child furthestParent:furthestParent layer:aLayer];

        parent = child;
    }
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
- (id)_dragHitTest:(CGPoint)aPoint pasteboard:(CPPasteboard)aPasteboard
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

- (void)_propagateContextMenuDOMEvent:(BOOL)aFlag
{
    if (aFlag && CPBrowserIsEngine(CPGeckoBrowserEngine))
        StopDOMEventPropagation = !aFlag;

    StopContextMenuDOMEventPropagation = !aFlag;
}

- (BOOL)_willPropagateContextMenuDOMEvent
{
    return StopContextMenuDOMEventPropagation;
}

- (CPWindow)_mouseHitTest:(CGPoint)location
{
    return [self _hitTest:location withTest:@selector(_isValidMousePoint:)]
}

- (CPWindow)hitTest:(CGPoint)location
{
    return [self _hitTest:location withTest:@selector(containsPoint:)]
}

- (CPWindow)_hitTest:(CGPoint)location withTest:(SEL)aTest
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

            if (!candidateWindow._ignoresMouseEvents && [candidateWindow performSelector:aTest withObject:location])
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
    for (var i = characters.length; i > 0; i--)
        CharacterKeysToPrevent["" + characters[i - 1].toLowerCase()] = YES;
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
    for (var i = keyCodes.length; i > 0; i--)
        KeyCodesToPrevent[keyCodes[i - 1]] = YES;
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
#endif

var CPEventClass = [CPEvent class];

var _CPEventFromNativeMouseEvent = function(aNativeEvent, anEventType, aPoint, modifierFlags, aTimestamp, aWindowNumber, aGraphicsContext, anEventNumber, aClickCount, aPressure, aMouseDragStart)
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
    if ((anEventType == CPLeftMouseDragged) || (anEventType == CPRightMouseDragged) || (anEventType == CPMouseMoved))
    {
        aNativeEvent._deltaX = aPoint.x - aMouseDragStart.x;
        aNativeEvent._deltaY = aPoint.y - aMouseDragStart.y;
    }
    else
    {
        aNativeEvent._deltaX = 0;
        aNativeEvent._deltaY = 0;
    }


    return aNativeEvent;
};

var CLICK_SPACE_DELTA   = 5.0,
    CLICK_TIME_DELTA    = (typeof document != "undefined" && document.addEventListener) ? 0.55 : 1.0;

var CPDOMEventGetClickCount = function(aComparisonEvent, aTimestamp, aLocation)
{
    if (!aComparisonEvent)
        return 1;

    var comparisonLocation = [aComparisonEvent locationInWindow];

    return (aTimestamp - [aComparisonEvent timestamp] < CLICK_TIME_DELTA &&
        ABS(comparisonLocation.x - aLocation.x) < CLICK_SPACE_DELTA &&
        ABS(comparisonLocation.y - aLocation.y) < CLICK_SPACE_DELTA) ? [aComparisonEvent clickCount] + 1 : 1;
};

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
};

function CPWindowObjectList()
{
    var platformWindows = [CPPlatformWindow visiblePlatformWindows],
        platformWindowEnumerator = [platformWindows objectEnumerator],
        platformWindow = nil,
        windowObjects = [];

    while ((platformWindow = [platformWindowEnumerator nextObject]) !== nil)
    {
        var levels = platformWindow._windowLevels,
            layers = platformWindow._windowLayers,
            levelCount = levels.length;

        while (levelCount--)
        {
            var windows = [layers objectForKey:levels[levelCount]]._windows,
                windowCount = windows.length;

            while (windowCount--)
                windowObjects.push(windows[windowCount]);
        }
    }

    return windowObjects;
}

function CPWindowList()
{
    var windowObjectList = CPWindowObjectList(),
        windowList = [];

    for (var i = 0, count = [windowObjectList count]; i < count; i++)
        windowList.push([windowObjectList[i] windowNumber]);

    return windowList;
}
