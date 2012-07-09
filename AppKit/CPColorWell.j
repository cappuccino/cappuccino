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
    BOOL    _active;
    BOOL    _bordered;

    CPColor _color;
}

+ (Class)_binderClassForBinding:(CPString)theBinding
{
    if (theBinding == CPValueBinding)
        return [CPColorWellValueBinder class];

    return [super _binderClassForBinding:theBinding];
}

+ (CPString)defaultThemeClass
{
    return @"colorwell";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), [CPNull null], _CGInsetMake(3.0, 3.0, 3.0, 3.0), _CGInsetMakeZero(), [CPNull null]]
                                       forKeys:[@"bezel-inset", @"bezel-color", @"content-inset", @"content-border-inset", @"content-border-color"]];
}

- (void)_reverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:self];

    [theBinding reverseSetValueFor:@"color"];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _active = NO;
        _color = [CPColor whiteColor];
        [self setBordered:YES];

        [self _registerForNotifications];
    }

    return self;
}

- (void)_registerForNotifications
{
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

// Managing Color From Color Wells

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
    if (_color == aColor)
        return;

    _color = aColor;

    [self setNeedsLayout];
}

/*!
    Changes the color of the well to that of \c aSender.
    @param aSender the object from which to retrieve the color
*/
- (void)takeColorFrom:(id)aSender
{
    [self setColor:[aSender color]];
}

// Activating and Deactivating Color Wells
/*!
    Activates the color well, displays the color panel, and makes the panel's current color the same as its own.
    If exclusive is \c YES, deactivates any other CPColorWells. \c NO, keeps them active.
    @param shouldBeExclusive whether other color wells should be deactivated.
*/
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

/*!
    Deactivates the color well.
*/
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

/*!
    Returns \c YES if the color well is active.
*/
- (BOOL)isActive
{
    return _active;
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

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self highlight:NO];

    if (!mouseIsUp || !CGRectContainsPoint([self bounds], aPoint) || ![self isEnabled])
        return;

    [self activate:YES];

    var colorPanel = [CPColorPanel sharedColorPanel];

    [colorPanel setColor:_color];
    [colorPanel orderFront:self];
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];

    return _CGRectInsetByInset(bounds, contentInset);
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    return _CGRectInsetByInset(bounds, bezelInset);
}

- (CGRect)contentBorderRectForBounds:(CGRect)bounds
{
    var contentBorderInset = [self currentValueForThemeAttribute:@"content-border-inset"];

    return _CGRectInsetByInset(bounds, contentBorderInset);
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
    var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

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
    var placeholderColor = [CPColor blueColor];

    [self _setPlaceholder:placeholderColor forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:placeholderColor forMarker:CPNullMarker isDefault:YES];
}

- (void)setValueFor:(CPString)theBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [destination valueForKeyPath:keyPath],
        isPlaceholder = CPIsControllerMarker(newValue);

    if (isPlaceholder)
    {
        if (newValue === CPNotApplicableMarker && [options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
        {
           [CPException raise:CPGenericException
                       reason:@"can't transform non applicable key on: " + _source + " value: " + newValue];
        }

        newValue = [self _placeholderForMarker:newValue];
    }
    else
    {
        newValue = [self transformValue:newValue withOptions:options];
    }

    [_source setColor:newValue];
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
        _active = NO;
        _color = [aCoder decodeObjectForKey:CPColorWellColorKey];
        [self setBordered:[aCoder decodeBoolForKey:CPColorWellBorderedKey]];

        [self _registerForNotifications];
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
