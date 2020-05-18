/*
 * CPSVGView.j
 * AppKit
 *
 * Created by Robert Grant.
 * Copyright 2015, plasq LLC.
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

/*!
    @ingroup appkit

    @class CPSVGView

    CPSVGView allows you to draw into SVG contexts.

    The default graphics context created is a DIV based context.
    Unlike a Canvas based context as DIV context allows SVG child
    elements to be nested within it.
*/
@implementation CPSVGView : CPView

/*!
    Locks focus on the receiver, so drawing commands apply to it.
*/
- (void)lockFocus
{
    if (!_graphicsContext)
    {
        var graphicsPort = CGDIVGraphicsContextCreate();

#if PLATFORM(DOM)
        var width = CGRectGetWidth(_frame),
            height = CGRectGetHeight(_frame),
            devicePixelRatio = window.devicePixelRatio || 1,
            backingStoreRatio = CPBrowserBackingStorePixelRatio(graphicsPort);

        _highDPIRatio = devicePixelRatio / backingStoreRatio;

        _DOMContentsElement = graphicsPort.DOMElement;

        _DOMContentsElement.style.zIndex = -100;

        _DOMContentsElement.style.overflow = "hidden";
        _DOMContentsElement.style.position = "absolute";
        _DOMContentsElement.style.visibility = "visible";

        CPDOMDisplayServerSetSize(_DOMContentsElement, width * _highDPIRatio, height * _highDPIRatio);

        CPDOMDisplayServerSetStyleLeftTop(_DOMContentsElement, NULL, 0.0, 0.0);
        CPDOMDisplayServerSetStyleSize(_DOMContentsElement, width, height);

        // The performance implications of this aren't clear, but without this subviews might not be redrawn when this
        // view moves.
        if (CPPlatformHasBug(CPCanvasParentDrawErrorsOnMovementBug))
            _DOMElement.style.webkitTransform = 'translateX(0)';

        CPDOMDisplayServerAppendChild(_DOMElement, _DOMContentsElement);
#endif
        _graphicsContext = [CPGraphicsContext graphicsContextWithGraphicsPort:graphicsPort flipped:YES];
    }

    [CPGraphicsContext setCurrentContext:_graphicsContext];

    CGContextSaveGState([_graphicsContext graphicsPort]);
}

/*!
    Takes focus away from the receiver, and restores it to the previous view.
*/
- (void)unlockFocus
{
    CGContextRestoreGState([_graphicsContext graphicsPort]);

    [CPGraphicsContext setCurrentContext:nil];
}

@end