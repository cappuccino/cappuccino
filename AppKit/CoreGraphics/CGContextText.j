/*
 * CGContextText.j
 * CoreText
 *
 * Created by Nicholas Small.
 * Copyright 2011, 280 North, Inc.
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

kCGTextFill = 0;
kCGTextStroke = 1;
kCGTextFillStroke = 2;
kCGTextInvisible = 3;

function CGContextGetTextMatrix(/* CGContext */ aContext)
{
    return aContext._textMatrix;
}

function CGContextSetTextMatrix(/* CGContext */ aContext, /* CGAffineTransform */ aTransform)
{
    aContext._textMatrix = aTransform;
}

function CGContextGetTextPosition(/* CGContext */ aContext)
{
    return aContext._textPosition || _CGPointMakeZero();
}

function CGContextSetTextPosition(/* CGContext */ aContext, /* float */ x, /* float */ y)
{
    aContext._textPosition = CGPointMake(x, y);
}

function CGContextGetFont(/* CGContext */ aContext)
{
    return aContext._CPFont;
}

function CGContextSelectFont(/* CGContext */ aContext, /* CPFont */ aFont)
{
    aContext.font = [aFont cssString];
    aContext._CPFont = aFont;
}

function CGContextSetTextDrawingMode(/* CGContext */ aContext, /* CGTextDrawingMode */ aMode)
{
    aContext._textDrawingMode = aMode;
}

function CGContextShowText(/* CGContext */ aContext, /* CPString */ aString)
{
    CGContextShowTextAtPoint(aContext, aContext._textPosition.x, aContext._textPosition.y, aString);
}

function CGContextShowTextAtPoint(/* CGContext */ aContext, /* float */ x, /* float */ y, /* CPString */ aString)
{
    aContext.textBaseline = @"middle";
    aContext.textAlign = @"left";
    
    var mode = aContext._textDrawingMode;
    if (!mode && mode !== 0)
        mode = kCGTextFill;
    
    var width = aContext.measureText(aString).width;
    
    if (mode === kCGTextFill || mode === kCGTextFillStroke)
        aContext.fillText(aString, x, y);
    if (mode === kCGTextStroke || mode === kCGTextFillStroke)
        aContext.strokeText(aString, x, y);
    
    aContext._textPosition = CGPointMake(x + width, y);
}

// FIXME: these are hacks that override the default behavior.

function CGContextSetFillColor(/* CGContext */ aContext, /* CPColor */ aColor)
{
    aContext.fillStyle = [aColor cssString];
    aContext._CPColor = aColor;
}

function CGContextGetFillColor(/* CGContext */ aContext)
{
    return aContext._CPColor;
}
