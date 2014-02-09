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
@import "CPControl.j"

var _sharedDefaultParagraphStyle,
    _defaultTabStopArray;

CPLeftTabStopType = 0;

/*
CPLeftTextAlignment = 0;
CPCenterTextAlignment = 1;
CPRightTextAlignment = 2;
*/

CPParagraphStyleAttributeName = @"CPParagraphStyleAttributeName";

@implementation CPTextTab : CPObject
{
    int    _type     @accessors(property=tabStopType);
    double _location @accessors(property=location);
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

- (id)initWithCoder:(id)aCoder
{
    self = [self init];

    if (self)
    {
        _type = [aCoder decodeIntForKey:"_type"];
        _location = [aCoder decodeDoubleForKey:"_location"];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [aCoder encodeInt:_type forKey:"_type"];
    [aCoder encodeDouble:_location forKey:"_location"];
}

@end

@implementation CPParagraphStyle : CPObject
{
    CPArray         _tabStops  @accessors(property = tabStops);
    CPTextAlignment _alignment @accessors(property = alignment);
    unsigned        _firstLineHeadIndent @accessors(property = firstLineHeadIndent);
    unsigned        _headIndent @accessors(property = headIndent);
    unsigned        _tailIndent @accessors(property = tailIndent);
    unsigned        _paragraphSpacing @accessors(property = paragraphSpacing);
    unsigned        _minimumLineHeight @accessors(property = minimumLineHeight);
    unsigned        _maximumLineHeight @accessors(property = maximumLineHeight);
    unsigned        _lineSpacing @accessors(property = lineSpacing);
}

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
- (void)addTabStop:(CPTextTab)aStop
{
    _tabStops.push(aStop);
}

- (void)_initWithDefaults
{
    _alignment = CPLeftTextAlignment;
    _tabStops = [[[self class] _defaultTabStops] copy];
}

- (id)init
{
    [self _initWithDefaults];

    return self;
}
- (id)copy
{
    var other = [[self class] alloc];
    return [other initWithParagraphStyle:self];
}
- initWithParagraphStyle:(CPParagraphStyle) other
{
    other._tabStops = [_tabStops copy];
    other._alignment = _alignment;
    other._firstLineHeadIndent = _firstLineHeadIndent;
    other._headIndent = _headIndent;
    other._tailIndent = _tailIndent;
    other._paragraphSpacing = _paragraphSpacing;
    other._minimumLineHeight = _minimumLineHeight;
    other._maximumLineHeight = _maximumLineHeight;
    other._lineSpacing = _lineSpacing;

    return self;
}

- (id)initWithCoder:(id)aCoder
{
    self = [self init];

    if (self)
    {
        _tabStops = [aCoder decodeObjectForKey:"_tabStops"];
        _alignment = [aCoder decodeIntForKey:"_alignment"];
        _firstLineHeadIndent = [aCoder decodeIntForKey:"_firstLineHeadIndent"];
        _headIndent = [aCoder decodeIntForKey:"_headIndent"];
        _tailIndent = [aCoder decodeIntForKey:"_tailIndent"];
        _paragraphSpacing = [aCoder decodeIntForKey:"_paragraphSpacing"];
        _minimumLineHeight = [aCoder decodeIntForKey:"_minimumLineHeight"];
        _maximumLineHeight = [aCoder decodeIntForKey:"_maximumLineHeight"];
        _lineSpacing = [aCoder decodeIntForKey:"_lineSpacing"];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [aCoder encodeInt:_alignment forKey:"_alignment"];
    [aCoder encodeObject:_tabStops forKey:"_tabStops"];
    [aCoder encodeInt:_firstLineHeadIndent forKey:"_firstLineHeadIndent"];
    [aCoder encodeInt:_headIndent forKey:"_headIndent"];
    [aCoder encodeInt:_tailIndent forKey:"_tailIndent"];
    [aCoder encodeInt:_paragraphSpacing forKey:"_paragraphSpacing"];
    [aCoder encodeInt:_minimumLineHeight forKey:"_minimumLineHeight"];
    [aCoder encodeInt:_maximumLineHeight forKey:"_maximumLineHeight"];
    [aCoder encodeInt:_lineSpacing forKey:"_lineSpacing"];
}

@end
