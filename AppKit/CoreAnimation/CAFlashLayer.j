/*
 * CAFlashLayer.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "CALayer.j"
@import "CPFlashMovie.j"


@implementation CAFlashLayer : CALayer
{
    CPFlashMovie    _flashMovie;
}

- (void)setFlashMovie:(CPFlashMovie)aFlashMovie
{
    if (_flashMovie == aFlashMovie)
        return;
        
    _flashMovie = aFlashMovie;
    
    _DOMElement.innerHTML = "<object width = \"100%\" height = \"100%\"><param name = \"movie\" value = \"" +
                            aFlashMovie._fileName + 
                            "\"></param><param name = \"wmode\" value = \"transparent\"></param><embed src = \"" + 
                            aFlashMovie._fileName + "\" type = \"application/x-shockwave-flash\" wmode = \"transparent\" width = \"100%\" height = \"100%\"></embed></object>";
}

- (CPFlashMovie)flashMovie
{
    return _flashMovie;
}

@end
