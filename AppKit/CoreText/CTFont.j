/*
 * CTFont.j
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

@import "CGAffineTransform.j"

@typedef CTFontRef

/*!
    @addtogroup coretext
    @{
*/

@implementation CTFont : CPObject
{
    CPString          _name;
    float             _size;
    CGAffineTransform _matrix;
}

- (id)initWithFontName:(CPString)name size:(float)size
{
    return [self initWithFontName: name size: size matrix: CGAffineTransformMakeIdentity()];
}

- (id)initWithFontName:(CPString)name size:(float)size matrix:(CGAffineTransform)matrix
{
    if (self = [super init]) {
        _name = [name copy];
        _size = size;
        _matrix = matrix ? CGAffineTransformMakeCopy(matrix) : CGAffineTransformMakeIdentity();
    }
    return self;
}

- (CPString)fontName
{
    return _name;
}

- (float)size
{
    return _size;
}

- (CGAffineTransform)matrix
{
    return CGAffineTransformMakeCopy(_matrix);
}

- (CPString)description
{
    return [CPString stringWithFormat: "CTFont name: %@, size: %f, matrix: %@", _name, _size, _matrix];
}

@end


function CTFontCreateWithFontName(name, size, matrix)
{
    return [[CTFont alloc] initWithFontName: name size: size matrix: matrix];
}

function CTFontCopyFullName(aFont)
{
    return [[aFont fontName] copy];
}

function CTFontGetMatrix(aFont)
{
    return [aFont matrix];
}

function CTFontGetSize(aFont)
{
    return [aFont size];
}

function CTFontDumpInfo(aFont)
{
    CPLog.debug([aFont description]);
}

/*!
    @}
*/
