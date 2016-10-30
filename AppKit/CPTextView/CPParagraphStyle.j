/*
 *  CPParagraphStyle.j
 *  AppKit
 *
 * FIXME
 *  This is basically a stub.
 *  We need to store all the spacing informations as well as writing direction (among others)
 *
 *  Created by Daniel Boehringer on 11/01/2014
 *  Copyright Daniel Boehringer 2014.
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
@import <Foundation/CPArray.j>

@import "CPText.j"

CPLeftTabStopType = 0;

CPParagraphStyleAttributeName = @"CPParagraphStyleAttributeName";

var _sharedDefaultParagraphStyle,
    _defaultTabStopArray;

@implementation CPParagraphStyle : CPObject
{
    CPArray         _tabStops               @accessors(property=tabStops);
    CPTextAlignment _alignment              @accessors(property=alignment);
    unsigned        _firstLineHeadIndent    @accessors(property=firstLineHeadIndent);
    unsigned        _headIndent             @accessors(property=headIndent);
    unsigned        _tailIndent             @accessors(property=tailIndent);
    unsigned        _paragraphSpacing       @accessors(property=paragraphSpacing);
    unsigned        _minimumLineHeight      @accessors(property=minimumLineHeight);
    unsigned        _maximumLineHeight      @accessors(property=maximumLineHeight);
    unsigned        _lineSpacing            @accessors(property=lineSpacing);
}


#pragma mark -
#pragma mark Class methods

+ (CPParagraphStyle)defaultParagraphStyle
{
    if (!_sharedDefaultParagraphStyle)
       _sharedDefaultParagraphStyle = [self new];

    return _sharedDefaultParagraphStyle;
}

+ (CPArray)_defaultTabStops
{
    if (!_defaultTabStopArray)
    {
        var i;
        _defaultTabStopArray = [];

        // <!> FIXME: Define constants for these magic numbers: 13, 28
         for (i = 1; i < 16 ; i++)
         {
            _defaultTabStopArray.push([[CPTextTab alloc] initWithType:CPLeftTabStopType location:i * 28]);
         }
    }

    return _defaultTabStopArray;
}


#pragma mark -
#pragma mark Init methods

- (id)init
{
    [self _initWithDefaults];

    return self;
}

- (CPParagraphStyle)initWithParagraphStyle:(CPParagraphStyle)other
{
    self = [super init];

    _tabStops = [other._tabStops copy];
    _alignment = other._alignment;
    _firstLineHeadIndent = other._firstLineHeadIndent;
    _headIndent = other._headIndent;
    _tailIndent = other._tailIndent;
    _paragraphSpacing = other._paragraphSpacing;
    _minimumLineHeight = other._minimumLineHeight;
    _maximumLineHeight = other._maximumLineHeight;
    _lineSpacing = other._lineSpacing;

    return self;
}

- (void)_initWithDefaults
{
    _alignment = CPLeftTextAlignment;
    _tabStops = [[[self class] _defaultTabStops] copy];
}

- (void)addTabStop:(CPTextTab)aStop
{
    _tabStops.push(aStop);
}

- (id)copy
{
    var other = [[self class] alloc];

    return [other initWithParagraphStyle:self];
}

@end


var CPParagraphStyleTabStopsKey = @"CPParagraphStyleTabStopsKey",
    CPParagraphStyleAlignmentKey = @"CPParagraphStyleAlignmentKey",
    CPParagraphStyleFirstLineHeadIndentKey = @"CPParagraphStyleFirstLineHeadIndentKey",
    CPParagraphStyleHeadIndentKey = @"CPParagraphStyleHeadIndentKey",
    CPParagraphStyleTailIndentKey = @"CPParagraphStyleTailIndentKey",
    CPParagraphStyleParagraphSpacingKey = @"CPParagraphStyleParagraphSpacingKey",
    CPParagraphStyleMinimumLineHeightKey = @"CPParagraphStyleMinimumLineHeightKey",
    CPParagraphStyleMaximumLineHeightKey = @"CPParagraphStyleMaximumLineHeightKey",
    CPParagraphStyleLineSpacingKey = @"CPParagraphStyleLineSpacingKey";

@implementation CPParagraphStyle (CPCoding)

- (id)initWithCoder:(id)aCoder
{
    self = [self init];

    if (self)
    {
        _tabStops = [aCoder decodeObjectForKey:"CPParagraphStyleTabStopsKey"];
        _alignment = [aCoder decodeIntForKey:"CPParagraphStyleAlignmentKey"];
        _firstLineHeadIndent = [aCoder decodeIntForKey:"CPParagraphStyleFirstLineHeadIndentKey"];
        _headIndent = [aCoder decodeIntForKey:"CPParagraphStyleHeadIndentKey"];
        _tailIndent = [aCoder decodeIntForKey:"CPParagraphStyleTailIndentKey"];
        _paragraphSpacing = [aCoder decodeIntForKey:"CPParagraphStyleParagraphSpacingKey"];
        _minimumLineHeight = [aCoder decodeIntForKey:"CPParagraphStyleMinimumLineHeightKey"];
        _maximumLineHeight = [aCoder decodeIntForKey:"CPParagraphStyleMaximumLineHeightKey"];
        _lineSpacing = [aCoder decodeIntForKey:"CPParagraphStyleLineSpacingKey"];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [aCoder encodeInt:_alignment forKey:"CPParagraphStyleAlignmentKey"];
    [aCoder encodeObject:_tabStops forKey:"CPParagraphStyleTabStopsKey"];
    [aCoder encodeInt:_firstLineHeadIndent forKey:"CPParagraphStyleFirstLineHeadIndentKey"];
    [aCoder encodeInt:_headIndent forKey:"CPParagraphStyleHeadIndentKey"];
    [aCoder encodeInt:_tailIndent forKey:"CPParagraphStyleTailIndentKey"];
    [aCoder encodeInt:_paragraphSpacing forKey:"CPParagraphStyleParagraphSpacingKey"];
    [aCoder encodeInt:_minimumLineHeight forKey:"CPParagraphStyleMinimumLineHeightKey"];
    [aCoder encodeInt:_maximumLineHeight forKey:"CPParagraphStyleMaximumLineHeightKey"];
    [aCoder encodeInt:_lineSpacing forKey:"CPParagraphStyleLineSpacingKey"];
}


@end


@implementation CPTextTab : CPObject
{
    int    _type     @accessors(property = tabStopType);
    double _location @accessors(property = location);
}

- (id)initWithType:(CPTabStopType) aType location:(double) aLocation
{
    if ([self = [super init]])
    {
        _type = aType;
        _location = aLocation;
    }

    return self;
}

@end


var CPTextTabTypeKey = @"CPTextTabTypeKey",
    CPTextTabLocationKey = @"CPTextTabLocationKey";

@implementation CPTextTab (CPCoding)

- (id)initWithCoder:(id)aCoder
{
    self = [self init];

    if (self)
    {
        _type = [aCoder decodeIntForKey:"CPTextTabTypeKey"];
        _location = [aCoder decodeDoubleForKey:"CPTextTabLocationKey"];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [aCoder encodeInt:_type forKey:"CPTextTabTypeKey"];
    [aCoder encodeDouble:_location forKey:"CPTextTabLocationKey"];
}

@end
