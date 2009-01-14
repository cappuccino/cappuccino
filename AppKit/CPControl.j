/*
 * CPControl.j
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

@import "CPFont.j"
@import "CPShadow.j"
@import "CPView.j"

#include "Platform/Platform.h"


/*
    @global
    @group CPTextAlignment
*/
CPLeftTextAlignment         = 0;
/*
    @global
    @group CPTextAlignment
*/
CPRightTextAlignment        = 1;
/*
    @global
    @group CPTextAlignment
*/
CPCenterTextAlignment       = 2;
/*
    @global
    @group CPTextAlignment
*/
CPJustifiedTextAlignment    = 3;
/*
    @global
    @group CPTextAlignment
*/
CPNaturalTextAlignment      = 4;

/*
    @global
    @group CPControlSize
*/
CPRegularControlSize        = 0;
/*
    @global
    @group CPControlSize
*/
CPSmallControlSize          = 1;
/*
    @global
    @group CPControlSize
*/
CPMiniControlSize           = 2;

CPControlNormalBackgroundColor      = "CPControlNormalBackgroundColor";
CPControlSelectedBackgroundColor    = "CPControlSelectedBackgroundColor";
CPControlHighlightedBackgroundColor = "CPControlHighlightedBackgroundColor";
CPControlDisabledBackgroundColor    = "CPControlDisabledBackgroundColor";

CPControlTextDidBeginEditingNotification    = "CPControlTextDidBeginEditingNotification";
CPControlTextDidChangeNotification          = "CPControlTextDidChangeNotification";
CPControlTextDidEndEditingNotification      = "CPControlTextDidEndEditingNotification";

var CPControlBlackColor     = [CPColor blackColor];

/*! @class CPControl

    CPControl is an abstract superclass used to implement user interface elements. As a subclass of CPView and CPResponder it has the ability to handle screen drawing and handling user input.
*/
@implementation CPControl : CPView
{
    id          _value;

    BOOL        _isEnabled;
    
    int         _alignment;
    CPFont      _font;
    CPColor     _textColor;
    CPShadow    _textShadow;
    
    id          _target;
    SEL         _action;
    int         _sendActionOn;
    
    CPDictionary    _backgroundColors;
    CPString        _currentBackgroundColorName;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _sendActionOn = CPLeftMouseUpMask;
        _isEnabled = YES;
        
        [self setFont:[CPFont systemFontOfSize:12.0]];
        [self setTextColor:CPControlBlackColor];
        
        _backgroundColors = [CPDictionary dictionary];
    }
    
    return self;
}

/*!
    Sets whether the receiver responds to mouse events.
    @param isEnabled whether the receiver will respond to mouse events
*/
- (void)setEnabled:(BOOL)isEnabled
{
    [self setAlphaValue:(_isEnabled = isEnabled) ? 1.0 : 0.3];
}

/*!
    Returns <code>YES</code> if the receiver responds to mouse events.
*/
- (BOOL)isEnabled
{
    return _isEnabled;
}


/*!
    Sets the color of the receiver's text.
*/
- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;
    
    _textColor = aColor;

#if PLATFORM(DOM)
    _DOMElement.style.color = [aColor cssString];
#endif
}

/*!
    Returns the color of the receiver's text
*/
- (CPColor)textColor
{
    return _textColor;
}

/*!
    Returns the receiver's alignment
*/
- (CPTextAlignment)alignment
{
    return _alignment;
}

/*!
    Sets the receiver's alignment
    @param anAlignment the receiver's alignment
*/
- (void)setAlignment:(CPTextAlignment)anAlignment
{
    _alignment = anAlignment;
}

/*!
    Sets the receiver's font
    @param aFont the font for the receiver
*/
- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
    
    _font = aFont;
    
#if PLATFORM(DOM)
    _DOMElement.style.font = [_font ? _font : [CPFont systemFontOfSize:12.0] cssString];
#endif
}

/*!
    Returns the receiver's font
*/
- (CPFont)font
{
    return _font;
}

/*!
    Sets the shadow for the receiver's text.
    @param aTextShadow the text shadow
*/
- (void)setTextShadow:(CPShadow)aTextShadow
{
#if PLATFORM(DOM)
    _DOMElement.style.textShadow = [_textShadow = aTextShadow cssString];
#endif
}

/*!
    Returns the receiver's text shadow
*/
- (CPShadow)textShadow
{
    return _textShadow;
}

/*!
    Returns the receiver's target action
*/
- (SEL)action
{
    return _action;
}

/*!
    Sets the receiver's target action
    @param anAction Sets the action message that gets sent to the target.
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

/*!
    Returns the receiver's target. The target receives action messages from the receiver.
*/
- (id)target
{
    return _target;
}

/*!
    Sets the receiver's target. The target receives action messages from the receiver.
    @param aTarget the object that will receive the message specified by action
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    CPLog("Start tracking at x:" + aPoint.x + " y:" + aPoint.y) ;
    return YES;
}

//- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)currentPoint inView:(NSView *)view {
- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)currentPoint // inView:(CPView)aView
{
    CPLog("Continue tracking at x:" + currentPoint.x + " y:" + currentPoint.y) ;
    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    CPLog("Stop tracking at x:" + aPoint.x + " y:" + aPoint.y) ;
}

- (void)old__trackMouse:(CPEvent)anEvent untilMouseUp:(BOOL)shouldContinueUntilMouseUp
{
    CPLog("start trackMouse") ;
    // if (event is mousedown) startTackingAt:event.locationInWIndow
    // else if (event is mousedragged && event location withing frame)
    // continueTracking:at:....
    // else if (event is out of frame) { stopTracking... if (event is mouseup
    // || !shouldContinueUntilMouseUp) return;}
    // register to receive next event

    // if (_sendActionOn & CPLeftMouseUpMask && CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]))

    // doc here : http://objc.toodarkpark.net/AppKit/Classes/NSCell.html#//apple_ref/occ/instm/NSCell/trackMouse:inRect:ofView:untilMouseUp:
    // if(![self startTrackingAt:[event locationInWindow] inView:view])
    //  return NO;

     if ([anEvent type] == CPLeftMouseDown) 
     {
         CPLog("startTrackingAt should log something") ;
         [self startTrackingAt:[anEvent locationInWindow]] ;
     }
     else
        return NO ;


    do {
        var currentPoint    = [anEvent locationInWindow] ;
        var lastPoint       = [anEvent locationInWindow] // should test if _lastPoint do not existe = current point else = _lastPoint
        var isWithinFrame   = CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]) ;
        var eventType       = [anEvent type] ;
        
        // if (shouldContinueUntilMouseUp) {
        //     if (eventType==CPLeftMouseUp) {
        //         // [self stopTracking:lastPoint at:[event locationInWindow] inView:view mouseIsUp:YES];
        //         [self stopTracking:lastPoint at:currentPoint mouseIsUp:YES];
        //         result=YES;
        //         break;
        //     }
        // }
        // else if (isWithinFrame) {
        //     if(eventType==CPLeftMouseUp){
        //         // [self stopTracking:lastPoint at:[event locationInWindow] inView:view mouseIsUp:YES];
        //         [self stopTracking:lastPoint at:currentPoint mouseIsUp:YES];
        //         result=YES;
        //         break;
        //     }
        // }
        // else {
        //     // [self stopTracking:lastPoint at:[event locationInWindow] inView:view mouseIsUp:NO];
        //     [self stopTracking:lastPoint at:currentPoint mouseIsUp:NO];
        //     result=NO;
        //     break;
        // }
        // 
        // if (isWithinFrame) {
        //     // if (![self continueTracking:lastPoint at:[event locationInWindow] inView:view])
        //     if (![self continueTracking:lastPoint at:currentPoint])
        //         break;
        // 
        //     // if([self isContinuous])
        //     //     [(NSControl *)view sendAction:[(NSControl *)view action] to:[(NSControl *)view target]];
        // }

        // [[view window] flushWindow];
        // 
        // event=[[view window] nextEventMatchingMask:NSLeftMouseUpMask|
        //                       NSLeftMouseDraggedMask];

        
        // === my version now :
        
        // var eventType       = [anEvent type] ;
        // var point           = [anEvent locationInWindow] ;
        // var lastPoint       = [anEvent locationInWindow] // should test if _lastPoint do not existe = current point else = _lastPoint
        // var isWithinFrame   = CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]) ;
        
        if (eventType == CPLeftMouseDown) 
        {
            // [self startTrackingAt:currentPoint] ;
        }
        else if (eventType == CPLeftMouseDragged && isWithinFrame)
        {
            [self continueTracking:lastPoint at:currentPoint];
        }
        // else if (event is out of frame) {
        //  stopTracking... if (event is mouseup || !shouldContinueUntilMouseUp) return;
        //  }
        // register to receive next event
        else if (!isWithinFrame)
        {
            [self stopTracking:lastPoint at:currentPoint mouseIsUp:(anEvent == CPLeftMouseUp)];
        
            if (eventType == CPLeftMouseUp || !shouldContinueUntilMouseUp) 
            {
                CPLog("This should end") ;
                break ;
            }
        }
        
        // CPLog("before force break") ;
        // break;
        // CPLog("after force break") ;
    } while (YES) ;



    // register to receive next event
    CPLog("end trackMouse 8") ;
}

- (void)trackMouse:(CPEvent)anEvent untilMouseUp:(BOOL)shouldContinueUntilMouseUp
{
    CPLog("start trackMouse") ;

    // doc here : http://objc.toodarkpark.net/AppKit/Classes/NSCell.html#//apple_ref/occ/instm/NSCell/trackMouse:inRect:ofView:untilMouseUp:

    var currentPoint    = [anEvent locationInWindow] ;
    // var currentPoint    = [self convertPoint:[anEvent locationInWindow] fromView:nil] ;
    var lastPoint       = [anEvent locationInWindow] 
    var isWithinFrame   = CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]) ;
    var eventType       = [anEvent type] ;
    
    if (eventType == CPLeftMouseDown) 
    {
        [self startTrackingAt:currentPoint] ;
    }
    else if (eventType == CPLeftMouseDragged && isWithinFrame)
    {
        [self continueTracking:lastPoint at:currentPoint];
    }
    else if (eventType == CPLeftMouseUp && isWithinFrame)
    {
        CPLog("Up in the frame -> shoud fire up action!") ;
        // [self stopTracking:lastPoint at:currentPoint mouseIsUp:(anEvent == CPLeftMouseUp)];
        return ;
    }
    else if (!isWithinFrame)
    {
        // [self stopTracking:lastPoint at:currentPoint mouseIsUp:(anEvent == CPLeftMouseUp)];
    
        if (eventType == CPLeftMouseUp || !shouldContinueUntilMouseUp) 
        {
            [self stopTracking:lastPoint at:currentPoint mouseIsUp:(anEvent == CPLeftMouseUp)];
            CPLog("Up out of the frame") ;
            return ;
        }
    }

    [CPApp setTarget:self selector:@selector(trackMouse:untilMouseUp:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
    
    CPLog("end trackMouse") ;
}

- (void)mouseDown:(CPEvent)anEvent
{
    // while (getNextEvent)
    // if (currentEvent is mousedragged) highlight or unhighlight
    // else if (currentEvent is mouseUp) fire action, return

    // if (not enabled) return; // nothing to do.
    // [self trackMouse:anEvent untilMouseUp:YES];    

    CPLog("CPControl > mouseDown") ;
    if (!_isEnabled) return ;
    [self trackMouse:anEvent untilMouseUp:YES] ;
}

- (void)mouseUp:(CPEvent)anEvent
{
    CPLog("CPControl > mouseUp") ;
    if (_sendActionOn & CPLeftMouseUpMask && CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
    {
        CPLog("Will send action because isWithinFrame == " + CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil])) ;
        [self sendAction:_action to:_target];
    }
    else 
    {
        CPLog("Won't send action because isWithinFrame == " + CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil])) ;
    }
    
    [super mouseUp:anEvent];
}

/*!
    Causes <code>anAction</code> to be sent to <code>anObject</code>.
    @param anAction the action to send
    @param anObject the object to which the action will be sent
*/
- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [CPApp sendAction:anAction to:anObject from:self];
}

- (int)sendActionOn:(int)mask
{
    var previousMask = _sendActionOn;
    
    _sendActionOn = mask;
    
    return previousMask;
}

/*!
    Returns whether the control can continuously send its action messages.
*/
- (BOOL)isContinuous
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    return (_sendActionOn & CPPeriodicMask) != 0;
}

/*!
    Sets whether the cell can continuously send its action messages.
 */
- (void)setContinuous:(BOOL)flag
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    if (flag)
        _sendActionOn |= CPPeriodicMask;
    else 
        _sendActionOn &= ~CPPeriodicMask;
}

/*!
    Returns the receiver's object value
*/
- (id)objectValue
{
    return _value;
}

/*!
    Set's the receiver's object value
*/
- (void)setObjectValue:(id)anObject
{
    _value = anObject;
}

/*!
    Returns the receiver's float value
*/
- (float)floatValue
{
    var floatValue = parseFloat(_value, 10);
    return isNaN(floatValue) ? 0.0 : floatValue;
}

/*!
    Sets the receiver's float value
*/
- (void)setFloatValue:(float)aValue
{
    [self setObjectValue:aValue];
}

/*!
    Returns the receiver's double value
*/
- (double)doubleValue
{
    var doubleValue = parseFloat(_value, 10);
    return isNaN(doubleValue) ? 0.0 : doubleValue;
}

/*!
    Set's the receiver's double value
*/
- (void)setDoubleValue:(double)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (int)intValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntValue:(int)anObject
{
    [self setObjectValue:anObject];
}


/*!
    Returns the receiver's int value
*/
- (int)integerValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntegerValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (CPString)stringValue
{
    return _value ? String(_value) : "";
}

/*!
    Set's the receiver's int value
*/
- (void)setStringValue:(CPString)anObject
{
    [self setObjectValue:anObject];
}


- (void)takeDoubleValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(doubleValue)])
        [self setDoubleValue:[sender doubleValue]];
}


- (void)takeFloatValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(floatValue)])
        [self setFloatValue:[sender floatValue]];
}


- (void)takeIntegerValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(integerValue)])
        [self setIntegerValue:[sender integerValue]];
}


- (void)takeIntValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(intValue)])
        [self setIntValue:[sender intValue]];
}


- (void)takeObjectValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(objectValue)])
        [self setObjectValue:[sender objectValue]];
}

- (void)takeStringValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(stringValue)])
        [self setStringValue:[sender stringValue]];
}


- (void)setBackgroundColor:(CPColor)aColor
{
    _backgroundColors = [CPDictionary dictionary];
    
    [self setBackgroundColor:aColor forName:CPControlNormalBackgroundColor];
    
    [super setBackgroundColor:aColor];
}

- (void)setBackgroundColor:(CPColor)aColor forName:(CPString)aName
{
    if (!aColor)
        [_backgroundColors removeObjectForKey:aName];
    else
        [_backgroundColors setObject:aColor forKey:aName];
        
    if (_currentBackgroundColorName == aName)
        [self setBackgroundColorWithName:_currentBackgroundColorName];
}

- (CPColor)backgroundColorForName:(CPString)aName
{
    var backgroundColor = [_backgroundColors objectForKey:aName];
    
    if (!backgroundColor && aName != CPControlNormalBackgroundColor)
        return [_backgroundColors objectForKey:CPControlNormalBackgroundColor];
        
    return backgroundColor;
}

- (void)setBackgroundColorWithName:(CPString)aName
{
    _currentBackgroundColorName = aName;
    
    [super setBackgroundColor:[self backgroundColorForName:aName]];
}

- (void)textDidBeginEditing:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidBeginEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidChange:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidEndEditing:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

/*
Ð doubleValue  
Ð setDoubleValue:
Ð intValue  
Ð setIntValue:  
Ð objectValue  
Ð setObjectValue:  
Ð stringValue  
Ð setStringValue:  
Ð setNeedsDisplay  
Ð attributedStringValue  
Ð setAttributedStringValue:  
*/

@end

var CPControlValueKey           = "CPControlValueKey",
    CPControlIsEnabledKey       = "CPControlIsEnabledKey",
    CPControlAlignmentKey       = "CPControlAlignmentKey",
    CPControlFontKey            = "CPControlFontKey",
    CPControlTextColorKey       = "CPControlTextColorKey",
    CPControlTargetKey          = "CPControlTargetKey",
    CPControlActionKey          = "CPControlActionKey",
    CPControlSendActionOnKey    = "CPControlSendActionOnKey";

var __Deprecated__CPImageViewImageKey   = @"CPImageViewImageKey";

@implementation CPControl (CPCoding)

/*
    Initializes the control by unarchiving it from a coder.
    @param aCoder the coder from which to unarchive the control
    @return the initialized control
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        [self setObjectValue:[aCoder decodeObjectForKey:CPControlValueKey]];
        
        if ([aCoder containsValueForKey:__Deprecated__CPImageViewImageKey])
            [self setObjectValue:[aCoder decodeObjectForKey:_DeprecatedCPImageViewImageKey]];

        [self setEnabled:[aCoder decodeBoolForKey:CPControlIsEnabledKey]];
        
        [self setAlignment:[aCoder decodeIntForKey:CPControlAlignmentKey]];
        [self setFont:[aCoder decodeObjectForKey:CPControlFontKey]];
        [self setTextColor:[aCoder decodeObjectForKey:CPControlTextColorKey]];
        
        [self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
        [self setAction:[aCoder decodeObjectForKey:CPControlActionKey]];
        [self sendActionOn:[aCoder decodeIntForKey:CPControlSendActionOnKey]];
    }
    
    return self;
}

/*
    Archives the control to the provided coder.
    @param aCoder the coder to which the control will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_value forKey:CPControlValueKey];
    
    [aCoder encodeBool:_isEnabled forKey:CPControlIsEnabledKey];
    
    [aCoder encodeInt:_alignment forKey:CPControlAlignmentKey];
    [aCoder encodeObject:_font forKey:CPControlFontKey];
    [aCoder encodeObject:_textColor forKey:CPControlTextColorKey];
    
    [aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];
    [aCoder encodeObject:_action forKey:CPControlActionKey];
    
    [aCoder encodeInt:_sendActionOn forKey:CPControlSendActionOnKey];
}

@end

var _CPControlSizeIdentifiers               = [],
    _CPControlCachedThreePartImages         = {},
    _CPControlCachedColorWithPatternImages  = {},
    _CPControlCachedThreePartImagePattern   = {};

_CPControlSizeIdentifiers[CPRegularControlSize] = "Regular";
_CPControlSizeIdentifiers[CPSmallControlSize]   = "Small";
_CPControlSizeIdentifiers[CPMiniControlSize]    = "Mini";
    
function _CPControlIdentifierForControlSize(aControlSize)
{
    return _CPControlSizeIdentifiers[aControlSize];
}

function _CPControlColorWithPatternImage(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];
    
    var color = _CPControlCachedColorWithPatternImages[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]];
    
        color = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:aClassName + "/" + identifier + ".png"] size:sizes[identifier]]];

        _CPControlCachedColorWithPatternImages[identifier] = color;
    }
    
    return color;
}

function _CPControlThreePartImages(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var images = _CPControlCachedThreePartImages[identifier];
    
    if (!images)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        images = [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "2.png"] size:sizes[2]]
                ];
                
        _CPControlCachedThreePartImages[identifier] = images;
    }
    
    return images;
}

function _CPControlThreePartImagePattern(isVertical, sizes, aClassName)
{
    var index = 2,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var color = _CPControlCachedThreePartImagePattern[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "2.png"] size:sizes[2]]
                ] isVertical:isVertical]];
                
        _CPControlCachedThreePartImagePattern[identifier] = color;
    }
    
    return color;
}

