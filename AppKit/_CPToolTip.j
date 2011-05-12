/*
 * _CPToolTip.j
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

@import "_CPAttachedWindow.j"

var CPCurrentToolTip,
    CPCurrentToolTipTimer;

CPToolTipDefaultColorMask = CPAttachedBlackWindowMask;

/*! @ingroup appkit
    subclass of CPAttachedWindow in order to build quick tooltip
*/
@implementation _CPToolTip : _CPAttachedWindow
{
    CPTextField _content;
}

#pragma mark -
#pragma mark Class Methods

/*! returns an initialized CPToolTip with string and attach it to given view
    @param aString the content of the tooltip
    @param aView the view where the tooltip will be attached
*/
+ (_CPToolTip)toolTipWithString:(CPString)aString forView:(CPView)aView
{
    var tooltip = [[_CPToolTip alloc] initWithString:aString styleMask:CPToolTipDefaultColorMask];

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
        layout = [_CPToolTip computeCorrectSize:toolTipFrame.size text:aString],
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

@implementation CPControl (Tooltips)

/*!
    Sets the tooltip for the receiver.

    @param aToolTip the tooltip
*/
- (void)setToolTip:(CPString)aToolTip
{
    if (_toolTip == aToolTip)
        return;

    _toolTip = aToolTip;

    if (!_DOMElement)
        return;

    var fIn = function(e)
            {
                [self _fireToolTip];
            },
        fOut = function(e)
            {
                 [self _invalidateToolTip];
            };

    if (_toolTip)
    {
        if (_DOMElement.addEventListener)
        {
            _DOMElement.addEventListener("mouseover", fIn, NO);
            _DOMElement.addEventListener("keypress", fOut, NO);
            _DOMElement.addEventListener("mouseout", fOut, NO);
        }
        else if (_DOMElement.attachEvent)
        {
            _DOMElement.attachEvent("onmouseover", fIn);
            _DOMElement.attachEvent("onkeypress", fOut);
            _DOMElement.attachEvent("onmouseout", fOut);
        }
    }
    else
    {
        if (_DOMElement.removeEventListener)
        {
            _DOMElement.removeEventListener("mouseover", fIn, NO);
            _DOMElement.removeEventListener("keypress", fOut, NO);
            _DOMElement.removeEventListener("mouseout", fOut, NO);
        }
        else if (_DOMElement.detachEvent)
        {
            _DOMElement.detachEvent("onmouseover", fIn);
            _DOMElement.detachEvent("onkeypress", fOut);
            _DOMElement.detachEvent("onmouseout", fOut);
        }
    }
}

/*!
    Returns the receiver's tooltip
*/
- (CPString)toolTip
{
    return _toolTip;
}

/*! @ignore
    starts the tooltip timer
*/
- (void)_fireToolTip
{
    if (CPCurrentToolTipTimer)
    {
        [CPCurrentToolTipTimer invalidate];
        if (CPCurrentToolTip)
            [CPCurrentToolTip close:nil];
        CPCurrentToolTip = nil;
    }

    if (_toolTip)
        CPCurrentToolTipTimer = [CPTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(_showToolTip:) userInfo:nil repeats:NO];
}

/*! @ignore
    Stop the tooltip timer if any
*/
- (void)_invalidateToolTip
{
    if (CPCurrentToolTipTimer)
    {
        [CPCurrentToolTipTimer invalidate];
        CPCurrentToolTipTimer = nil;
    }

    if (CPCurrentToolTip)
    {
        [CPCurrentToolTip close:nil];
        CPCurrentToolTip = nil;
    }
}

/*! @ignore
    Actually shows the tooltip if any
*/
- (void)_showToolTip:(CPTimer)aTimer
{
    if (CPCurrentToolTip)
        [CPCurrentToolTip close:nil];
    CPCurrentToolTip = [_CPToolTip toolTipWithString:_toolTip forView:self];
}

@end