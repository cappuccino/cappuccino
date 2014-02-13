/*
 * CPButtonBar.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPView.j"
@import "CPWindow_Constants.j"

@class CPSplitView

@global CPPopUpButtonStatePullsDown


@implementation CPButtonBar : CPView
{
    BOOL    _hasResizeControl;
    BOOL    _resizeControlIsLeftAligned;
    CPArray _buttons;
}

+ (id)plusButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
        image = [[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-plus" forClass:[CPButtonBar class]];

    [button setBordered:NO];
    [button setImage:image];
    [button setImagePosition:CPImageOnly];

    return button;
}

+ (id)minusButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
        image = [[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-minus" forClass:[CPButtonBar class]];

    [button setBordered:NO];
    [button setImage:image];
    [button setImagePosition:CPImageOnly];

    return button;
}

+ (id)actionPopupButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)],
        image = [[CPTheme defaultTheme] valueForAttributeWithName:@"button-image-action" forClass:[CPButtonBar class]];

    [button addItemWithTitle:nil];
    [[button lastItem] setImage:image];
    [button setImagePosition:CPImageOnly];
    [button setValue:CGInsetMake(0, 0, 0, 0) forThemeAttribute:"content-inset"];

    [button setPullsDown:YES];

    return button;
}

+ (CPString)defaultThemeClass
{
    return @"button-bar";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"resize-control-inset": CGInsetMake(0.0, 0.0, 0.0, 0.0),
            @"resize-control-size": CGSizeMakeZero(),
            @"resize-control-color": [CPNull null],
            @"bezel-color": [CPNull null],
            @"button-bezel-color": [CPNull null],
            @"button-text-color": [CPNull null],
            @"button-image-plus": [CPNull null],
            @"button-image-minus": [CPNull null],
            @"button-image-action": [CPNull null],
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _buttons = [];
        [self setNeedsLayout];
    }

    return self;
}

- (void)awakeFromCib
{
    var view = [self superview],
        subview = self;

    while (view)
    {
        if ([view isKindOfClass:[CPSplitView class]])
        {
            var viewIndex = [[view subviews] indexOfObject:subview];
            [view setButtonBar:self forDividerAtIndex:viewIndex];

            break;
        }

        subview = view;
        view = [view superview];
    }
}

- (void)setButtons:(CPArray)buttons
{
    _buttons = [CPArray arrayWithArray:buttons];

    for (var i = 0, count = [_buttons count]; i < count; i++)
        [_buttons[i] setBordered:YES];

    [self setNeedsLayout];
}

- (CPArray)buttons
{
    return [CPArray arrayWithArray:_buttons];
}

- (void)setHasResizeControl:(BOOL)shouldHaveResizeControl
{
    if (_hasResizeControl === shouldHaveResizeControl)
        return;

    _hasResizeControl = !!shouldHaveResizeControl;
    [self setNeedsLayout];
}

- (BOOL)hasResizeControl
{
    return _hasResizeControl;
}

- (void)setResizeControlIsLeftAligned:(BOOL)shouldBeLeftAligned
{
    if (_resizeControlIsLeftAligned === shouldBeLeftAligned)
        return;

    _resizeControlIsLeftAligned = !!shouldBeLeftAligned;
    [self setNeedsLayout];
}

- (BOOL)resizeControlIsLeftAligned
{
    return _resizeControlIsLeftAligned;
}

- (CGRect)resizeControlFrame
{
    var inset = [self currentValueForThemeAttribute:@"resize-control-inset"],
        size = [self currentValueForThemeAttribute:@"resize-control-size"],
        currentSize = [self bounds],
        leftOrigin = _resizeControlIsLeftAligned ? 0 : currentSize.size.width - size.width - inset.right - inset.left;

    return CGRectMake(leftOrigin, 0, size.width + inset.left + inset.right, size.height + inset.top + inset.bottom);
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "resize-control-view")
    {
        var inset = [self currentValueForThemeAttribute:@"resize-control-inset"],
            size = [self currentValueForThemeAttribute:@"resize-control-size"],
            currentSize = [self bounds];

        if (_resizeControlIsLeftAligned)
            return CGRectMake(inset.left, inset.top, size.width, size.height);
        else
            return CGRectMake(currentSize.size.width - size.width - inset.right, inset.top, size.width, size.height);
    }

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "resize-control-view")
        return [[CPView alloc] initWithFrame:CGRectMakeZero()];

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var normalColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateNormal],
        highlightedColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateHighlighted],
        disabledColor = [self valueForThemeAttribute:@"button-bezel-color" inState:CPThemeStateDisabled],
        textColor = [self valueForThemeAttribute:@"button-text-color" inState:CPThemeStateNormal];

    var buttonsNotHidden = [CPArray arrayWithArray:_buttons],
        count = [buttonsNotHidden count];

    while (count--)
        if ([buttonsNotHidden[count] isHidden])
            [buttonsNotHidden removeObject:buttonsNotHidden[count]];

    var currentButtonOffset = _resizeControlIsLeftAligned ? CGRectGetMaxX([self bounds]) + 1 : -1,
        bounds = [self bounds],
        height = CGRectGetHeight(bounds) - 1,
        frameWidth = CGRectGetWidth(bounds),
        resizeRect = _hasResizeControl ? [self rectForEphemeralSubviewNamed:"resize-control-view"] : CGRectMakeZero(),
        resizeWidth = CGRectGetWidth(resizeRect),
        availableWidth = frameWidth - resizeWidth - 1;

    for (var i = 0, count = [buttonsNotHidden count]; i < count; i++)
    {
        var button = buttonsNotHidden[i],
            width = CGRectGetWidth([button frame]);

        if (availableWidth > width)
            availableWidth -= width;
        else
            break;

        if (_resizeControlIsLeftAligned)
        {
            [button setFrame:CGRectMake(currentButtonOffset - width, 1, width, height)];
            currentButtonOffset -= width - 1;
        }
        else
        {
            [button setFrame:CGRectMake(currentButtonOffset, 1, width, height)];
            currentButtonOffset += width - 1;
        }

        [button setValue:normalColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateNormal, CPThemeStateBordered)];
        [button setValue:highlightedColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateHighlighted,  CPThemeStateBordered)];
        [button setValue:disabledColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
        [button setValue:textColor forThemeAttribute:@"text-color" inState:CPThemeStateBordered];

        // FIXME shouldn't need this
        [button setValue:normalColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateNormal, CPThemeStateBordered, CPPopUpButtonStatePullsDown)];
        [button setValue:highlightedColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateHighlighted, CPThemeStateBordered, CPPopUpButtonStatePullsDown)];
        [button setValue:disabledColor forThemeAttribute:@"bezel-color" inState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered, CPPopUpButtonStatePullsDown)];

        [self addSubview:button];
    }

    if (_hasResizeControl)
    {
        var resizeControlView = [self layoutEphemeralSubviewNamed:@"resize-control-view"
                                                       positioned:CPWindowAbove
                                  relativeToEphemeralSubviewNamed:nil];

        [resizeControlView setAutoresizingMask: _resizeControlIsLeftAligned ? CPViewMaxXMargin : CPViewMinXMargin];
        [resizeControlView setBackgroundColor:[self currentValueForThemeAttribute:@"resize-control-color"]];
    }
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self setNeedsLayout];
}

@end

var CPButtonBarHasResizeControlKey = @"CPButtonBarHasResizeControlKey",
    CPButtonBarResizeControlIsLeftAlignedKey = @"CPButtonBarResizeControlIsLeftAlignedKey",
    CPButtonBarButtonsKey = @"CPButtonBarButtonsKey";

@implementation CPButtonBar (CPCoding)

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_hasResizeControl forKey:CPButtonBarHasResizeControlKey];
    [aCoder encodeBool:_resizeControlIsLeftAligned forKey:CPButtonBarResizeControlIsLeftAlignedKey];
    [aCoder encodeObject:_buttons forKey:CPButtonBarButtonsKey];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _buttons = [aCoder decodeObjectForKey:CPButtonBarButtonsKey] || [];
        _hasResizeControl = [aCoder decodeBoolForKey:CPButtonBarHasResizeControlKey];
        _resizeControlIsLeftAligned = [aCoder decodeBoolForKey:CPButtonBarResizeControlIsLeftAlignedKey];
    }

    return self;
}

@end
