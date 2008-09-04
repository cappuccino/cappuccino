/*
 * CPColorWell.j
 * AppKit
 *
 * Created by Ross Boucher.
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

import <Foundation/CPString.j>

import "CPView.j"
import "CPColor.j"
import "CPColorPanel.j"


var _CPColorWellDidBecomeExclusiveNotification = @"_CPColorWellDidBecomeExclusiveNotification";

@implementation CPColorWell : CPControl
{
    BOOL    _active;
    
    CPColor _color;
    CPView  _wellView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _active = NO;
        
        _color = [CPColor whiteColor];
        
        [self drawBezelWithHighlight:NO];
        [self drawWellInside:CGRectInset([self bounds], 3.0, 3.0)];
        
        var defaultCenter = [CPNotificationCenter defaultCenter];
        
        [defaultCenter
            addObserver:self
               selector:@selector(colorWellDidBecomeExclusive:)
                   name:_CPColorWellDidBecomeExclusiveNotification
                 object:nil];

        [defaultCenter
            addObserver:self
               selector:@selector(colorPanelWillClose:)
                   name:CPWindowWillCloseNotification
                 object:[CPColorPanel sharedColorPanel]];
    }
    
    return self;
}

// Managing Color From Color Wells

- (CPColor)color
{
    return _color;
}

- (void)setColor:(CPColor)aColor
{
    if (_color == aColor)
        return;
    
    _color = aColor;
    
    [self drawWellInside:CGRectInset([self bounds], 3.0, 3.0)];
}

- (void)takeColorFrom:(id)aSender
{
    [self setColor:[aSender color]];
}

// Activating and Deactivating Color Wells

- (void)activate:(BOOL)shouldBeExclusive
{
    if (shouldBeExclusive)
        // FIXME: make this queue!
        [[CPNotificationCenter defaultCenter]
            postNotificationName:_CPColorWellDidBecomeExclusiveNotification
                          object:self];


    if ([self isActive])
        return;
        
    _active = YES;
    
    [[CPNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(colorPanelDidChangeColor:)
               name:CPColorPanelColorDidChangeNotification
             object:[CPColorPanel sharedColorPanel]];
}

- (void)deactivate
{
    if (![self isActive])
        return;
    
    _active = NO;
    
    [[CPNotificationCenter defaultCenter]
        removeObserver:self
                  name:CPColorPanelColorDidChangeNotification
                object:[CPColorPanel sharedColorPanel]];
}

- (BOOL)isActive
{
    return _active;
}

// Drawing a Color Well

- (void)drawBezelWithHighlight:(BOOL)shouldHighlight
{
}

- (void)drawWellInside:(CGRect)aRect
{
    if (!_wellView)
    {
        _wellView = [[CPView alloc] initWithFrame:aRect];
        
        [self addSubview:_wellView];
    }
    else
        [_wellView setFrame:aRect];
    
    [_wellView setBackgroundColor:_color];
}

- (void)colorPanelDidChangeColor:(CPNotification)aNotification
{
    [self takeColorFrom:[aNotification object]];
    
    [self sendAction:[self action] to:[self target]];
}

- (void)colorWellDidBecomeExclusive:(CPNotification)aNotification
{
    if (self != [aNotification object])
        [self deactivate];
}

- (void)colorPanelWillClose:(CPNotification)aNotification
{
    [self deactivate];
}

- (void)mouseDown:(CPEvent)anEvent
{
    [self drawBezelWithHighlight:YES];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    [self drawBezelWithHighlight:CGRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil])];
}

-(void)mouseUp:(CPEvent)anEvent
{
    [self drawBezelWithHighlight:NO];

    if (!CGRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
        return;
        
    [self activate:YES];

    var colorPanel = [CPColorPanel sharedColorPanel];
    
    [colorPanel setColor:_color];

    [colorPanel orderFront:self];
}

@end
