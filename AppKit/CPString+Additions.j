/*
 * CPString+Additions.j
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
    AppKit adds two methods to the CPString class to support drawing string directly in an CPView.

    AppKit also adds similar methods to CPAttributedString.
    The two drawing methods draw a string object with a single set of attributes that apply to the entire string.
    To draw a string with multiple attributes, such as multiple text fonts, you must use an attributed string.
*/
@implementation CPString (AppKitAdditions)

/*!
    Draws a string in the current graphics context.
    This method applies the attributes to the entier string
    and displays it on a single "infinately long" line.

    @param aPoint - The starting point to draw the string
    @param attributes - the dictionary of attributes to apply to the string
*/
- (void)drawAtPoint:(CGPoint)aPoint withAttributes:(CPDictionary)attributes
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        run = _CTRunCreate([self copy], attributes);

    CGContextSetTextPosition(context, aPoint.x, aPoint.y);
    CTRunDraw(run, context, nil);
}

/*!
    Draws a string in the current graphics context.
    This method applies the attributes to the entier string
    and displays it within the given rect.

    @param aRect - The rect for which the string should be drawn into
    @param attributes - the dictionary of attributes to apply to the string
*/
- (void)drawInRect:(CGRect)aRect withAttributes:(CPDictionary)attributes
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        string = [[CPAttributedString alloc] initWithString:self attributes:attributes];
        frameSetter = CTFramesetterCreateWithAttributedString(string),
        path = CGPathCreateMutable();

    CGPathAddRect(path, nil, aRect);
    
    var frame = CTFramesetterCreateFrame(frameSetter, CPMakeRange(0, [string length]), path, nil);

    CTFrameDraw(frame, context);
}

@end
