/*
 * CPStepper.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2009, Antoine Mercadal
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
@import "CPView.j"

@import "CPAttachedWindow.j"


CPToolTipDefaultColorMask = CPAttachedBlackWindowMask;

/*! @ingroup appkit
    subclass of CPAttachedWindow in order to build quick tooltip
*/
@implementation CPToolTip : CPAttachedWindow
{
    CPTextField _content;
}

#pragma mark -
#pragma mark Class Methods

/*! returns an initialized CPToolTip with string and attach it to given view
    @param aString the content of the tooltip
    @param aView the view where the tooltip will be attached
*/
+ (CPToolTip)toolTipWithString:(CPString)aString forView:(CPView)aView
{
    var tooltip = [[CPToolTip alloc] initWithString:aString styleMask:CPToolTipDefaultColorMask];

    [tooltip setAlphaValue:0.9];
    [tooltip attachToView:aView];
    [tooltip resignMainWindow];

    return tooltip;
}

/*! compute a cool size for the given string
    @param aToolTipSize the original wanted tool tip size
    @param aText the wanted text
    @return CPArray containing the computer toolTipSize and textFrameSize
*/
+ (CPSize)computeCorrectSize:(CPSize)aToolTipSize text:(CPString)aText
{
    var font = [CPFont systemFontOfSize:12.0],
        textFrameSize = [aText sizeWithFont:font inWidth:(aToolTipSize.width - 10)];

    if (textFrameSize.height < 100)
    {
        aToolTipSize.height = textFrameSize.height + 10;
        return [aToolTipSize, textFrameSize];
    }

    var newWidth        = aToolTipSize.width + ((parseInt(textFrameSize.height - 100) / 30) * 30);
    textFrameSize       = [aText sizeWithFont:font inWidth:newWidth - 10];
    aToolTipSize.width  = newWidth + 5;
    aToolTipSize.height = textFrameSize.height + 10;

    return [aToolTipSize, textFrameSize];
}


#pragma mark -
#pragma mark Initialization

/*! returns an initialized CPToolTip with string
    @param aString the content of the tooltip
*/
- (id)initWithString:(CPString)aString styleMask:(unsigned)aStyleMask
{
    var toolTipFrame = CPRectMake(0.0, 0.0, 250.0, 30.0),
        layout = [CPToolTip computeCorrectSize:toolTipFrame.size text:aString],
        textFrameSize = layout[1];

    toolTipFrame.size = layout[0];

    if (self = [super initWithContentRect:toolTipFrame styleMask:aStyleMask])
    {
        textFrameSize.height += 4;

        _content = [CPTextField labelWithTitle:aString];
        [_content setLineBreakMode:CPLineBreakByCharWrapping];
        [_content setAlignment:CPJustifiedTextAlignment];
        [_content setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_content setFrameOrigin:CPPointMake(5.0, 5.0)];
        [_content setFrameSize:textFrameSize];
        [_content setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_content setTextColor:(aStyleMask & CPAttachedWhiteWindowMask) ? [CPColor blackColor] : [CPColor whiteColor]];
        [_content setValue:((aStyleMask & CPAttachedWhiteWindowMask) ? [CPColor whiteColor] : [CPColor blackColor]) forThemeAttribute:@"text-shadow-color"];

        [[self contentView] addSubview:_content];
        [self setMovableByWindowBackground:NO];
    }

    return self;
}

@end