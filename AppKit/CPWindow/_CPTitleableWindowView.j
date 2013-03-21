/*
 * _CPTitleableWindowView.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2012, SlevenBits Ltd.
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

@import "CPTextField.j"
@import "_CPWindowView.j"


@implementation _CPTitleableWindowView : _CPWindowView
{
    CPTextField _titleField;
}

+ (int)titleBarHeight
{
    return [[CPTheme defaultTheme] valueForAttributeWithName:@"title-bar-height" forClass:[self class]];
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [super contentRectForFrameRect:aFrameRect],
        titleBarHeight = [self titleBarHeight];

    contentRect.origin.y += titleBarHeight;
    contentRect.size.height -= titleBarHeight;

    return contentRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = CGRectMakeCopy(aContentRect),
        titleBarHeight = [self titleBarHeight];

    frameRect.origin.y -= titleBarHeight;
    frameRect.size.height += titleBarHeight;

    return frameRect;
}

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_titleField setHitTests:NO];
        [_titleField setStringValue:@"Untitled"];
        [_titleField sizeToFit];
        [_titleField setAutoresizingMask:CPViewWidthSizable];
        [_titleField setStringValue:@""];

        [_titleField setFrame:CGRectMake(20.0, 3.0, CGRectGetWidth([self bounds]) - 40.0, CGRectGetHeight([_titleField frame]))];

        [self addSubview:_titleField];

        [self setNeedsLayout];
    }

    return self;
}

- (void)setTitle:(CPString)aTitle
{
    [_titleField setStringValue:aTitle];
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds],
        width = CGRectGetWidth(bounds);

    // The vertical alignment of the title is set by the theme, so just give it all available space. By default
    // the title will vertically centre within.
    [_titleField setFrame:CGRectMake(20.0, 0, width - 40.0, [[self class] titleBarHeight])];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setBackgroundColor:[self valueForThemeAttribute:@"bezel-color"]];

    [_titleField setTextColor:[self currentValueForThemeAttribute:@"title-text-color"]];
    [_titleField setFont:[self currentValueForThemeAttribute:@"title-font"]];
    [_titleField setAlignment:[self currentValueForThemeAttribute:@"title-alignment"]];
    [_titleField setVerticalAlignment:[self currentValueForThemeAttribute:@"title-vertical-alignment"]];
    [_titleField setLineBreakMode:[self currentValueForThemeAttribute:@"title-line-break-mode"]];
    [_titleField setTextShadowColor:[self currentValueForThemeAttribute:@"title-text-shadow-color"]];
    [_titleField setTextShadowOffset:[self currentValueForThemeAttribute:@"title-text-shadow-offset"]];
}

- (CGSize)_minimumResizeSize
{
    var size = [super _minimumResizeSize];

    size.height += [[self class] titleBarHeight];
    return size;
}

- (int)bodyOffset
{
    return [self contentRectForFrameRect:[self frame]].origin.y;
}

@end
