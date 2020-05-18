/*
 * CTRun.j
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

@import <Foundation/Foundation.j>

@import "CGContext.j"

@typedef CTRun

/*!
    @addtogroup coretext
    @{
*/


function CTRunCreate(text, positions, attributes)
{
    return {text: text, positions: positions, attributes: attributes};
}

function CTRunGetCharCount(aRun)
{
    return aRun.text.length();
}

function CTRunGetAttributes(aRun)
{
    return aRun.attributes;
}

function CTRunGetPositions(aRun)
{
    return aRun.positions;
}

function CTRunGetTypographicBounds(aRun)
{
    return 0;
}

function CTRunGetImageBounds(aRun)
{
    return 0;
}

function CTApplyAttributes(aContext, attributes)
{
//    CPLog.trace("CTApplyAttributes(<>, %@)", attributes);
    
    if (attributes)
    {
        // Set the attributes first!
        [attributes enumerateKeysAndObjectsUsingBlock: function(key, value, stop)
        {
            if (key == kCTForegroundColorAttributeName)
            {
                CGContextSetFillColor(aContext, value);
            }
            if (key == kCTFontAttributeName)
            {
                var name = CTFontCopyFullName(value);
                CGContextSetFont(aContext, CGFontCreateWithFontName(name));
                CGContextSetFontSize(aContext, CTFontGetSize(value));
            }
        }];
    }
    
}


/*!
    Draws the run.
    @param aRun the run to draw
    @param aContext the context within which to draw
    @param aRange the subrange to draw - ignored
    @return void
*/

function CTRunDraw(aRun, aContext, aRange)
{
    // aRange is ignored!
    CGContextSaveGState(aContext);
    CTApplyAttributes(aContext, aRun.attributes);
    CGContextShowTextAtPositions(aContext, aRun.text, aRun.positions, aRun.positions.length);
    CGContextRestoreGState(aContext);
}

/*!
    @}
*/
