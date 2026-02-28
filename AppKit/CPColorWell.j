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

@import <Foundation/CPString.j>

@import "CPView.j"
@import "CPColor.j"
@import "CPColorPanel.j"

var _CPColorWellDidBecomeExclusiveNotification = @"_CPColorWellDidBecomeExclusiveNotification";

/*!
    @ingroup appkit
    @class CPColorWell

    CPColorWell is a CPControl for selecting and displaying a single color value. An example of a CPColorWell object (or simply color well) is found in CPColorPanel, which uses a color well to display the current color selection.</p>

    <p>An application can have one or more active CPColorWells. You can activate multiple CPColorWells by invoking the \c -activate: method with \c NO as its argument. When a mouse-down event occurs on an CPColorWell's border, it becomes the only active color well. When a color well becomes active, it brings up the color panel also.
*/
@implementation CPColorWell : CPControl
{
    BOOL    _bordered;
    CPColor _color;
    BOOL    _isChangingColorFromPanel; // Guard flag to prevent recursion
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return [CPColorWellValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

+ (CPString)defaultThemeClass
{
    return @"colorwell";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"bezel-inset": CGInsetMakeZero(),
            @"bezel-color": [CPNull null],
            @"content-inset": CGInsetMake(3.0, 3.0, 3.0, 3.0),
            @"content-border-inset": CGInsetMakeZero(),
            @"content-border-color": [CPNull null],
        };
}

- (void)_reverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:self];

    [theBinding reverseSetValueFor:@"color"];
}

- (BOOL)isFirstResponder
{
    return [[self window] firstResponder] === self;
}

- (BOOL)acceptsFirstResponder
{
    return [self isEnabled];
}

- (void)activate:(BOOL)shouldBeExclusive
{
    [[self window] makeFirstResponder:self];
    [[CPColorPanel sharedColorPanel] orderFront:self];
}

- (BOOL)isActive
{
    return [self isFirstResponder] && [self isEnabled];
}

/*!
    Deactivates the color well.
*/
- (void)deactivate
{
    if ([self isFirstResponder])
        [[self window] makeFirstResponder:nil];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _color = [CPColor whiteColor];
        [self setBordered:YES];
        
        // Register using string literal to avoid dependency issues
        [self registerForDraggedTypes:[CPArray arrayWithObject:@"CPColorDragType"]];
    }

    return self;
}

#pragma mark -
#pragma mark Draw

/*!
    Sets whether the color well is bordered.
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];
}

/*!
    Returns whether the color well is bordered
*/
- (BOOL)isBordered
{
    return [self hasThemeState:CPThemeStateBordered];
}

#pragma mark -
#pragma mark Managing Color

/*!
    Returns the color well's current color.
*/
- (CPColor)color
{
    return _color;
}

/*!
    Sets the color well's current color.
*/
- (void)setColor:(CPColor)aColor
{
    if ([_color isEqual:aColor])
        return;

    _color = aColor;

    [self setNeedsLayout];
    
    // Only push back to the panel if we initiated the change (not if the panel pushed it to us)
    // AND if we are the current focus.
    if (!_isChangingColorFromPanel && [self isFirstResponder])
        [[CPColorPanel sharedColorPanel] setColor:_color];
}

/*!
    Changes the color of the well to that of \c aSender.
    @param aSender the object from which to retrieve the color
*/
- (void)takeColorFrom:(id)aSender
{
    [self setColor:[aSender color]];
}

/*!
    Standard action method sent by CPColorPanel via the Responder Chain.
*/
- (void)changeColor:(id)aSender
{
    if ([aSender isKindOfClass:[CPColorPanel class]])
    {
        _isChangingColorFromPanel = YES;
        [self setColor:[aSender color]];
        _isChangingColorFromPanel = NO;
        
        // Forward the action to our target (e.g. controller)
        [self sendAction:[self action] to:[self target]];
    }
}

#pragma mark -
#pragma mark Activating and Deactivating

/*!
    Activates the color well, displays the color panel, and makes the panel's current color the same as its own.
    If exclusive is \c YES, deactivates any other CPColorWells. \c NO, keeps them active.
    @param shouldBeExclusive whether other color wells should be deactivated.
*/
- (BOOL)becomeFirstResponder
{
    [self setThemeState:CPThemeStateFirstResponder];
    
    var panel = [CPColorPanel sharedColorPanel];

    // EXPLICITLY set ourselves as the target.
    // This ensures that when the user clicks the panel (making Panel key),
    // the panel still knows to send messages back to us.
    [panel setTarget:self];
    [panel setAction:@selector(changeColor:)];

    // Sync panel to our current color
    [panel setColor:_color];


    [[CPNotificationCenter defaultCenter] postNotificationName:_CPColorWellDidBecomeExclusiveNotification object:self];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self unsetThemeState:CPThemeStateFirstResponder];
    
    var panel = [CPColorPanel sharedColorPanel];

    // Clean up if we were the target
    if ([panel target] == self)
        [panel setTarget:nil];
        
    return YES;
}

#pragma mark -
#pragma mark Event Handling

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self activate:YES];
}

#pragma mark -
#pragma mark Drag and Drop

- (void)draggingEntered:(id)sender
{
    var pasteboard = [sender draggingPasteboard];
    
    if ([[pasteboard types] containsObject:@"CPColorDragType"])
    {
        [self setThemeState:CPThemeStateHighlighted];
        return CPDragOperationCopy;
    }
    
    return CPDragOperationNone;
}

- (void)draggingExited:(id)sender
{
    [self unsetThemeState:CPThemeStateHighlighted];
}

- (BOOL)performDragOperation:(id)sender
{
    var pasteboard = [sender draggingPasteboard];
    
    if ([[pasteboard types] containsObject:@"CPColorDragType"])
    {
        var data = [pasteboard dataForType:@"CPColorDragType"],
            newColor = [CPKeyedUnarchiver unarchiveObjectWithData:data];
            
        if (newColor && [newColor isKindOfClass:[CPColor class]])
        {
            [self setColor:newColor];
            [self sendAction:[self action] to:[self target]];
            
            // Activate nicely after drop
            [self activate:YES];
            [self unsetThemeState:CPThemeStateHighlighted];
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -
#pragma mark Layout

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];
    return CGRectInsetByInset(bounds, contentInset);
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];
    return CGRectInsetByInset(bounds, bezelInset);
}

- (CGRect)contentBorderRectForBounds:(CGRect)bounds
{
    var contentBorderInset = [self currentValueForThemeAttribute:@"content-border-inset"];
    return CGRectInsetByInset(bounds, contentBorderInset);
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    switch (aName)
    {
        case "bezel-view":
            return [self bezelRectForBounds:[self bounds]];
        case "content-view":
            return [self contentRectForBounds:[self bounds]];
        case "content-border-view":
            return [self contentBorderRectForBounds:[self bounds]];
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [view setHitTests:NO];
    return view;
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];

    [bezelView setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    [contentView setBackgroundColor:_color];
    
    var contentBorderView = [self layoutEphemeralSubviewNamed:@"content-border-view"
                                                   positioned:CPWindowAbove
                              relativeToEphemeralSubviewNamed:@"content-view"];

    [contentBorderView setBackgroundColor:[self currentValueForThemeAttribute:@"content-border-color"]];
}

@end

@implementation CPColorWellValueBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    var placeholderColor = [CPColor blackColor];

    [self _setPlaceholder:placeholderColor forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNullMarker isDefault:YES];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source color];
}

- (void)setValue:(id)aValue forBinding:(CPString)theBinding
{
    [_source setColor:aValue];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setColor:aValue];
}

@end

var CPColorWellColorKey     = "CPColorWellColorKey",
    CPColorWellBorderedKey  = "CPColorWellBorderedKey";

@implementation CPColorWell (CPCoding)

/*!
    Initializes the color well by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPColorWell.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _color = [aCoder decodeObjectForKey:CPColorWellColorKey];
        [self setBordered:[aCoder decodeBoolForKey:CPColorWellBorderedKey]];
        [self registerForDraggedTypes:[CPArray arrayWithObject:@"CPColorDragType"]];
    }

    return self;
}

/*!
    Archives this button into the provided coder.
    @param aCoder the coder to which the color well's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_color forKey:CPColorWellColorKey];
    [aCoder encodeObject:[self isBordered] forKey:CPColorWellBorderedKey];
}

@end
