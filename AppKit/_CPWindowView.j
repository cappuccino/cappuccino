/*
 * _CPWindowView.j
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

import "CPView.j"
import "CPImageView.j"


var _CPWindowViewResizeIndicatorImage = nil;

@implementation _CPWindowView : CPView
{
    unsigned    _styleMask;
    
    CPImageView _resizeIndicator;
    
    CPString    _title;
}

+ (void)initialize
{
    if (self != [_CPWindowView class])
        return;
    
    _CPWindowViewResizeIndicatorImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:self] pathForResource:@"_CPWindowView/_CPWindowViewResizeIndicator.png"] size:CGSizeMake(12.0, 12.0)];
}

- (id)initWithFrame:(CPRect)aFrame forStyleMask:(unsigned)aStyleMask
{
    if (aStyleMask & CPHUDBackgroundWindowMask)
        self = [_CPHUDWindowView alloc];
    
    self._styleMask = aStyleMask;
    
    return [self initWithFrame:aFrame];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _resizeIndicator = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        
        [_resizeIndicator setImage:_CPWindowViewResizeIndicatorImage];
        [_resizeIndicator setFrameSize:CGSizeMakeCopy([_CPWindowViewResizeIndicatorImage size])];
        
        [self addSubview:_resizeIndicator];
        
        [self setShowsResizeIndicator:_styleMask & CPResizableWindowMask];
    }
    
    return self;
}

- (void)setTitle:(CPString)aTitle
{
}

- (CPString)title
{
    return nil;
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var theWindow = [self window];
    
    if (![_resizeIndicator isHidden])
    {
        // FIXME: This should be better
        var frame = CGRectMakeCopy([self frame]);
    
        frame.origin.x = CGRectGetWidth(frame) - 20.0;
        frame.origin.y = CGRectGetHeight(frame) - 24.0;
        frame.size.width = 20.0 - 5.0,
        frame.size.height = 24.0 - 8.0;
        
        if (CGRectContainsPoint(frame, [self convertPoint:[anEvent locationInWindow] fromView:nil]))
            return [theWindow trackResizeWithEvent:anEvent];
    }
    
    if ([theWindow isMovableByWindowBackground])
        [theWindow trackMoveWithEvent:anEvent];
        
    else
        [super mouseDown:anEvent];
}

- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{
    [_resizeIndicator setHidden:!shouldShowResizeIndicator];
}

- (CPImage)showsResizeIndicator
{
    return ![_resizeIndicator isHidden];
}

- (void)setTitle:(CPString)title
{
    _title = title;
}

- (CPString)title
{
    return _title;
}

- (void)windowDidChangeDocumentEdited
{
}

- (void)windowDidChangeDocumentSaving
{
}

@end

var _CPHUDWindowViewTopImage          = nil,
    _CPHUDWindowViewTopLeftImage      = nil,
    _CPHUDWindowViewTopRightImage     = nil,
    
    _CPHUDWindowViewLeftImage         = nil,
    _CPHUDWindowViewRightImage        = nil,
    _CPHUDWindowViewCenterImage       = nil,
    
    _CPHUDWindowViewBottomImage       = nil,
    _CPHUDWindowViewBottomLeftImage   = nil,
    _CPHUDWindowViewBottomRightImage  = nil,
    
    _CPHUDWindowViewBackgroundColor   = nil,
    
    CPHUDCloseButtonImage       = nil;

@implementation _CPHUDWindowView : _CPWindowView
{
    CPTextField         _titleField;
    CPButton            _closeButton;
}

+ (void)initialize
{
    if (self != [_CPHUDWindowView class])
        return;
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPHUDWindowViewBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [        
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowTopLeft.png"] size:CPSizeMake(15.0, 86.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowTopCenter.png"] size:CPSizeMake(1.0, 86.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowTopRight.png"] size:CPSizeMake(15.0, 86.0)],
            
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowCenterLeft.png"] size:CPSizeMake(15.0, 1.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowCenter.png"] size:CPSizeMake(1.0, 1.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowCenterRight.png"] size:CPSizeMake(15.0, 1.0)],
            
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowBottomLeft.png"] size:CPSizeMake(15.0, 39.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowBottomCenter.png"] size:CPSizeMake(1.0, 39.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowBottomRight.png"] size:CPSizeMake(15.0, 39.0)]
        ]]];

    _CPHUDWindowViewCloseImage        = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowClose.png"] size:CPSizeMake(20.0, 20.0)];
    _CPHUDWindowViewCloseActiveImage  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowCloseActive.png"] size:CPSizeMake(20.0, 20.0)];
}

- (CPView)hitTest:(CPPoint)aPoint
{
    var view = [super hitTest:aPoint];

    if (view == _titleField)
        return self;
        
    return view;
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        var bounds = [self bounds];
        
        [self setBackgroundColor:_CPHUDWindowViewBackgroundColor];
        
        _titleField = [[CPTextField alloc] initWithFrame:CPRectMakeZero()];
        
        [_titleField setFont:[CPFont systemFontOfSize:11.0]];
        [_titleField setTextColor:[CPColor whiteColor]];
        [_titleField setTextShadow:[CPShadow shadowWithOffset:CPSizeMake(0.0, 1.0) blurRadius:2.0 color:[CPColor blackColor]]];
        [_titleField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
        
        [self addSubview:_titleField];
        
        if (_styleMask & CPClosableWindowMask)
        {
            var closeSize = [_CPHUDWindowViewCloseImage size];
            
            _closeButton = [[CPButton alloc] initWithFrame:CPRectMake(10.0, 7.0, closeSize.width, closeSize.height)];
            
            [_closeButton setBordered:NO];
            
            [_closeButton setImage:_CPHUDWindowViewCloseImage];
            [_closeButton setAlternateImage:_CPHUDWindowViewCloseActiveImage];
            
            [_closeButton setTarget:self];
            [_closeButton setAction:@selector(close:)];
            
            [self addSubview:_closeButton];
        }
        
        [_resizeIndicator setFrameOrigin:CGPointMake(CGRectGetWidth(bounds) - 20.0, CGRectGetHeight(bounds) - 24.0)];
        [_resizeIndicator setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    }
    
    return self;
}

- (void)close:(id)aSender
{
    [[self window] performClose:self];
}

- (void)setTitle:(CPString)aTitle
{
    [_titleField setStringValue:aTitle];
    [_titleField sizeToFit];

    var size = [_titleField frame].size;

    [_titleField setFrameOrigin:CPPointMake((CPRectGetWidth([self frame]) - size.width) / 2.0, (26.0 - size.height) / 2.0)];
}

- (CPString)title
{
    return [_titleField stringValue];
}

- (void)setFrameSize:(CPSize)aSize
{
    [super setFrameSize:aSize];
}

@end
