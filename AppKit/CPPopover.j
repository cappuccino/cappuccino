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
    CPPopoverDelegate_popover_willClose_    = 1 << 3,
    CPPopoverDelegate_popover_didClose_     = 1 << 4;


/*! @ingroup appkit
    @class CPPopover

    This class represent a widget that displays a attached
    view relative to another one.

    Delegate can implement:

    @code
    – popoverShouldClose:(CPPopover)aPopOver
    – popoverWillShow:(CPPopover)aPopOver
    – popoverDidShow:(CPPopover)aPopOver
    – popoverWillClose:(CPPopover)aPopOver
    – popoverDidClose:(CPPopover)aPopOver
    @endcode
*/
@implementation CPPopover : CPResponder
{
    @outlet CPViewController    _contentViewController  @accessors(property=contentViewController);
    @outlet id                  _delegate               @accessors(getter=delegate);

    BOOL                        _animates               @accessors(property=animates);
    int                         _appearance             @accessors(property=appearance);
    int                         _behavior               @accessors(getter=behavior);

    _CPAttachedWindow           _attachedWindow;
    int                         _implementedDelegateMethods;
}


#pragma mark -
#pragma mark Initialization

/*!
    Initialize the CPPopover witn default values

    @returns an initialized CPPopover
*/
- (CPPopover)init
{
    if (self = [super init])
    {
        _animates      = YES;
        _appearance    = CPPopoverAppearanceMinimal;
        _behavior      = CPPopoverBehaviorApplicationDefined;
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*!
    Returns the current rect of the popover

    @return CGRect representing the frame of the popover
*/
- (CGRect)positioningRect
{
    if (![_attachedWindow isVisible])
        return CGRectMakeZero();
    return [_attachedWindow frame];
}

/*! Sets the frame of the popover
    @param aRect the desired frame
*/
- (void)setPositioningRect:(CGRect)aRect
{
    if (![_attachedWindow isVisible])
        return;
    [_attachedWindow setFrame:aRect];
}

/*!
    Returns the size of the popover's view

    @return CGSize representing the size of the popover's view
*/
- (CGSize)contentSize
{
    if (![_attachedWindow isVisible])
        return CGRectMakeZero();
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

    @returns \c YES if visible
*/
- (BOOL)isShown
{
    return [_attachedWindow isVisible];
}

/*!
Set the behavior of the CPPopover. It can be:

- \c CPPopoverBehaviorTransient: the popover will close if another control outside the popover becomes the responder
- \c CPPopoverBehaviorApplicationDefined: (DEFAULT) the application is responsible for closing the popover

@param aBehavior the desired behavior
*/
- (void)setBehavior:(int)aBehavior
{
    if (_behavior == aBehavior)
        return;

    _behavior = aBehavior;
    [_attachedWindow setStyleMask:[self styleMaskForBehavior]];
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
#pragma mark Positioning

/*!
    Show the popover

    @param positioningRect if set, the popover will be positionned to a random rect relative to the window
    @param positioningView if set, the popover will be positioned relative to this view
    @param preferredEdge: \c CPRectEdge representing the preferred positioning.
*/
- (void)showRelativeToRect:(CGRect)positioningRect ofView:(CPView)positioningView preferredEdge:(CPRectEdge)preferredEdge
{
    if (!positioningView)
        [CPException raise:CPInvalidArgumentException reason:"positionView must not be nil"];

    if (!_contentViewController)
        [CPException raise:CPInternalInconsistencyException reason:@"contentViewController must not be nil"];

    // If the popover is currently closing, do nothing. That is what Cocoa does.
    if ([_attachedWindow isClosing])
        return;

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_willShow_)
        [_delegate popoverWillShow:self];

    if (!_attachedWindow)
    {
        _attachedWindow = [[_CPAttachedWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:[self styleMaskForBehavior]];

        var parentWindow = [positioningView window];

        if (![parentWindow isKindOfClass:_CPAttachedWindow])
            [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(parentWindowWillClose:) name:CPWindowWillCloseNotification object:parentWindow];
    }

    [_attachedWindow setAppearance:_appearance];
    [_attachedWindow setAnimates:_animates];
    [_attachedWindow setDelegate:self];
    [_attachedWindow setMovableByWindowBackground:NO];
    [_attachedWindow setFrame:[_attachedWindow frameRectForContentRect:[[_contentViewController view] frame]]];
    [_attachedWindow setContentView:[_contentViewController view]];
    [_attachedWindow positionRelativeToRect:positioningRect ofView:positioningView preferredEdge:preferredEdge];

    if (!_animates && _implementedDelegateMethods & CPPopoverDelegate_popover_didShow_)
        [_delegate popoverDidShow:self];
}

- (unsigned)styleMaskForBehavior
{
    return (_behavior == CPPopoverBehaviorTransient) ? CPClosableOnBlurWindowMask : 0;
}

/*!
    Closes the popover
*/
- (void)close
{
    [self _close];
}

/*!
    Closes the popover
*/
- (void)_close
{
    if ([_attachedWindow isClosing] || ![self isShown])
        return;

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_willClose_)
        [_delegate popoverWillClose:self];

    [_attachedWindow close];

    // popoverDidClose will be sent from attachedWindowDidClose, since
    // the attached window will close asynchronously when animating.
}


#pragma mark -
#pragma mark Action

/*!
    Close the popover

    @param sender the sender of the action
*/
- (IBAction)performClose:(id)sender
{
    if ([_attachedWindow isClosing])
        return;

    if (_implementedDelegateMethods & CPPopoverDelegate_popover_shouldClose_)
        if (![_delegate popoverShouldClose:self])
            return;

    [self _close];
}


#pragma mark -
#pragma mark Delegates

/*! @ignore */
- (BOOL)attachedWindowShouldClose:(_CPAttachedWindow)anAttachedWindow
{
    [self performClose:self];

    // We return NO, because we want the CPPopover to determine
    // if the attached window can be closed and to give us a chance
    // to send delegate messages.
    return NO;
}

/*! @ignore */
- (void)attachedWindowDidClose:(_CPAttachedWindow)anAttachedWindow
{
    if (_implementedDelegateMethods & CPPopoverDelegate_popover_didClose_)
        [_delegate popoverDidClose:self];
}

/*! @ignore */
- (void)attachedWindowDidShow:(_CPAttachedWindow)anAttachedWindow
{
    if (_implementedDelegateMethods & CPPopoverDelegate_popover_didShow_)
        [_delegate popoverDidShow:self];
}


#pragma mark -
#pragma mark Notifications

/*!
    @ignore

    This method is called only when a non-popover parent window
    is closing. In that case popovers should order out.
*/
- (void)parentWindowWillClose:(CPNotification)aNotification
{
    [_attachedWindow orderOut:nil];
    [self performClose:nil];
}

@end

@implementation CPPopover (Deprecated)

- (void)setBehaviour:(int)aBehavior
{
    _CPReportLenientDeprecation(self, _cmd, @selector(setBehavior:));

    [self setBehavior:aBehavior];
}

@end

var CPPopoverNeedsNewAttachedWindowKey = @"CPPopoverNeedsNewAttachedWindowKey",
    CPPopoverAppearanceKey = @"CPPopoverAppearanceKey",
    CPPopoverAnimatesKey = @"CPPopoverAnimatesKey",
    CPPopoverContentViewControllerKey = @"CPPopoverContentViewControllerKey",
    CPPopoverDelegateKey = @"CPPopoverDelegateKey",
    CPPopoverBehaviorKey = @"CPPopoverBehaviorKey";

@implementation CPPopover (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _appearance = [aCoder decodeIntForKey:CPPopoverAppearanceKey];
        _animates = [aCoder decodeBoolForKey:CPPopoverAnimatesKey];
        _contentViewController = [aCoder decodeObjectForKey:CPPopoverContentViewControllerKey];
        [self setDelegate:[aCoder decodeObjectForKey:CPPopoverDelegateKey]];
        [self setBehavior:[aCoder decodeIntForKey:CPPopoverBehaviorKey]];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_appearance forKey:CPPopoverAppearanceKey];
    [aCoder encodeBool:_animates forKey:CPPopoverAnimatesKey];
    [aCoder encodeObject:_contentViewController forKey:CPPopoverContentViewControllerKey];
    [aCoder encodeObject:_delegate forKey:CPPopoverDelegateKey];
    [aCoder encodeInt:_behavior forKey:CPPopoverBehaviorKey];
}

@end
