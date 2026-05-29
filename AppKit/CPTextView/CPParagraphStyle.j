/*
 *  CPParagraphStyle.j
 *  AppKit
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
@import <Foundation/CPDictionary.j>

CPParagraphStyleAttributeName = @"CPParagraphStyleAttributeName";

// Standard Tab Interval (28pts is roughly 4 spaces in standard fonts)
var kDefaultTabInterval = 28.0;

// MARK: - CPTextTab Implementation

@implementation CPTextTab : CPObject
{
    CPTextAlignment     _alignment  @accessors(readonly, property=alignment);
    float               _location   @accessors(readonly, property=location);
    CPDictionary        _options    @accessors(readonly, property=options);
}

- (id)initWithTextAlignment:(CPTextAlignment)anAlignment location:(float)aLocation options:(CPDictionary)options
{
    if (self = [super init])
    {
        _alignment = anAlignment;
        _location = aLocation;
        _options = [options copy];
    }
    return self;
}

// Convenience initializer matching AppKit behavior
- (id)initWithType:(CPTabStopType)aType location:(float)aLocation
{
    // Map old TabStopType to TextAlignment for modern compatibility
    return [self initWithTextAlignment:aType location:aLocation options:nil];
}

// Added to resolve the unrecognized selector exception in the RTF producer
- (CPTabStopType)tabStopType
{
    return _alignment;
}

- (BOOL)isEqual:(id)other
{
    if (self === other) return YES;
    if (![other isKindOfClass:[CPTextTab class]]) return NO;

    return _location === [other location] &&
           _alignment === [other alignment] &&
           ((_options == nil && [other options] == nil) || [_options isEqualToDictionary:[other options]]);
}

- (id)copy
{
    return [[CPTextTab alloc] initWithTextAlignment:_alignment location:_location options:_options];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _alignment = [aCoder decodeIntForKey:@"CPTextTabAlignment"];
        _location = [aCoder decodeFloatForKey:@"CPTextTabLocation"];
        _options = [aCoder decodeObjectForKey:@"CPTextTabOptions"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeInt:_alignment forKey:@"CPTextTabAlignment"];
    [aCoder encodeFloat:_location forKey:@"CPTextTabLocation"];
    [aCoder encodeObject:_options forKey:@"CPTextTabOptions"];
}

@end


// MARK: - CPParagraphStyle Implementation

var _sharedDefaultParagraphStyle = nil;

@implementation CPParagraphStyle : CPObject
{
    float                   _lineSpacing            @accessors(readonly, property=lineSpacing);
    float                   _paragraphSpacing       @accessors(readonly, property=paragraphSpacing);
    CPTextAlignment         _alignment              @accessors(readonly, property=alignment);
    float                   _headIndent             @accessors(readonly, property=headIndent);
    float                   _tailIndent             @accessors(readonly, property=tailIndent);
    float                   _firstLineHeadIndent    @accessors(readonly, property=firstLineHeadIndent);
    float                   _minimumLineHeight      @accessors(readonly, property=minimumLineHeight);
    float                   _maximumLineHeight      @accessors(readonly, property=maximumLineHeight);
    CPLineBreakMode         _lineBreakMode          @accessors(readonly, property=lineBreakMode);
    CPWritingDirection      _baseWritingDirection   @accessors(readonly, property=baseWritingDirection);
    float                   _lineHeightMultiple     @accessors(readonly, property=lineHeightMultiple);
    float                   _paragraphSpacingBefore @accessors(readonly, property=paragraphSpacingBefore);
    float                   _defaultTabInterval     @accessors(readonly, property=defaultTabInterval);
    CPArray                 _tabStops               @accessors(readonly, property=tabStops);
}

+ (CPParagraphStyle)defaultParagraphStyle
{
    if (!_sharedDefaultParagraphStyle)
    {
        _sharedDefaultParagraphStyle = [[CPParagraphStyle alloc] init];
        // Ensure defaults are set on the shared instance internal vars
        // Since it's immutable, we rely on the init to set these.
    }
    return _sharedDefaultParagraphStyle;
}

+ (CPWritingDirection)defaultWritingDirectionForLanguage:(CPString)languageName
{
    // Simplified: Cappuccino usually assumes LTR unless specified otherwise.
    return CPWritingDirectionLeftToRight;
}

- (id)init
{
    if (self = [super init])
    {
        _lineSpacing = 0.0;
        _paragraphSpacing = 0.0;
        _alignment = CPLeftTextAlignment;
        _headIndent = 0.0;
        _tailIndent = 0.0;
        _firstLineHeadIndent = 0.0;
        _minimumLineHeight = 0.0;
        _maximumLineHeight = 0.0;
        _lineBreakMode = CPLineBreakByWordWrapping;
        _baseWritingDirection = CPWritingDirectionNatural;
        _lineHeightMultiple = 0.0;
        _paragraphSpacingBefore = 0.0;
        _defaultTabInterval = kDefaultTabInterval;
        
        // Generate default tab stops
        _tabStops = [];
        for (var i = 1; i <= 12; i++)
        {
            [_tabStops addObject:[[CPTextTab alloc] initWithType:CPLeftTextAlignment 
                                                        location:i * kDefaultTabInterval]];
        }
    }
    return self;
}

- (id)initWithParagraphStyle:(CPParagraphStyle)other
{
    if (self = [super init])
    {
        _lineSpacing            = [other lineSpacing];
        _paragraphSpacing       = [other paragraphSpacing];
        _alignment              = [other alignment];
        _headIndent             = [other headIndent];
        _tailIndent             = [other tailIndent];
        _firstLineHeadIndent    = [other firstLineHeadIndent];
        _minimumLineHeight      = [other minimumLineHeight];
        _maximumLineHeight      = [other maximumLineHeight];
        _lineBreakMode          = [other lineBreakMode];
        _baseWritingDirection   = [other baseWritingDirection];
        _lineHeightMultiple     = [other lineHeightMultiple];
        _paragraphSpacingBefore = [other paragraphSpacingBefore];
        _defaultTabInterval     = [other defaultTabInterval];
        _tabStops               = [[other tabStops] copy];
    }
    return self;
}

- (id)copy
{
    // Since this class is immutable, return self. 
    // Subclasses (Mutable) will override.
    if ([self class] === [CPParagraphStyle class])
        return self;
        
    return [[CPParagraphStyle alloc] initWithParagraphStyle:self];
}

- (id)mutableCopy
{
    return [[CPMutableParagraphStyle alloc] initWithParagraphStyle:self];
}

// MARK: - Equality

- (BOOL)isEqual:(id)other
{
    if (self === other) return YES;
    if (![other isKindOfClass:[CPParagraphStyle class]]) return NO;
    
    return _lineSpacing === [other lineSpacing] &&
           _paragraphSpacing === [other paragraphSpacing] &&
           _alignment === [other alignment] &&
           _headIndent === [other headIndent] &&
           _tailIndent === [other tailIndent] &&
           _firstLineHeadIndent === [other firstLineHeadIndent] &&
           _lineBreakMode === [other lineBreakMode] &&
           [_tabStops isEqualToArray:[other tabStops]];
}

@end


// MARK: - CPMutableParagraphStyle Implementation

@implementation CPMutableParagraphStyle : CPParagraphStyle
{
}

- (id)initWithParagraphStyle:(CPParagraphStyle)other
{
    if (self = [super initWithParagraphStyle:other])
    {
        // Ensure our tab stops array is mutable in the mutable subclass
        _tabStops = [[other tabStops] mutableCopy];
    }
    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _tabStops = [_tabStops mutableCopy];
    }
    return self;
}

- (void)setLineSpacing:(float)aLineSpacing
{
    _lineSpacing = aLineSpacing;
}

- (void)setParagraphSpacing:(float)aParagraphSpacing
{
    _paragraphSpacing = aParagraphSpacing;
}

- (void)setAlignment:(CPTextAlignment)anAlignment
{
    _alignment = anAlignment;
}

- (void)setHeadIndent:(float)aHeadIndent
{
    _headIndent = aHeadIndent;
}

- (void)setTailIndent:(float)aTailIndent
{
    _tailIndent = aTailIndent;
}

- (void)setFirstLineHeadIndent:(float)aFirstLineHeadIndent
{
    _firstLineHeadIndent = aFirstLineHeadIndent;
}

- (void)setMinimumLineHeight:(float)aMinimumLineHeight
{
    _minimumLineHeight = aMinimumLineHeight;
}

- (void)setMaximumLineHeight:(float)aMaximumLineHeight
{
    _maximumLineHeight = aMaximumLineHeight;
}

- (void)setLineBreakMode:(CPLineBreakMode)aLineBreakMode
{
    _lineBreakMode = aLineBreakMode;
}

- (void)setBaseWritingDirection:(CPWritingDirection)aBaseWritingDirection
{
    _baseWritingDirection = aBaseWritingDirection;
}

- (void)setLineHeightMultiple:(float)aLineHeightMultiple
{
    _lineHeightMultiple = aLineHeightMultiple;
}

- (void)setParagraphSpacingBefore:(float)aParagraphSpacingBefore
{
    _paragraphSpacingBefore = aParagraphSpacingBefore;
}

- (void)setDefaultTabInterval:(float)aDefaultTabInterval
{
    _defaultTabInterval = aDefaultTabInterval;
}

- (void)addTabStop:(CPTextTab)aTabStop
{
    [_tabStops addObject:aTabStop];
}

- (void)removeTabStop:(CPTextTab)aTabStop
{
    [_tabStops removeObject:aTabStop];
}

- (void)setTabStops:(CPArray)newTabStops
{
    if (_tabStops === newTabStops) return;
    _tabStops = [newTabStops mutableCopy];
}

- (id)copyWithZone:(CPZone)aZone
{
    // Return an immutable copy
    return [[CPParagraphStyle alloc] initWithParagraphStyle:self];
}

@end
