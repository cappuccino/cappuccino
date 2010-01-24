/*
 * CPFlashMovie.j
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

@import <Foundation/CPObject.j>

/*! 
    @ingroup appkit
    @class CPFlashMovie

    CPFlashMovie is used to represent a Flash movie in the Cappuccino framework.
*/
@implementation CPFlashMovie : CPObject
{
    CPString _fileName;
}

/*!
    Creates a new Flash movie with the swf at \c aFileName.
    @param aFilename the swf to load
    @return the initialized CPFlashMovie
*/
+ (id)flashMovieWithFile:(CPString)aFileName
{
    return [[self alloc] initWithFile:aFileName];
}

/*!
    Initializes the Flash movie.
    @param aFilename the swf to load
    @return the initialized CPFlashMovie
*/
- (id)initWithFile:(CPString)aFileName
{
    self = [super init];
    
    if (self)
        _fileName = aFileName;
    
    return self;
}

- (CPString)fileName
{
    return _fileName;
}

@end

var CPFlashMovieFileNameKey = "CPFlashMovieFileNameKey";

@implementation CPFlashMovie (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    _fileName = [aCoder decodeObjectForKey:CPFlashMovieFileNameKey];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_fileName forKey:CPFlashMovieFileNameKey];
}

@end