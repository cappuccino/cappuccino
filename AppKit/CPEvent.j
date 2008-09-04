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

import <Foundation/CPObject.j>

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

var _CPEventPeriodicEventPeriod         = 0,
    _CPEventPeriodicEventTimer          = nil;

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
    CPString            _characters;
    CPString            _charactersIgnoringModifiers
    BOOL                _isARepeat;
    unsigned            _keyCode;
    DOMEvent            _DOMEvent;
    
    float               _deltaX;
    float               _deltaY;
    float               _deltaZ;
}
    
+ (CPEvent)keyEventWithType:(CPEventType)anEventType location:(CPPoint)aPoint modifierFlags:(unsigned int)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    characters:(CPString)characters charactersIgnoringModifiers:(CPString)unmodCharacters isARepeat:(BOOL)repeatKey keyCode:(unsigned short)code
{
    return [[self alloc] _initKeyEventWithType:anEventType location:aPoint modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext 
        characters:characters charactersIgnoringModifiers:unmodCharacters isARepeat:repeatKey keyCode:code];
}

+ (id)mouseEventWithType:(CPEventType)anEventType location:(CPPoint)aPoint modifierFlags:(unsigned)modifierFlags 
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    eventNumber:(int)anEventNumber clickCount:(int)aClickCount pressure:(float)aPressure
{
    return [[self alloc] _initMouseEventWithType:anEventType location:aPoint modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext eventNumber:anEventNumber clickCount:aClickCount pressure:aPressure];
}

+ (CPEvent)otherEventWithType:(CPEventType)anEventType location:(CGPoint)aLocation modifierFlags:(unsigned)modifierFlags
    timestamp:(CPTimeInterval)aTimestamp windowNumber:(int)aWindowNumber context:(CPGraphicsContext)aGraphicsContext
    subtype:(short)aSubtype data1:(int)aData1 data2:(int)aData2
{
    return [[self alloc] _initOtherEventWithType:anEventType location:aLocation modifierFlags:modifierFlags
        timestamp:aTimestamp windowNumber:aWindowNumber context:aGraphicsContext subtype:aSubtype data1:aData1 data2:aData2];
}

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
        _window = [CPApp windowWithWindowNumber:aWindowNumber];
    }
    
    return self;
}

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

- (CPPoint)locationInWindow
{
    return _location;
}

- (unsigned)modifierFlags
{
    return _modifierFlags;
}

- (CPTimeInterval)timestamp
{
    return _timestamp;
}

- (CPEventType)type
{
    return _type;
}

- (CPWindow)window
{
    return _window;
}

- (int)windowNumber
{
    return _windowNumber;
}

// Mouse Event Information

- (int)buttonNumber
{
    return _buttonNumber;
}

- (int)clickCount
{
    return _clickCount;
}

- (CPString)characters
{
    return _characters;
}

- (CPString)charactersIgnoringModifiers
{
    return _charactersIgnoringModifiers;
}

- (BOOL)isARepeat
{
    return _isARepeat;
}

- (unsigned short)keyCode
{
    return _keyCode;
}

- (float)pressure
{
    return _pressure;
}

- (DOMEvent)_DOMEvent
{
    return _DOMEvent;
}

// Getting Scroll Wheel Event Infomration

- (float)deltaX
{
    return _deltaX;
}

- (float)deltaY
{
    return _deltaY;
}

- (float)deltaZ
{
    return _deltaZ;
}

+ (void)startPeriodicEventsAfterDelay:(CPTimeInterval)aDelay withPeriod:(CPTimeInterval)aPeriod
{
    _CPEventPeriodicEventPeriod = aPeriod;
    
    // FIXME: OH TIMERS!!!
    _CPEventPeriodicEventTimer = window.setTimeout(function() { _CPEventPeriodicEventTimer = window.setInterval(_CPEventFirePeriodEvent, aPeriod * 1000.0); }, aDelay * 1000.0);
}

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
    
    [[CPRunLoop currentRunLoop] performSelectors];
}

