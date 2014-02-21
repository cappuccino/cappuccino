/*
 * _CPToolTip.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2011 <primalmotion@archipelproject.org>
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
@import "CPWindow.j"

@global CPApp
@class _CPToolTipWindowView

_CPToolTipWindowMask = 1 << 27;

var _CPToolTipHeight = 24.0,
    _CPToolTipFontSize = 11.0,
    _CPToolTipDelay = 1.0,
    _CPToolTipCurrentToolTip,
    _CPToolTipCurrentToolTipTimer;

/*! @ingroup appkit
    This is a basic tooltip that behaves mostly like Cocoa ones.
*/
@implementation _CPToolTip : CPWindow
{
    CPTextField _content;
}


#pragma mark -
#pragma mark Class Methods

/*! @ignore
    Invalidate any scheduled tooltips, or hide any visible one
*/
+ (void)invalidateCurrentToolTipIfNeeded
{
    if (_CPToolTipCurrentToolTipTimer)
    {
        [_CPToolTipCurrentToolTipTimer invalidate];
        _CPToolTipCurrentToolTipTimer = nil;
    }

    if (_CPToolTipCurrentToolTip)
    {
        [_CPToolTipCurrentToolTip close];
        _CPToolTipCurrentToolTip = nil;
    }
}

/*! @ignore
    Schedule a tooltip for the given view
    @param aView the view that might display the tooltip
*/
+ (void)scheduleToolTipForView:(CPView)aView
{
    if (![aView toolTip] || ![[aView toolTip] length])
        return;

    [_CPToolTip invalidateCurrentToolTipIfNeeded];

    var callbackFunction = function() {
        [_CPToolTip invalidateCurrentToolTipIfNeeded];
        _CPToolTipCurrentToolTip = [_CPToolTip toolTipWithString:[aView toolTip]];
        [_CPToolTipCurrentToolTip setPlatformWindow:[[aView window] platformWindow]];
    };

    _CPToolTipCurrentToolTipTimer = [CPTimer scheduledTimerWithTimeInterval:_CPToolTipDelay
                                                                   callback:callbackFunction
                                                                    repeats:NO];
}


/*! Returns an initialized _CPToolTip with the given text and attach it to given view.
    @param aString the content of the tooltip
*/
+ (_CPToolTip)toolTipWithString:(CPString)aString
{
    var tooltip = [[_CPToolTip alloc] initWithString:aString styleMask:_CPToolTipWindowMask];

    [tooltip showToolTip];

    return tooltip;
}

/*!
    Compute a cool size for the given string.

    @param aToolTipSize a frame with the maximum width desired for the tooltip
    @param aText the wanted text
    @return CPArray containing the computer toolTipSize and textFrameSize
*/
+ (CGSize)computeCorrectSize:(CGSize)aToolTipSize text:(CPString)aText
{
    var font = [CPFont systemFontOfSize:_CPToolTipFontSize],
        textFrameSizeSingleLine = [aText sizeWithFont:font],
        textFrameSize = [aText sizeWithFont:font inWidth:(aToolTipSize.width)];

    // If the text fully fits within the maximum width, shrink to fit.
    if (textFrameSizeSingleLine.width < aToolTipSize.width)
    {
        var textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()],
            inset = [textField currentValueForThemeAttribute:@"content-inset"] || CGInsetMakeZero();
        textFrameSize = textFrameSizeSingleLine;
        textFrameSize.width += inset.left + inset.right;
        aToolTipSize.width = textFrameSize.width;
    }

    if (textFrameSize.height < 100)
    {
        aToolTipSize.height = textFrameSize.height + 4;
        return [aToolTipSize, textFrameSize];
    }

    var newWidth        = aToolTipSize.width + ((parseInt(textFrameSize.height - 100) / _CPToolTipHeight) * _CPToolTipHeight);
    textFrameSize       = [aText sizeWithFont:font inWidth:newWidth - 4];
    aToolTipSize.width  = newWidth + 2;
    aToolTipSize.height = textFrameSize.height + 4;

    return [aToolTipSize, textFrameSize];
}

/*!
    Override default windowView class loader.

    @param aStyleMask the window mask
    @return the windowView class
*/
+ (Class)_windowViewClassForStyleMask:(unsigned)aStyleMask
{
    return _CPToolTipWindowView;
}


#pragma mark -
#pragma mark Initialization

/*!
    Returns an initialized _CPToolTip with string.

    @param aString the content of the tooltip
    @param aStyleMask the tooltip's style mask
*/
- (id)initWithString:(CPString)aString styleMask:(unsigned)aStyleMask
{
    var toolTipFrame = CGRectMake(0.0, 0.0, 250.0, _CPToolTipHeight),
        layout = [_CPToolTip computeCorrectSize:toolTipFrame.size text:aString],
        textFrameSize = layout[1];

    toolTipFrame.size = layout[0];

    if (self = [super initWithContentRect:toolTipFrame styleMask:aStyleMask])
    {
        _constrainsToUsableScreen = NO;

        textFrameSize.height += 4;

        _content = [CPTextField labelWithTitle:aString];
        [_content setFont:[CPFont systemFontOfSize:_CPToolTipFontSize]]
        [_content setLineBreakMode:CPLineBreakByCharWrapping];
        [_content setAlignment:CPJustifiedTextAlignment];
        [_content setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_content setFrameOrigin:CGPointMake(0.0, 0.0)];
        [_content setFrameSize:textFrameSize];
        [_content setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_content setTextColor:[[[CPTheme defaultTheme] attributeWithName:@"color" forClass:_CPToolTipWindowView] value]];

        [[self contentView] addSubview:_content];

        [self setLevel:CPStatusWindowLevel];
        [self setAlphaValue:0.9];

        [_windowView setNeedsDisplay:YES];
    }

    return self;
}


#pragma mark -
#pragma mark Controls

/*!
    Show the tooltip after computing the position.
*/
- (void)showToolTip
{
    var mousePosition = [[CPApp currentEvent] globalLocation],
        nativeRect = [[self platformWindow] nativeContentRect];

    mousePosition.y += 20;

    if (mousePosition.x < 0)
        mousePosition.x = 5;
    if (mousePosition.x + CGRectGetWidth([self frame]) > nativeRect.size.width)
        mousePosition.x = nativeRect.size.width - CGRectGetWidth([self frame]) - 5;
    if (mousePosition.y < 0)
        mousePosition.y = 5;
    if (mousePosition.y + CGRectGetHeight([self frame]) > nativeRect.size.height)
        mousePosition.y = mousePosition.y - CGRectGetHeight([self frame]) - 40;

    [self setFrameOrigin:mousePosition];
    [self orderFront:nil];
}

@end
