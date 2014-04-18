/*
 * CPPlatformPasteboard.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2013, SlevenBits Ltd.
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

@import "CPCompatibility.j"
@import "CPEvent.j"
@import "CPPasteboard.j"
@import "CPPlatform.j"
@import "CPPlatformWindow+DOMKeys.j"

@global CPApp
@global CPPlatformWindow

// From CPPlatformWindow+DOM.j
@global _CPDOMEventStop

#if PLATFORM(DOM)

#define SUPPRESS_CAPPUCCINO_CUT_FOR_EVENT(anEvent) anEvent._suppressCappuccinoCut = YES
#define SUPPRESS_CAPPUCCINO_PASTE_FOR_EVENT(anEvent) anEvent._suppressCappuccinoPaste = YES

var hasEditableTarget = function(aDOMEvent)
{
    var target = aDOMEvent.target || aDOMEvent.srcElement;

    if (!target)
        return NO;

    if (target.contentEditable == "true")
        return YES;

    var nodeName = target.nodeName.toUpperCase();

    return nodeName === "INPUT" || nodeName == "TEXTAREA";
}

/*
 * This class encapsulates copy and paste related functionality for the
 * DOM environment. While originally all of this code was apread out in a
 * dozen places in CPPlatformWindow+DOM.j, this class serves to collect
 * and isolate that code for easier testing and maintenance.
 */
@implementation CPPlatformPasteboard : CPObject
{
    DOMWindow   _DOMWindow;

    DOMElement  _DOMPasteboardElement;

    BOOL        supportsNativeCopyAndPaste;
    BOOL        hasBugWhichPreventsNonEditablePaste;
    BOOL        hasBugWhichPreventsNonEditablePasteRedirect;

    CPEvent     _lastKeyDownEvent;
    BOOL        currentEventIsNativePasteEvent;
    BOOL        currentEventIsNativeCopyOrCutEvent;
    BOOL        currentEventShouldBeSuppressed;
    BOOL        currentEventShouldDefinitelyBubble;
    BOOL        currentEventShouldDefinitelyNotBubble;

    BOOL        _ignoreNativeCopyOrCutEvent;
    BOOL        _ignoreNativePastePreparation;
}

- (id)init
{
    if (self = [super init])
    {
        supportsNativeCopyAndPaste                  = CPFeatureIsCompatible(CPJavaScriptClipboardEventsFeature);
        hasBugWhichPreventsNonEditablePaste         = CPPlatformHasBug(CPJavaScriptPasteRequiresEditableTarget);
        hasBugWhichPreventsNonEditablePasteRedirect = CPPlatformHasBug(CPJavaScriptPasteCantRefocus);
    }

    return self;
}

- (void)setDOMWindow:(DOMWindow)aDOMWindow
{
    if (_DOMWindow === aDOMWindow)
        return;

    if (_DOMWindow)
        [self destroyDOMElements];

    _DOMWindow = aDOMWindow;

    if (_DOMWindow)
        [self createDOMElements];
}

- (void)createDOMElements
{
    var theDocument = _DOMWindow.document,
        _DOMBodyElement = theDocument.getElementById("cappuccino-body") || theDocument.body;

    // Create Native Pasteboard handler.
    _DOMPasteboardElement = theDocument.createElement("textarea");

    _DOMPasteboardElement.style.position = "absolute";
    _DOMPasteboardElement.style.top = "-10000px";
    _DOMPasteboardElement.style.zIndex = "999";
    _DOMPasteboardElement.className = "cpdontremove";

    _DOMBodyElement.appendChild(_DOMPasteboardElement);

    _DOMPasteboardElement.blur();

    var copyEventCallback = function (anEvent) { return [self beforeCopyEvent:anEvent]; },
        nativeBeforeClipboardEventCallback = function (anEvent) { return [self nativeBeforeClipboardEvent:anEvent]; },
        nativeCopyOrCutEventCallback = function (anEvent) { return [self nativeCopyOrCutEvent:anEvent]; },
        pasteEventCallback = function (anEvent) { return [self beforePasteEvent:anEvent]; },
        nativePasteEventCallback = function (anEvent) { return [self nativePasteEvent:anEvent]; };

    if (theDocument.addEventListener)
    {
        if (supportsNativeCopyAndPaste)
        {
            _DOMWindow.addEventListener("beforecopy", nativeBeforeClipboardEventCallback, NO);
            _DOMWindow.addEventListener("beforecut", nativeBeforeClipboardEventCallback, NO);
            _DOMWindow.addEventListener("beforepaste", nativeBeforeClipboardEventCallback, NO);
            _DOMWindow.addEventListener("copy", nativeCopyOrCutEventCallback, NO);
            _DOMWindow.addEventListener("cut", nativeCopyOrCutEventCallback, NO);
            _DOMWindow.addEventListener("paste", nativePasteEventCallback, NO);
        }
        else
        {
            theDocument.addEventListener("beforepaste", pasteEventCallback, NO);
            theDocument.addEventListener("beforecopy", copyEventCallback, NO);
            theDocument.addEventListener("beforecut", copyEventCallback, NO);
        }

        _DOMWindow.addEventListener("unload", function()
        {
            if (supportsNativeCopyAndPaste)
            {
                _DOMWindow.removeEventListener("beforecopy", nativeBeforeClipboardEventCallback, NO);
                _DOMWindow.removeEventListener("beforecut", nativeBeforeClipboardEventCallback, NO);
                _DOMWindow.removeEventListener("beforepaste", nativeBeforeClipboardEventCallback, NO);
                _DOMWindow.removeEventListener("copy", nativeCopyOrCutEventCallback, NO);
                _DOMWindow.removeEventListener("cut", nativeCopyOrCutEventCallback, NO);
                _DOMWindow.removeEventListener("paste", nativePasteEventCallback, NO);
            }
            else
            {
                theDocument.removeEventListener("beforepaste", pasteEventCallback, NO);
                theDocument.removeEventListener("beforecopy", copyEventCallback, NO);
                theDocument.removeEventListener("beforecut", copyEventCallback, NO);
            }
        }, NO);
    }
    else
    {
        // TODO If we wanted IE 8 and lower copy and paste it'd go here.
    }
}

- (void)destroyDOMElements
{
    var theDocument = _DOMWindow.document,
        _DOMBodyElement = theDocument.getElementById("cappuccino-body") || theDocument.body;

    _DOMBodyElement.removeChild(_DOMPasteboardElement);
    _DOMPasteboardElement = nil;
}

- (void)windowMaySendKeyEvent:(CPEvent)anEvent
{
    // Reset our opinions.
    currentEventIsNativePasteEvent          = NO;
    currentEventIsNativeCopyOrCutEvent      = NO;
    currentEventShouldBeSuppressed          = NO;
    currentEventShouldDefinitelyNotBubble   = NO;
    currentEventShouldDefinitelyBubble      = NO;

    if (!anEvent)
        return;

    if ([anEvent type] !== CPKeyDown)
    {
        // Reset these flags on key up.
        _ignoreNativePastePreparation = NO;
        _ignoreNativeCopyOrCutEvent = NO;
        return;
    }

    var modifierFlags = [anEvent modifierFlags];

    if (!(modifierFlags & (CPControlKeyMask | CPCommandKeyMask)))
        return;

    _lastKeyDownEvent = anEvent;

    var aDOMEvent = anEvent._DOMEvent,
        characters = [anEvent characters],
        mayRequireDOMPasteboardElement = [self _mayRequireDOMPasteboardElementHack:aDOMEvent flags:modifierFlags];

    if (characters === "v" && mayRequireDOMPasteboardElement)
    {
        if (supportsNativeCopyAndPaste && hasBugWhichPreventsNonEditablePaste && hasBugWhichPreventsNonEditablePasteRedirect && !hasEditableTarget(aDOMEvent))
        {
            // You can't paste from the system clipboard into a non-editable area in Safari, neither using native
            // copy and paste nor our _DOMPasteboardElement hack. We will paste from the Cappuccino pasteboard only
            // and allow Safari to "beep" to indicate something went wrong.

            // The key down will not result in a paste event being sent by Safari, so it's not a paste event.
            currentEventIsNativePasteEvent = NO;
            // Yes to get the beep.
            currentEventShouldDefinitelyBubble = YES;
        }
        else if (!(supportsNativeCopyAndPaste || hasBugWhichPreventsNonEditablePaste) && !_ignoreNativePastePreparation)
        {
            // We don't support native copy and paste so we must focus the _DOMPasteboardElement to receive the
            // paste content. This needs to be done at keyDown time (or in the case of modern Safari, before the keyDown,
            // which unfortunately isn't possible. See above.)
            _DOMPasteboardElement.focus();
            _DOMPasteboardElement.select();
            _DOMPasteboardElement.value = "";
            _DOMWindow.setNativeTimeout(function () { [self _checkDOMPasteboardElement]; }, 0);

            currentEventIsNativePasteEvent = YES;
        }
        else if (supportsNativeCopyAndPaste)
            currentEventIsNativePasteEvent = YES;

        if (currentEventIsNativePasteEvent)
        {
            // We need the event to propagate or nothing will be pasted.
            currentEventShouldDefinitelyBubble = YES;

            // And we don't send the keydown because either our native paste envent handler will send it,
            // or the _checkDOMPasteboardElement check will.
            currentEventShouldBeSuppressed = YES;
        }
    }
    else if ((characters == "c" || characters == "x") && mayRequireDOMPasteboardElement)
    {
        currentEventIsNativeCopyOrCutEvent = YES;

        // If _ignoreNativeCopyOrCutEvent, we already handled the copy/cut in beforeCopyEvent:.
        // If supportsNativeCopyAndPaste, we will be handling it in the nativebeforeCopyEvent: handler.
        // In both of those cases we don't want to send the event on keydown too, or we'll get 2X copy/cut operations.
        if (supportsNativeCopyAndPaste || _ignoreNativeCopyOrCutEvent)
            currentEventShouldBeSuppressed = YES;
    }

    if (!currentEventShouldBeSuppressed)
    {
        if (characters === "v")
            SUPPRESS_CAPPUCCINO_PASTE_FOR_EVENT(anEvent);
        else if (characters === "x")
            SUPPRESS_CAPPUCCINO_CUT_FOR_EVENT(anEvent);
    }
}

- (BOOL)windowShouldSuppressKeyEvent
{
    return currentEventShouldBeSuppressed;
}

- (void)windowDidSendKeyEvent:(CPEvent)anEvent
{
    // Now that the copy event has been sent through the Cappuccino event stack, we can load any Cappuccino
    // pasteboard string into our DOMPasteboardElement hack, if necessary.
    if (!supportsNativeCopyAndPaste && currentEventIsNativeCopyOrCutEvent)
        [self _primeDOMPasteboardElement];
}

- (BOOL)windowShouldStopPropagation
{
    return currentEventShouldDefinitelyNotBubble;
}

- (BOOL)windowShouldNotStopPropagation
{
    return currentEventShouldDefinitelyBubble;
}

- (CPEvent)_fakeClipboardEvent:(DOMEvent)aDOMEvent type:(CPString)aType
{
    var keyCode = aType === "x" ? CPKeyCodes.X : (aType === "c" ? CPKeyCodes.C : CPKeyCodes.V),
        characters = aType,
        timestamp = [CPEvent currentTimestamp],  // fake event, might as well use current timestamp
        windowNumber = [[CPApp keyWindow] windowNumber],
        modifierFlags = CPPlatformActionKeyMask,
        location = [_lastKeyDownEvent locationInWindow],
        anEvent = [CPEvent keyEventWithType:CPKeyDown location:location modifierFlags:modifierFlags
                                  timestamp:timestamp windowNumber:windowNumber context:nil
                                 characters:characters charactersIgnoringModifiers:characters isARepeat:NO keyCode:keyCode];

    anEvent._data1 = @{ "simulated": YES };
    anEvent._DOMEvent = aDOMEvent;

    return anEvent;
}

- (void)beforeCopyEvent:(DOMEvent)aDOMEvent
{
    if ([self _mayRequireDOMPasteboardElementHack:aDOMEvent flags:CPPlatformActionKeyMask] && !_ignoreNativeCopyOrCutEvent)
    {
        // we have to send out a fake copy or cut event so that we can force the copy/cut mechanisms to take place
        var anEvent = [self _fakeClipboardEvent:aDOMEvent type:(aDOMEvent.type === "beforecut" ? "x" : "c")];

        [CPApp sendEvent:anEvent];

        // Once we've sent it, we can load the copy information into the pasteboard hack.
        [self _primeDOMPasteboardElement];

        //then we have to IGNORE the real keyboard event to prevent a double copy
        //safari also sends the beforecopy event twice, so we additionally check here and prevent two events
        _ignoreNativeCopyOrCutEvent = YES;
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (boolean)beforePasteEvent:(DOMEvent)aDOMEvent
{
    // Set up to capture the paste in a temporary input field. We'll send the event after capture.
    if ([self _mayRequireDOMPasteboardElementHack:aDOMEvent flags:CPPlatformActionKeyMask])
    {
        _DOMPasteboardElement.focus();
        _DOMPasteboardElement.select();
        _DOMPasteboardElement.value = "";

        _ignoreNativePastePreparation = YES;
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

/*
Return true if the event may be a copy and paste event, but the target is not an input or text area.
*/
- (void)_mayRequireDOMPasteboardElementHack:(DOMEvent)aDOMEvent flags:(unsigned)modifierFlags
{
    return !hasEditableTarget(aDOMEvent) && (modifierFlags & CPPlatformActionKeyMask);
}

- (void)_primeDOMPasteboardElement
{
    var pasteboard = [CPPasteboard generalPasteboard],
        types = [pasteboard types];

    if (types.length)
    {
        if ([types indexOfObjectIdenticalTo:CPStringPboardType] !== CPNotFound)
            _DOMPasteboardElement.value = [pasteboard stringForType:CPStringPboardType];
        else
            _DOMPasteboardElement.value = [pasteboard _generateStateUID];

        _DOMPasteboardElement.focus();
        _DOMPasteboardElement.select();

        window.setNativeTimeout(function() { [self _clearDOMPasteboardElement]; }, 0);
    }
}

- (void)_checkDOMPasteboardElement
{
    if (supportsNativeCopyAndPaste)
    {
        [self _clearDOMPasteboardElement];
        return;
    }

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

    [self _clearDOMPasteboardElement];

    [CPApp sendEvent:[self _fakeClipboardEvent:nil type:@"v"]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)_clearDOMPasteboardElement
{
    _DOMPasteboardElement.value = "";
    _DOMPasteboardElement.blur();
}

- (boolean)nativeBeforeClipboardEvent:(DOMEvent)aDOMEvent
{
    // Our job here is to return "false" if the given clipboard operation should be enabled even in a situation where
    // the browser might normally grey the option out.

    // Allow these fields to do their own thing.
    if (hasEditableTarget(aDOMEvent))
        return true;

    var returnValue = YES;

    switch (aDOMEvent.type)
    {
        case "beforecopy":
            returnValue = !([CPApp targetForAction:@selector(copy:)]);
            break;
        case "beforecut":
            returnValue = !([CPApp targetForAction:@selector(cut:)]);
            break;
        case "beforepaste":
            returnValue = !([CPApp targetForAction:@selector(paste:)]);
            break;
    }

    if (!returnValue)
        _CPDOMEventStop(aDOMEvent, self);

    return returnValue;
}

- (boolean)nativePasteEvent:(DOMEvent)aDOMEvent
{
    // This shouldn't happen.
    if (!supportsNativeCopyAndPaste)
        return;

    var value;
    if (aDOMEvent.clipboardData && aDOMEvent.clipboardData.setData)
        value = aDOMEvent.clipboardData.getData('text/plain');
    else
        value = _DOMWindow.clipboardData.getData("Text");

    if ([value length])
    {
        var pasteboard = [CPPasteboard generalPasteboard];

        if ([pasteboard _stateUID] != value)
        {
            [pasteboard declareTypes:[CPStringPboardType] owner:self];
            [pasteboard setString:value forType:CPStringPboardType];
        }
    }

    var anEvent = [self _fakeClipboardEvent:aDOMEvent type:"v"],
        platformWindow = [[anEvent window] platformWindow];

    SUPPRESS_CAPPUCCINO_PASTE_FOR_EVENT(anEvent);

    // By default we'll stop the native handling of the event since we're handling it ourselves. However, we need to
    // stop it before we send the event so that the event can overrule our choice. CPTextField for instance wants the
    // default handling when focused (which is to insert into the field).
    [platformWindow _propagateCurrentDOMEvent:NO]

    [CPApp sendEvent:anEvent];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    if (![platformWindow _willPropagateCurrentDOMEvent])
        _CPDOMEventStop(aDOMEvent, self);

    return false;
}

- (boolean)nativeCopyOrCutEvent:(DOMEvent)aDOMEvent
{
    // This shouldn't happen.
    if (!supportsNativeCopyAndPaste)
        return;

    var anEvent = [self _fakeClipboardEvent:aDOMEvent type:(aDOMEvent.type.indexOf("cut") != CPNotFound ? "x" : "c")],
        platformWindow = [[anEvent window] platformWindow];

    SUPPRESS_CAPPUCCINO_CUT_FOR_EVENT(anEvent);

    [platformWindow _propagateCurrentDOMEvent:NO]

    // Let the app react through copy: and cut: actions.
    [CPApp sendEvent:anEvent];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    // If StopDOMEventPropagation was set to NO, we don't try to write to the system clipboard. The control that did this
    // wants to use the default copy/cut functionality.
    if (![platformWindow _willPropagateCurrentDOMEvent])
    {
        // Now the app should have written whatever it wants to have copied to the Cappuccino clipboard. So now we need
        // to write it to the system board.
        _CPDOMEventStop(aDOMEvent, self);

        var pasteboard = [CPPasteboard generalPasteboard];

        if ([[pasteboard types] containsObject:CPStringPboardType])
        {
            var stringValue = [pasteboard stringForType:CPStringPboardType];

            if (aDOMEvent.clipboardData && aDOMEvent.clipboardData.setData)
                aDOMEvent.clipboardData.setData('text/plain', stringValue);
            else
                _DOMWindow.clipboardData.setData('Text', stringValue);
        }
    }

    return ![platformWindow _willPropagateCurrentDOMEvent];
}

@end

#endif
