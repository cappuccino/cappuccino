/*
 * CPPopover.j
 * AppKit
 *
 * Created by Antoine Mercadal.
 * Copyright 2011 Antoine Mercadal.
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

@import "CPButton.j"
@import "CPColor.j"
@import "CPImage.j"
@import "CPImageView.j"
@import "CPResponder.j"
@import "CPView.j"
@import "_CPAttachedWindow.j"


CPPopoverBehaviorApplicationDefined = 0;
CPPopoverBehaviorTransient          = 1;
CPPopoverBehaviorSemitransient      = 2;


var CPPopoverDelegate_popover_willShow_     = 1 << 0,
    CPPopoverDelegate_popover_didShow_      = 1 << 1,
    CPPopoverDelegate_popover_shouldClose_  = 1 << 2,
    CPPopoverDelegate_popover_willClose_   = 1 << 3,
    CPPopoverDelegate_popover_didClose_     = 1 << 4;


/*! @ingroup appkit
    @class CPPopover

    This class represent a widget that displays a attached
    view relative to another one.

    Delegate can implement:
        – popoverShouldClose:(CPPopover)aPopOver
        – popoverWillShow:(CPPopover)aPopOver
        – popoverDidShow:(CPPopover)aPopOver
        – popoverWillClose:(CPPopover)aPopOver
        – popoverDidClose:(CPPopover)aPopOver
*/
@implementation CPPopover : CPResponder
{
    @outlet CPViewController    _contentViewController  @accessors(property=contentViewController);
    @outlet id                  _delegate               @accessors(getter=delegate);

    BOOL                        _animates               @accessors(property=animates);
    BOOL                        _shown                  @accessors(getter=shown);
    int                         _appearance             @accessors(property=appearance);
    int                         _behavior               @accessors(getter=behavior);

    BOOL                        _needsCompute;
    _CPAttachedWindow           _attachedWindow;
    int                         _implementedDelegateMethods;
}


#pragma mark -
#pragma mark INitialization

/*!
    Initialize the CPPopover witn default values

    @returns anInitialized CPPopover
*/
- (CPPopover)init
{
    if (self = [super init])
    {
        _animates       = YES;
        _appearance     = CPPopoverAppearanceMinimal;
        _behavior       = CPPopoverBehaviorApplicationDefined;
        _needsCompute   = YES;
        _shown          = NO;
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*!
    Returns the current rect of the popover

    @return CPRect represeting the frame of the popover
*/
- (CPRect)positionningRect
{
    if (!_attachedWindow || ![_attachedWindow isVisible])
        return nil;
    return [_attachedWindow frame];
}

/*! Sets the frame of the popover
    @param aRect the desired frame
*/
- (void)setPositionningRect:(CPRect)aRect
{
    if (!_attachedWindow || ![_attachedWindow isVisible])
        return;
    [_attachedWindow setFrame:aRect];
}

/*!
    Returns the size of the popover's view

    @return CPSize represeting the size of the popover's view
*/
- (CPRect)contentSize
{
    if (!_attachedWindow || ![_attachedWindow isVisible])
        return nil;
    return [[_contentViewController view] frameSize];
}

/*!
    Sets the size of of the popover's view

    @param aSize the desired size
*/
- (void)setContentSize:(CPSize)aSize
{
    [[_contentViewController view] setFrameSize:aSize];
}

/*!
    Indicates if CPPopover is visible

    @returns YES if visible
*/
- (BOOL)shown
{
    if (!_attachedWindow)
        return NO;
    return [_attachedWindow isVisible];
}

/*!
    Set the behaviour of the CPPopover. It can be
        - CPPopoverBehaviorTransient: the popover will be close if another control outside the popover become the responder
        - CPPopoverBehaviorApplicationDefined: (DEFAULT) the application is responsible for closing the popover

    @param aBehaviour the desired behaviour
*/
- (void)setBehaviour:(int)aBehaviour
{
    if (_behavior == aBehaviour)
        return;

    _behavior = aBehaviour;
    _needsCompute = YES;
}


- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(popoverWillShow:)])
        _implementedDelegateMethods |= CPPopoverDelegate_popover_willShow_;

    if ([_delegate respondsToSelector:@selector(popoverDidShow:)])
        _implementedDelegateMethods |= CPPopoverDelegate_popover_didShow_;

    if ([_delegate respondsToSelector:@selector(popoverShouldClose:)])
        _implementedDelegateMethods |= CPPopoverDelegate_popover_shouldClose_;

    if ([_delegate respondsToSelector:@selector(popoverWillClose:)])
        _implementedDelegateMethods |= CPPopoverDelegate_popover_willClose_;

    if ([_delegate respondsToSelector:@selector(popoverDidClose:)])
        _implementedDelegateMethods |= CPPopoverDelegate_popover_didClose_;
}

#pragma mark -
#pragma mark Positionning

/*!
    Show the popover

    @param positioningRect if set, the popover will be positionned to a random rect relative to the window
    @param positioningView if set, the popover will be positioned relative to this view
    @param preferredEdge: CPRectEdge representing the prefered positionning.
*/
- (void)showRelativeToRect:(CPRect)positioningRect ofView:(CPView)positioningView preferredEdge:(CPRectEdge)preferredEdge
{
    if (_implementedDelegateMethods & CPPopoverDelegate_popover_willShow_)
        [_delegate popoverWillShow:self];

    if (!_contentViewController)
         [CPException raise:CPInternalInconsistencyException reason:@"contentViewController must not be nil"];

    if (_needsCompute)
    {
        var styleMask = (_behavior == CPPopoverBehaviorTransient) ? CPClosableOnBlurWindowMask : nil;
        _attachedWindow = [[_CPAttachedWindow alloc] initWithContentRect:CPRectMakeZero() styleMask:styleMask];
    }

    [_attachedWindow setAppearance:_appearance];
    [_attachedWindow setAnimates:_animates];
    [_attachedWindow setDelegate:self];
    [_attachedWindow setMovableByWindowBackground:NO];
    [_attachedWindow setFrame:[_attachedWindow frameRectForContentRect:[[_contentViewController view] frame]]];
    [_attachedWindow setContentView:[_contentViewController view]];

    if (positioningRect)
        [_attachedWindow positionRelativeToRect:positioningRect preferredEdge:preferredEdge];
    else if (positioningView)
        [_attachedWindow positionRelativeToView:positioningView preferredEdge:preferredEdge];
    else
        [CPException raise:CPInvalidArgumentException reason:@"you must set positioningRect or positioningRect"];

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_didShow_)
        [_delegate popoverDidShow:self];
}

/*!
    Closes the popover
*/
- (void)close
{
    if (_implementedDelegateMethods & CPPopoverDelegate_popover_shouldClose_)
        if (![_delegate popoverShouldClose:self])
            return;

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_willClose_)
        [_delegate popoverWillClose:self];

    [_attachedWindow close];

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_didClose_)
        [_delegate popoverDidClose:self];
}


#pragma mark -
#pragma mark Action

/*!
    Close the popover

    @param aSender the sender of the action
*/
- (IBAction)performClose:(id)aSender
{
    [self close];
}


#pragma mark -
#pragma mark Delegates

/*! @ignore */
- (BOOL)didAttachedWindowShouldClose:(_CPAttachedWindow)anAttachedWindow
{
    [self close];

    // we return NO, because we want the CPPopover to compute
    // if the attached can be close in order to send delegate messages
    return NO;
}

@end


@implementation CPPopover (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _needsCompute = [aCoder decodeIntForKey:@"_needsCompute"];
        _appearance = [aCoder decodeIntForKey:@"_appearance"];
        _animates = [aCoder decodeBoolForKey:@"_animates"];
        _contentViewController = [aCoder decodeObjectForKey:@"_contentViewController"];
        [self setDelegate:[aCoder decodeObjectForKey:@"_delegate"]];
        [self setBehaviour:[aCoder decodeIntForKey:@"_behavior"]];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_behavior forKey:@"_behavior"];
    [aCoder encodeInt:_appearance forKey:@"_appearance"];
    [aCoder encodeBool:_needsCompute forKey:@"_needsCompute"];
    [aCoder encodeObject:_contentViewController forKey:@"_contentViewController"];
    [aCoder encodeObject:_delegate forKey:@"_delegate"];
    [aCoder encodeObject:_animates forKey:@"_animates"];
}

@end