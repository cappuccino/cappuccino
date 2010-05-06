/*
 * CPEvent.j
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

#include "CoreGraphics/CGGeometry.h"


CPLeftMouseDown                         = 1;
CPLeftMouseUp                           = 2;
CPRightMouseDown                        = 3;
CPRightMouseUp                          = 4;
CPMouseMoved                            = 5;
CPLeftMouseDragged                      = 6;
CPRightMouseDragged                     = 7;
CPMouseEntered                          = 8;
CPMouseExited                           = 9;
CPKeyDown                               = 10;
CPKeyUp                                 = 11;
CPFlagsChanged                          = 12;
CPAppKitDefined                         = 13;
CPSystemDefined                         = 14;
CPApplicationDefined                    = 15;
CPPeriodic                              = 16;
CPCursorUpdate                          = 17; 
CPScrollWheel                           = 22;
CPOtherMouseDown                        = 25;
CPOtherMouseUp                          = 26;
CPOtherMouseDragged                     = 27;

// iPhone Event Types
CPTouchStart                            = 28;
CPTouchMove                             = 29;
CPTouchEnd                              = 30;
CPTouchCancel                           = 31;
                                        
                                        
CPAlphaShiftKeyMask                     = 1 << 16;
CPShiftKeyMask                          = 1 << 17;
CPControlKeyMask                        = 1 << 18;
CPAlternateKeyMask                      = 1 << 19;
CPCommandKeyMask                        = 1 << 20;
CPNumericPadKeyMask                     = 1 << 21;
CPHelpKeyMask                           = 1 << 22;
CPFunctionKeyMask                       = 1 << 23;
CPDeviceIndependentModifierFlagsMask    = 0xffff0000;

CPLeftMouseDownMask                     = 1 << CPLeftMouseDown;
CPLeftMouseUpMask                       = 1 << CPLeftMouseUp;
CPRightMouseDownMask                    = 1 << CPRightMouseDown;
CPRightMouseUpMask                      = 1 << CPRightMouseUp;
CPOtherMouseDownMask                    = 1 << CPOtherMouseDown;
CPOtherMouseUpMask                      = 1 << CPOtherMouseUp;
CPMouseMovedMask                        = 1 << CPMouseMoved;
CPLeftMouseDraggedMask                  = 1 << CPLeftMouseDragged;
CPRightMouseDraggedMask                 = 1 << CPRightMouseDragged;
CPOtherMouseDragged                     = 1 << CPOtherMouseDragged;
CPMouseEnteredMask                      = 1 << CPMouseEntered;
CPMouseExitedMask                       = 1 << CPMouseExited;
CPCursorUpdateMask                      = 1 << CPCursorUpdate;
CPKeyDownMask                           = 1 << CPKeyDown;
CPKeyUpMask                             = 1 << CPKeyUp;
CPFlagsChangedMask                      = 1 << CPFlagsChanged;
CPAppKitDefinedMask                     = 1 << CPAppKitDefined;
CPSystemDefinedMask                     = 1 << CPSystemDefined;
CPApplicationDefinedMask                = 1 << CPApplicationDefined;
CPPeriodicMask                          = 1 << CPPeriodic;
CPScrollWheelMask                       = 1 << CPScrollWheel;
CPAnyEventMask                          = 0xffffffff;

CPDOMEventDoubleClick                   = "dblclick",
CPDOMEventMouseDown                     = "mousedown",
CPDOMEventMouseUp                       = "mouseup",
CPDOMEventMouseMoved                    = "mousemove",
CPDOMEventMouseDragged                  = "mousedrag",
CPDOMEventKeyUp                         = "keyup",
CPDOMEventKeyDown                       = "keydown",
CPDOMEventKeyPress                      = "keypress";
CPDOMEventCopy                          = "copy";
CPDOMEventPaste                         = "paste";
CPDOMEventScrollWheel                   = "mousewheel";
CPDOMEventTouchStart                    = "touchstart";
CPDOMEventTouchMove                     = "touchmove";
CPDOMEventTouchEnd                      = "touchend";
CPDOMEventTouchCancel                   = "touchcancel";

var _CPEventPeriodicEventPeriod         = 0,
    _CPEventPeriodicEventTimer          = nil;

/*! 
    @ingroup appkit
    @class CPEvent
    CPEvent encapsulates the details of a Cappuccino keyboard or mouse event.
*/
@implementation CPEvent : CPObject
{
    CPEventType         _type;
    CPPoint             _location;
    unsigned            _modifierFlags;
    CPTimeInterval      _timestamp;
    CPGraphicsContext   _context;
    int                 _eventNumber;
    unsigned            _clickCount;
    float               _pressure;
    CPWindow            _window;
    Number              _windowNumber;
    CPString            _characters;
    CPString            _charactersIgnoringModifiers
    BOOL                _isARepeat;
    unsigned            _keyCode;
    DOMEvent            _DOMEvent;

    float               _deltaX;
    float               _deltaY;
    float               _deltaZ;
}

/*!
    Creates a new keyboard event.
    @param anEventType the event type. Must be one of CPKeyDown, CPKeyUp or CPFlagsChanged
    @param aPoint the location of the cursor in the window specified by \c aWindowNumber
    @param modifierFlags a bitwise combination of the modifiers specified in the CPEvent globals
    @param aTimestamp the time the event occurred
    @param aWindowNumber the number of the CPWindow where the event occurred
    @param aGraphicsContext the graphics context where the event occurred
    @param characters the characters associated with the event
    @param unmodCharacters the string of keys pressed without the presence of any modifiers other than Shift
    @param repeatKey \c YES if this is caused by the system repeat as opposed to the user pressing the key again
    @param code a number associated with the keyboard key of this event
    @throws CPInternalInconsistencyException if \c anEventType is not a CPKeyDown,
    CPKeyUp or CPFlagsChanged
    @return the keyboard event
*/
+ (CPEvent)keyEventWithType:(CPEventType)anEventType location:(CGPoint)aPoint modifierFlags:(unsigned int)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    characters:(CPString)characters charactersIgnoringModifiers:(CPString)unmodCharacters isARepeat:(BOOL)repeatKey keyCode:(unsigned short)code
{
    return [[self alloc] _initKeyEventWithType:anEventType location:aPoint modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext 
        characters:characters charactersIgnoringModifiers:unmodCharacters isARepeat:repeatKey keyCode:code];
}

/*!
    Creates a new mouse event
    @param anEventType the event type
    @param aPoint the location of the cursor in the window specified by \c aWindowNumber
    @param modifierFlags a bitwise combination of the modifiers specified in the CPEvent globals
    @param aTimestamp the time the event occurred
    @param aWindowNumber the number of the CPWindow where the event occurred
    @param aGraphicsContext the graphics context where the event occurred
    @param anEventNumber a number for this event
    @param aClickCount the number of clicks that caused this event
    @param aPressure the amount of pressure applied to the input device (ranges from 0.0 to 1.0)
    @throws CPInternalInconsistencyException if an invalid event type is provided
    @return the new mouse event
*/
+ (id)mouseEventWithType:(CPEventType)anEventType location:(CGPoint)aPoint modifierFlags:(unsigned)modifierFlags 
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    eventNumber:(int)anEventNumber clickCount:(int)aClickCount pressure:(float)aPressure
{
    return [[self alloc] _initMouseEventWithType:anEventType location:aPoint modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext eventNumber:anEventNumber clickCount:aClickCount pressure:aPressure];
}

/*!
    Creates a new custom event
    @param anEventType the event type. Must be one of CPAppKitDefined, CPSystemDefined, CPApplicationDefined or CPPeriodic
    @param aLocation the location of the cursor in the window specified by \c aWindowNumber
    @param modifierFlags a bitwise combination of the modifiers specified in the CPEvent globals
    @param aTimestamp the time the event occurred
    @param aWindowNumber the number of the CPWindow where the event occurred
    @param aGraphicsContext the graphics context where the event occurred
    @param aSubtype a numeric identifier to differentiate this event from other custom events
    @param aData1 more data that describes the event
    @param aData2 even more data that describes the event
    @throws CPInternalInconsistencyException if an invalid event type is provided
    @return the new custom event
*/
+ (CPEvent)otherEventWithType:(CPEventType)anEventType location:(CGPoint)aLocation modifierFlags:(unsigned)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    subtype:(short)aSubtype data1:(int)aData1 data2:(int)aData2
{
    return [[self alloc] _initOtherEventWithType:anEventType location:aLocation modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext subtype:aSubtype data1:aData1 data2:aData2];
}

/* @ignore */
- (id)_initMouseEventWithType:(CPEventType)anEventType location:(CPPoint)aPoint modifierFlags:(unsigned)modifierFlags 
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    eventNumber:(int)anEventNumber clickCount:(int)aClickCount pressure:(float)aPressure
{
    self = [super init];
    
    if (self)
    {
        _type = anEventType;
        _location = CPPointCreateCopy(aPoint);
        _modifierFlags = modifierFlags;
        _timestamp = aTimestamp;
        _context = aGraphicsContext;
        _eventNumber = anEventNumber;
        _clickCount = aClickCount;
        _pressure = aPressure;
        _window = [CPApp windowWithWindowNumber:aWindowNumber];
    }
    
    return self;
}

/* @ignore */
- (id)_initKeyEventWithType:(CPEventType)anEventType location:(CPPoint)aPoint modifierFlags:(unsigned int)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    characters:(CPString)characters charactersIgnoringModifiers:(CPString)unmodCharacters isARepeat:(BOOL)isARepeat keyCode:(unsigned short)code
{
    self = [super init];
    
    if (self)
    {
        _type = anEventType;
        _location = CPPointCreateCopy(aPoint);
        _modifierFlags = modifierFlags;
        _timestamp = aTimestamp;
        _context = aGraphicsContext;
        _characters = characters;
        _charactersIgnoringModifiers = unmodCharacters;
        _isARepeat = isARepeat;
        _keyCode = code;
        _windowNumber = aWindowNumber;
    }
    
    return self;
}

/* @ignore */
- (id)_initOtherEventWithType:(CPEventType)anEventType location:(CGPoint)aPoint modifierFlags:(unsigned)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    subtype:(short)aSubtype data1:(int)aData1 data2:(int)aData2
{
    self = [super init];
    
    if (self)
    {
        _type = anEventType;
        _location = CPPointCreateCopy(aPoint);
        _modifierFlags = modifierFlags;
        _timestamp = aTimestamp;
        _context = aGraphicsContext;
        _subtype = aSubtype;
        _data1 = aData1;
        _data2 = aData2;
    }   

    return self;
}

/*!
    Returns the location of the mouse (for mouse events).
    If this is not a mouse event, it returns \c nil.
    If \c window returns \c nil, then
    the mouse coordinates will be based on the screen coordinates.
    Otherwise, the coordinates are relative to the window's coordinates.
    @return the location of the mouse, or \c nil for non-mouse events.
*/
- (CGPoint)locationInWindow
{
    return _CGPointMakeCopy(_location);
}

- (CGPoint)globalLocation
{
    var theWindow = [self window],
        location = [self locationInWindow];

    if (theWindow)
        return [theWindow convertBaseToGlobal:location];

    return location;
}

/*!
    Returns event information as a bit mask
*/
- (unsigned)modifierFlags
{
    return _modifierFlags;
}

/*!
    Returns the time the event occurred
*/
- (CPTimeInterval)timestamp
{
    return _timestamp;
}

/*!
    Returns the type of event.
*/
- (CPEventType)type
{
    return _type;
}

/*!
    Returns the event's associated window
*/
- (CPWindow)window
{
    if (!_window)
        _window = [CPApp windowWithWindowNumber:_windowNumber];

    return _window;
}

/*!
    The number of the window associated with the event.
*/
- (int)windowNumber
{
    return _windowNumber;
}

// Mouse Event Information
/*!
    Returns the button number for the mouse that generated the event.
*/
- (int)buttonNumber
{
    if (_type === CPRightMouseDown || _type === CPRightMouseUp || _type === CPRightMouseDragged)
        return 1;

    return 0;
}

/*!
    Returns the number of clicks that caused this event. (mouse only)
*/
- (int)clickCount
{
    return _clickCount;
}

/*!
    Returns the characters associated with this event (keyboard only)
    @throws CPInternalInconsistencyException if this method is called on a non-key event
*/
- (CPString)characters
{
    return _characters;
}

/*!
    Returns the character ignoring any modifiers (except shift).
    @throws CPInternalInconsistencyException if this method is called on a non-key event
*/
- (CPString)charactersIgnoringModifiers
{
    return _charactersIgnoringModifiers;
}

/*!
    Returns \c YES if the keyboard event was caused by the key being held down.
    @throws CPInternalInconsistencyException if this method is called on a non-key event
*/
- (BOOL)isARepeat
{
    return _isARepeat;
}

/*!
    Returns the key's key code.
    @throws CPInternalInconsistencyException if this method is called on a non-key event
*/
- (unsigned short)keyCode
{
    return _keyCode;
}

+ (CGPoint)mouseLocation
{
    // FIXME: this is incorrect, we shouldn't depend on the current event.
    var event = [CPApp currentEvent],
        eventWindow = [event window];

    if (eventWindow)
        return [eventWindow convertBaseToGlobal:[event locationInWindow]];

    return [event locationInWindow];
}

- (float)pressure
{
    return _pressure;
}

/*
    @ignore
*/
- (DOMEvent)_DOMEvent
{
    return _DOMEvent;
}

// Getting Scroll Wheel Event Infomration
/*!
    Returns the change in the x-axis for a mouse event.
*/
- (float)deltaX
{
    return _deltaX;
}

/*!
    Returns the change in the y-axis for a mouse event.
*/
- (float)deltaY
{
    return _deltaY;
}

/*!
    Returns the change in the x-axis for a mouse event.
*/
- (float)deltaZ
{
    return _deltaZ;
}

- (BOOL)_couldBeKeyEquivalent
{
    // FIXME: More cases? Space?
    return  _type === CPKeyDown &&
            _modifierFlags & (CPCommandKeyMask | CPControlKeyMask) &&
            [_characters length] > 0;
}

/*!
    Generates periodic events every \c aPeriod seconds.
    @param aDelay the number of seconds before the first event
    @param aPeriod the length of time in seconds between successive events
*/
+ (void)startPeriodicEventsAfterDelay:(CPTimeInterval)aDelay withPeriod:(CPTimeInterval)aPeriod
{
    _CPEventPeriodicEventPeriod = aPeriod;
    
    // FIXME: OH TIMERS!!!
    _CPEventPeriodicEventTimer = window.setTimeout(function() { _CPEventPeriodicEventTimer = window.setInterval(_CPEventFirePeriodEvent, aPeriod * 1000.0); }, aDelay * 1000.0);
}

/*!
    Stops the periodic events from being generated
*/
+ (void)stopPeriodicEvents
{
    if (_CPEventPeriodicEventTimer === nil)
        return;
    
    window.clearTimeout(_CPEventPeriodicEventTimer);
    
    _CPEventPeriodicEventTimer = nil;
}

@end

function _CPEventFirePeriodEvent()
{
    [CPApp sendEvent:[CPEvent otherEventWithType:CPPeriodic location:_CGPointMakeZero() modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0]];
}

var CPEventClass = [CPEvent class];

function _CPEventFromNativeMouseEvent(aNativeEvent, anEventType, aPoint, modifierFlags, aTimestamp, aWindowNumber, aGraphicsContext, anEventNumber, aClickCount, aPressure)
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

