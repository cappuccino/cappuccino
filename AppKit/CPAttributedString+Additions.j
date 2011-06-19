/*
 * CPAttributedString+Additions.j
 * AppKit
 *
 * Created by Randy Luecke
 * Copyright 2011, RCLConcepts, LLC.
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


/*
    AppKit adds two methods to the CPAttributedString class to support drawing string directly in an CPView.

    AppKit also adds similar methods to CPString.
*/
@implementation CPAttributedString (AppKitAdditions)
/*!
    Draws a string in the current graphics context.
    This method and draws the reciver on a single "infinately long" line.

    @param aPoint - The starting point to draw the string
*/
- (void)drawAtPoint:(CGPoint)aPoint
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        line = CTLineCreateWithAttributedString([self copy]);

    CGContextSetTextPosition(context, aPoint.x, aPoint.y);
    CTLineDraw(line, context);
}

/*!
    Draws a string in the current graphics context.

    @param aRect - The rect for which the string should be drawn into
*/
- (void)drawInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        frameSetter = CTFramesetterCreateWithAttributedString([self copy]),
        path = CGPathCreateMutable();

    CGPathAddRect(path, nil, aRect);
    
    var frame = CTFramesetterCreateFrame(frameSetter, CPMakeRange(0, [self length]), path, nil);

    CTFrameDraw(frame, context);
}
@end
