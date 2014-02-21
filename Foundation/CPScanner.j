/*
 * CPScanner.j
 * Foundation
 *
 * Created by Emanuele Vulcano.
 * Copyright 2008, Emanuele Vulcano.
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

@import "CPCharacterSet.j"
@import "CPDictionary.j"
@import "CPString.j"

@implementation CPScanner : CPObject
{
    CPString        _string;
    CPDictionary    _locale;
    int             _scanLocation;
    BOOL            _caseSensitive;
    CPCharacterSet  _charactersToBeSkipped;
}

+ (id)scannerWithString:(CPString)aString
{
    return [[self alloc] initWithString:aString];
}

- (id)initWithString:(CPString)aString
{
    if (self = [super init])
    {
        _string = [aString copy];
        _scanLocation = 0;
        _charactersToBeSkipped = [CPCharacterSet whitespaceCharacterSet];
        _caseSensitive = NO;
    }

    return self;
}

- (id)copy
{
    var copy = [[CPScanner alloc] initWithString:[self string]];

    [copy setCharactersToBeSkipped:[self charactersToBeSkipped]];
    [copy setCaseSensitive:[self caseSensitive]];
    [copy setLocale:[self locale]];
    [copy setScanLocation:[self scanLocation]];

    return copy;
}

- (CPDictionary)locale
{
    return _locale;
}

- (void)setLocale:(CPDictionary)aLocale
{
    _locale = aLocale;
}

- (void)setCaseSensitive:(BOOL)flag
{
    _caseSensitive = flag;
}

- (BOOL)caseSensitive
{
    return _caseSensitive;
}

- (CPString)string
{
    return _string;
}

- (CPCharacterSet)charactersToBeSkipped
{
    return _charactersToBeSkipped;
}

- (void)setCharactersToBeSkipped:(CPCharacterSet)c
{
    _charactersToBeSkipped = c;
}

- (BOOL)isAtEnd
{
    return _scanLocation == _string.length;
}

- (int)scanLocation
{
    return _scanLocation;
}

- (void)setScanLocation:(int)aLocation
{
    if (aLocation > _string.length)
        aLocation = _string.length; // clamp to just after the last character
    else if (aLocation < 0)
        aLocation = 0; // clamp to the first

    _scanLocation = aLocation;
}

// Method body for all methods that return their value by reference.
- (BOOL)_performScanWithSelector:(SEL)s withObject:(id)arg into:(id)ref
{
    var ret = [self performSelector:s withObject:arg];

    if (ret == nil)
        return NO;

    if (ref != nil)
        ref(ret);

    return YES;
}

/* ================================ */
/* = Scanning with CPCharacterSet = */
/* ================================ */

- (BOOL)scanCharactersFromSet:(CPCharacterSet)scanSet intoString:(id)ref
{
    return [self _performScanWithSelector:@selector(scanCharactersFromSet:) withObject:scanSet into:ref];
}

- (CPString)scanCharactersFromSet:(CPCharacterSet)scanSet
{
    return [self _scanWithSet:scanSet breakFlag:NO];
}

- (BOOL)scanUpToCharactersFromSet:(CPCharacterSet)scanSet intoString:(id)ref
{
    return [self _performScanWithSelector:@selector(scanUpToCharactersFromSet:) withObject:scanSet into:ref];
}

- (CPString)scanUpToCharactersFromSet:(CPCharacterSet)scanSet
{
    return [self _scanWithSet:scanSet breakFlag:YES];
}

// If stop == YES, it will stop when it sees a character from
// the set (scanUpToCharactersFromSet:); if stop == NO, it will
// stop when it sees a character NOT from the set
// (scanCharactersFromSet:).
- (CPString)_scanWithSet:(CPCharacterSet)scanSet breakFlag:(BOOL)stop
{
    if ([self isAtEnd])
        return nil;

    var current = [self scanLocation],
        str = nil;

    while (current < _string.length)
    {
        var c = (_string.charAt(current));

        if ([scanSet characterIsMember:c] == stop)
            break;

        if (![_charactersToBeSkipped characterIsMember:c])
        {
            if (!str)
                str = '';
            str += c;
        }

        current++;
    }

    if (str)
        [self setScanLocation:current];

    return str;
}

/* ==================== */
/* = Scanning strings = */
/* ==================== */

- (void)_movePastCharactersToBeSkipped
{
    var current = [self scanLocation],
        string = [self string],
        toSkip = [self charactersToBeSkipped];

    while (current < string.length)
    {
        if (![toSkip characterIsMember:string.charAt(current)])
            break;

        current++;
    }

    [self setScanLocation:current];
}


- (BOOL)scanString:(CPString)aString intoString:(id)ref
{
    return [self _performScanWithSelector:@selector(scanString:) withObject:aString into:ref];
}

- (CPString)scanString:(CPString)s
{
    [self _movePastCharactersToBeSkipped];
    if ([self isAtEnd])
        return nil;

    var currentStr = [self string].substr([self scanLocation], s.length);
    if ((_caseSensitive && currentStr != s) || (!_caseSensitive && (currentStr.toLowerCase() != s.toLowerCase())))
    {
        return nil;
    }
    else
    {
        [self setScanLocation:[self scanLocation] + s.length];
        return s;
    }
}

- (BOOL)scanUpToString:(CPString)aString intoString:(id)ref
{
    return [self _performScanWithSelector:@selector(scanUpToString:) withObject:aString into:ref];
}

- (CPString)scanUpToString:(CPString)s
{
    var current = [self scanLocation],
        str = [self string],
        captured = nil;

    while (current < str.length)
    {
        var currentStr = str.substr(current, s.length);
        if (currentStr == s || (!_caseSensitive && currentStr.toLowerCase() == s.toLowerCase()))
            break;

        if (!captured)
            captured = '';
        captured += str.charAt(current);
        current++;
    }

    if (captured)
        [self setScanLocation:current];

    // evil private method use!
    // this method is defined in the category on CPString
    // in CPCharacterSet.j
    if ([self charactersToBeSkipped])
        captured = [captured _stringByTrimmingCharactersInSet:[self charactersToBeSkipped] options:_CPCharacterSetTrimAtBeginning];

    return captured;
}

/* ==================== */
/* = Scanning numbers = */
/* ==================== */

- (float)scanWithParseFunction:(Function)parseFunction
{
    [self _movePastCharactersToBeSkipped];
    var str = [self string],
        loc = [self scanLocation];

    if ([self isAtEnd])
        return 0;

    var s = str.substring(loc, str.length),
        f =  parseFunction(s);

    if (isNaN(f))
        return nil;

    loc += (""+f).length;
    var i = 0;
    while (!isNaN(parseFloat(str.substring(loc + i, str.length))))
        {i++;}

    [self setScanLocation:loc + i];
    return f;

}

- (float)scanFloat
{
    return [self scanWithParseFunction:parseFloat];
}

- (int)scanInt
{
    return [self scanWithParseFunction:parseInt];
}

- (BOOL)scanInt:(int)intoInt
{
    return [self _performScanWithSelector:@selector(scanInt) withObject:nil into:intoInt];
}

- (BOOL)scanFloat:(float)intoFloat
{
    return [self _performScanWithSelector:@selector(scanFloat) withObject:nil into:intoFloat];
}

- (BOOL)scanDouble:(float)intoDouble
{
    return [self scanFloat:intoDouble];
}

/* ========= */
/* = Debug = */
/* ========= */

- (CPString)description
{
    return [super description] + " {" + CPStringFromClass([self class]) + ", state = '" + ([self string].substr(0, _scanLocation) + "{{ SCAN LOCATION ->}}" + [self string].substr(_scanLocation)) + "'; }";
}

@end
