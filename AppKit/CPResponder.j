/*
 * CPResponder.j
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

CPDeleteKeyCode     = 8;
CPUpArrowKeyCode    = 63232;
CPDownArrowKeyCode  = 63233;
CPLeftArrowKeyCode  = 63234;
CPRightArrowKeyCode = 63235;

@implementation CPResponder : CPObject
{
    CPMenu      _menu;
    CPResponder _nextResponder;
}

// Changing the first responder

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return YES;
}

// Setting the next responder

- (void)setNextResponder:(CPResponder)aResponder
{
    _nextResponder = aResponder;
}

- (CPResponder)nextResponder
{
    return _nextResponder;
}

- (void)interpretKeyEvents:(CPArray)events
{
    var event,
        index = 0;
    
    while(event = events[index++])
    {
        switch([event keyCode])
        {
            case CPLeftArrowKeyCode:    [self moveBackward:self];
                                        break;
            case CPRightArrowKeyCode:   [self moveForward:self];
                                        break;
            case CPUpArrowKeyCode:      [self moveUp:self];
                                        break;
            case CPDownArrowKeyCode:    [self moveDown:self];
                                        break;
            case CPDeleteKeyCode:       [self deleteBackward:self];
                                        break;
            case 3:
            case 13:                    [self insertLineBreak:self];
                                        break;
            default:                    [self insertText:[event characters]];
        }
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)scrollWheel:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)keyDown:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)keyUp:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    return NO;
}

// Action Methods

- (void)deleteBackward:(id)aSender
{
}

- (void)insertLineBreak:(id)aSender
{
}

- (void)insertText:(CPString)aString
{
}

// Dispatch methods

- (void)doCommandBySelector:(SEL)aSelector
{
    if([self respondsToSelector:aSelector])
        [self performSelector:aSelector];
    else
        [_nextResponder doCommandBySelector:aSelector];
}

- (BOOL)tryToPerform:(SEL)aSelector with:(id)anObject
{
    if([self respondsToSelector:aSelector])
    {
        [self performSelector:aSelector withObject:anObject];
        
        return YES;
    }

    return [_nextResponder tryToPerform:aSelector with:anObject];
}

// Managing a Responder's menu

- (void)setMenu:(CPMenu)aMenu
{
    _menu = aMenu;
}

- (CPMenu)menu
{
    return _menu;
}

// Getting the Undo Manager

- (CPUndoManager)undoManager
{
    return [_nextResponder performSelector:_cmd];
}

// Terminating the responder chain

- (void)noResponderFor:(SEL)anEventSelector
{
}

@end

var CPResponderNextResponderKey = @"CPResponderNextResponderKey";

@implementation CPResponder (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self init];
    
    if (self)
        _nextResponder = [aCoder decodeObjectForKey:CPResponderNextResponderKey];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeConditionalObject:_nextResponder forKey:CPResponderNextResponderKey];
}

@end
