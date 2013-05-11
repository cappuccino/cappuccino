/*
 * CPDateFormatter.j
 * Foundation
 *
 * Created by Alexander Ljungberg.
 * Copyright 2012, SlevenBits Ltd.
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

@import "CPArray.j"
@import "CPDate.j"
@import "CPString.j"
@import "CPFormatter.j"
@import "CPTimeZone.j"
@import "CPLocale.j"

@class CPNull

@global CPLocaleLanguageCode
@global CPLocaleCountryCode

CPDateFormatterNoStyle     = 0;
CPDateFormatterShortStyle  = 1;
CPDateFormatterMediumStyle = 2;
CPDateFormatterLongStyle   = 3;
CPDateFormatterFullStyle   = 4;

CPDateFormatterBehaviorDefault = 0;
CPDateFormatterBehavior10_0    = 1000;
CPDateFormatterBehavior10_4    = 1040;

var defaultDateFormatterBehavior = CPDateFormatterBehavior10_4,
    relativeDateFormating,
    patternStringTokens;

/*!
    @ingroup foundation
    @class CPDateFormatter

    CPDateFormatter takes a CPDate value and formats it as text for
    display. It also supports the converse, taking text and interpreting it as a
    CPDate by configurable formatting rules.
*/
@implementation CPDateFormatter : CPFormatter
{
    BOOL                    _allowNaturalLanguage               @accessors(property=allowNaturalLanguage, readonly);
    BOOL                    _doesRelativeDateFormatting         @accessors(property=doesRelativeDateFormatting);
    CPDate                  _defaultDate                        @accessors(property=defaultDate);
    CPDate                  _twoDigitStartDate                  @accessors(property=twoDigitStartDate);
    CPDateFormatterBehavior _formatterBehavior                  @accessors(property=formatterBehavior);
    CPDateFormatterStyle    _dateStyle                          @accessors(property=dateStyle);
    CPDateFormatterStyle    _timeStyle                          @accessors(property=timeStyle);
    CPLocale                _locale                             @accessors(property=locale);
    CPString                _AMSymbol                           @accessors(property=AMSymbol);
    CPString                _dateFormat                         @accessors(property=dateFormat);
    CPString                _PMSymbol                           @accessors(property=PMSymbol);
    CPTimeZone              _timeZone                           @accessors(property=timeZone);

    CPDictionary            _symbols;
}


+ (void)initialize
{
    if (self !== [CPDateFormatter class])
        return;

    relativeDateFormating = @{
      @"fr" : [@"demain", 1440, @"apr" + String.fromCharCode(233) + @"s-demain", 2880, @"apr" + String.fromCharCode(233) + @"s-apr" + String.fromCharCode(233) + @"s-demain", 4320, @"hier", -1440, @"avant-hier", -2880, @"avant-avant-hier", -4320],
      @"en" : [@"tomorrow", 1440, @"yesterday", -1440],
      @"de" : [],
      @"es" : []
    };

    patternStringTokens = [@"QQQ", @"qqq", @"QQQQ", @"qqqq", @"MMM", @"MMMM", @"LLL", @"LLLL", @"E", @"EE", @"EEE", @"eee", @"eeee", @"eeeee", @"a", @"z", @"zz", @"zzz", @"zzzz", @"Z", @"ZZ", @"ZZZ", @"ZZZZ", @"ZZZZZ", @"v", @"vv", @"vvv", @"vvvv", @"V", @"VV", @"VVV", @"VVVV"];
}

/*! Return a string representation of the given date, dateStyle and timeStyle
    @param date the given date
    @param dateStyle the dateStyle
    @param timeStyle the timeStyle
    @return a CPString reprensenting the given date
*/
+ (CPString)localizedStringFromDate:(CPDate)date dateStyle:(CPDateFormatterStyle)dateStyle timeStyle:(CPDateFormatterStyle)timeStyle
{
    var formatter = [[CPDateFormatter alloc] init];

    [formatter setFormatterBehavior:CPDateFormatterBehavior10_4];
    [formatter setDateStyle:dateStyle];
    [formatter setTimeStyle:timeStyle];

    return [formatter stringForObjectValue:date];
}

/*! Not yet implemented
    Return a string representation of the given template, opts and locale
    @param template the template
    @param opts, pass 0
    @param locale the locale
    @return a CPString representing the givent template
*/
+ (CPString)dateFormatFromTemplate:(CPString)template options:(CPUInteger)opts locale:(CPLocale)locale
{
    // TODO : check every template from cocoa and return a good format (have fun ^^)
}

/*! Return the defaultFormatterBehavior
    @return a CPDateFormatterBehavior
*/
+ (CPDateFormatterBehavior)defaultFormatterBehavior
{
    return defaultDateFormatterBehavior;
}

/*! Set the defaultFormatterBehavior
    @param behavior
*/
+ (void)setDefaultFormatterBehavior:(CPDateFormatterBehavior)behavior
{
    defaultDateFormatterBehavior = behavior;
}

/*! Init a dateFormatter
    @return a new CPDateFormatter
*/
- (id)init
{
    if (self = [super init])
    {
        _dateStyle = nil;
        _timeStyle = nil;

        [self _init];
    }

    return self;
}

/*! Init a dateFormatter with a format and the naturalLanguage
    @param format the format
    @param flag flag representation of allowNaturalLanguage
    @return a new CPDateFormatter
*/
- (id)initWithDateFormat:(CPString)format allowNaturalLanguage:(BOOL)flag
{
    if (self = [self init])
    {
        _dateFormat = format;
        _allowNaturalLanguage = flag;
    }

    return self
}

/*! Private init
*/
- (void)_init
{
    var AMSymbol = [CPString stringWithFormat:@"%s", @"AM"],
        PMSymbol = [CPString stringWithFormat:@"%s", @"PM"],
        weekdaySymbols = [CPArray arrayWithObjects:@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"],
        shortWeekdaySymbols = [CPArray arrayWithObjects:@"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat"],
        veryShortWeekdaySymbols = [CPArray arrayWithObjects:@"S", @"M", @"T", @"W", @"T", @"F", @"S"],
        standaloneWeekdaySymbols = [CPArray arrayWithObjects:@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"],
        shortStandaloneWeekdaySymbols = [CPArray arrayWithObjects:@"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat"],
        veryShortStandaloneWeekdaySymbols = [CPArray arrayWithObjects:@"S", @"M", @"T", @"W", @"T", @"F", @"S"],
        monthSymbols = [CPArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"],
        shortMonthSymbols = [CPArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"],
        veryShortMonthSymbols = [CPArray arrayWithObjects:@"J", @"F", @"M", @"A", @"M", @"J", @"J", @"A", @"S", @"O", @"N", @"D"],
        standaloneMonthSymbols = [CPArray arrayWithObjects:@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"],
        shortStandaloneMonthSymbols = [CPArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"],
        veryShortStandaloneMonthSymbols = [CPArray arrayWithObjects:@"J", @"F", @"M", @"A", @"M", @"J", @"J", @"A", @"S", @"O", @"N", @"D"],
        quarterSymbols = [CPArray arrayWithObjects:@"1st quarter", @"2nd quarter", @"3rd quarter", @"4th quarter"],
        shortQuarterSymbols = [CPArray arrayWithObjects:@"Q1", @"Q2", @"Q3", @"Q4"],
        standaloneQuarterSymbols = [CPArray arrayWithObjects:@"1st quarter", @"2nd quarter", @"3rd quarter", @"4th quarter"],
        shortStandaloneQuarterSymbols = [CPArray arrayWithObjects:@"Q1", @"Q2", @"Q3", @"Q4"];

    _symbols = @{
        @"en" : @{
            @"AMSymbol" : AMSymbol,
            @"PMSymbol" : PMSymbol,
            @"weekdaySymbols" : weekdaySymbols,
            @"shortWeekdaySymbols" : shortWeekdaySymbols,
            @"veryShortWeekdaySymbols" : veryShortWeekdaySymbols,
            @"standaloneWeekdaySymbols" : standaloneWeekdaySymbols,
            @"shortStandaloneWeekdaySymbols" : shortStandaloneWeekdaySymbols,
            @"veryShortStandaloneWeekdaySymbols" : veryShortStandaloneWeekdaySymbols,
            @"monthSymbols" : monthSymbols,
            @"shortMonthSymbols" : shortMonthSymbols,
            @"veryShortMonthSymbols" : veryShortMonthSymbols,
            @"standaloneMonthSymbols" : standaloneMonthSymbols,
            @"shortStandaloneMonthSymbols" : shortStandaloneMonthSymbols,
            @"veryShortStandaloneMonthSymbols" : veryShortStandaloneMonthSymbols,
            @"quarterSymbols" : quarterSymbols,
            @"shortQuarterSymbols" : shortQuarterSymbols,
            @"standaloneQuarterSymbols" : standaloneQuarterSymbols,
            @"shortStandaloneQuarterSymbols" : shortStandaloneQuarterSymbols
        },
        @"fr" : @{},
        @"es" : @{},
        @"de" : @{}
    };

    _timeZone = [CPTimeZone systemTimeZone];
    _twoDigitStartDate = [[CPDate alloc] initWithString:@"1950-01-01 00:00:00 +0000"];
    _locale = [CPLocale currentLocale];
}


#pragma mark -
#pragma mark Setter Getter

/*! Return AMSymbol
*/
- (CPString)AMSymbol
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"AMSymbol"];
}

/*! Set the AMSymbol
*/
- (void)setAMSymbol:(CPString)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"AMSymbol"];
}

/*! Return a PMSymbol
*/
- (CPString)PMSymbol
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"PMSymbol"];
}

/*! Set the PMSymbol
*/
- (void)setPMSymbol:(CPString)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"PMSymbol"];
}

/*! Return the weekdaySymbols
*/
- (CPArray)weekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"weekdaySymbols"];
}

/*! Set the weekdaySymbols
*/
- (void)setWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"weekdaySymbols"];
}

/*! Return a shortWeekdaySymbols
*/
- (CPArray)shortWeekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortWeekdaySymbols"];
}

/*! Set the shortWeekdaySymbols
*/
- (void)setShortWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortWeekdaySymbols"];
}

/*! Return veryShortWeekdaySymbols
*/
- (CPArray)veryShortWeekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"veryShortWeekdaySymbols"];
}

/*! Set the veryShortWeekdaySymbols
*/
- (void)setVeryShortWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"veryShortWeekdaySymbols"];
}

/*! Return the standaloneWeekdaySymbols
*/
- (CPArray)standaloneWeekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"standaloneWeekdaySymbols"];
}

/*! Set the standaloneWeekdaySymbols
*/
- (void)setStandaloneWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"standaloneWeekdaySymbols"];
}

/*! Return the shortStandaloneWeekdaySymbols
*/
- (CPArray)shortStandaloneWeekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortStandaloneWeekdaySymbols"];
}

/*! Set the shortStandaloneWeekdaySymbols
*/
- (void)setShortStandaloneWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortStandaloneWeekdaySymbols"];
}

/*! Return the veryShortStandaloneWeekdaySymbols
*/
- (CPArray)veryShortStandaloneWeekdaySymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"veryShortStandaloneWeekdaySymbols"];
}

/*! Set the veryShortStandaloneWeekdaySymbols
*/
- (void)setVeryShortStandaloneWeekdaySymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"veryShortStandaloneWeekdaySymbols"];
}

/*! Return the monthSymbols
*/
- (CPArray)monthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"monthSymbols"];
}

/*! Set the monthSymbols
*/
- (void)setMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"monthSymbols"];
}

/*! Return a shortMonthSymbols
*/
- (CPArray)shortMonthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortMonthSymbols"];
}

/*! Set the shortMonthSymbols
*/
- (void)setShortMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortMonthSymbols"];
}

/*! Return veryShortMonthSymbols
*/
- (CPArray)veryShortMonthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"veryShortMonthSymbols"];
}

/*! Set the veryShortMonthSymbols
*/
- (void)setVeryShortMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"veryShortMonthSymbols"];
}

/*! Return standaloneMonthSymbols
*/
- (CPArray)standaloneMonthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"standaloneMonthSymbols"];
}

/*! Set the standaloneMonthSymbols
*/
- (void)setStandaloneMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"standaloneMonthSymbols"];
}

/*! Return the shortStandaloneMonthSymbols
*/
- (CPArray)shortStandaloneMonthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortStandaloneMonthSymbols"];
}

/*! Set the shortStandaloneMonthSymbols
*/
- (void)setShortStandaloneMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortStandaloneMonthSymbols"];
}

/*! Return the veryShortStandaloneMonthSymbols
*/
- (CPArray)veryShortStandaloneMonthSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"veryShortStandaloneMonthSymbols"];
}

/*! Set the veryShortStandaloneMonthSymbols
*/
- (void)setVeryShortStandaloneMonthSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"veryShortStandaloneMonthSymbols"];
}

/*! Return the quarterSymbols
*/
- (CPArray)quarterSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"quarterSymbols"];
}

/*! Set the quarterSymbols
*/
- (void)setQuarterSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"quarterSymbols"];
}

/*! Return the shortQuarterSymbols
*/
- (CPArray)shortQuarterSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortQuarterSymbols"];
}

/*! Set the shortQuarterSymbols
*/
- (void)setShortQuarterSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortQuarterSymbols"];
}

/*! Return the standaloneQuarterSymbols
*/
- (CPArray)standaloneQuarterSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"standaloneQuarterSymbols"];
}

/*! Set the standaloneQuarterSymbols
*/
- (void)setStandaloneQuarterSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"standaloneQuarterSymbols"];
}

/*! Return the shortStandaloneQuarterSymbols
*/
- (CPArray)shortStandaloneQuarterSymbols
{
    return [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] valueForKey:@"shortStandaloneQuarterSymbols"];
}

/*! Set the shortStandaloneQuarterSymbols
*/
- (void)setShortStandaloneQuarterSymbols:(CPArray)aValue
{
    [[_symbols valueForKey:[_locale objectForKey:CPLocaleLanguageCode]] setValue:aValue forKey:@"shortStandaloneQuarterSymbols"];
}


#pragma mark -
#pragma mark StringFromDate methods

/*! Return a string representation of a given date.
    This method returns (if possible) a representation of the given date with the dateFormat of the CPDateFormatter, otherwise it takes the dateStyle and timeStyle
    @param aDate the given date
    @return CPString the string representation
*/
- (CPString)stringFromDate:(CPDate)aDate
{
    var format,
        relativeWord,
        result;

    if (!aDate)
        return;

    aDate = [aDate copy];
    [aDate _dateWithTimeZone:_timeZone];

    if (_dateFormat)
        return [self _stringFromDate:aDate format:_dateFormat];

    switch (_dateStyle)
    {
        case CPDateFormatterNoStyle:
            format = @"";
            break;

        case CPDateFormatterShortStyle:
            if ([self _isAmericanFormat])
                format = @"M/d/yy";
            else
                format = @"dd/MM/yy";

            break;

        case CPDateFormatterMediumStyle:
            if ([self _isAmericanFormat])
                format = @"MMM d, Y";
            else
                format = @"d MMM Y";

            break;

        case CPDateFormatterLongStyle:
            if ([self _isAmericanFormat])
                format = @"MMMM d, Y";
            else
                format = @"d MMMM Y";

            break;

        case CPDateFormatterFullStyle:
            if ([self _isAmericanFormat])
                format = @"EEEE, MMMM d, Y";
            else
                format = @"EEEE d MMMM Y";

            break;

        default:
            format = @"";
    }


    if ([self doesRelativeDateFormatting])
    {
        var language = [_locale objectForKey:CPLocaleLanguageCode],
            relativeWords = [relativeDateFormating valueForKey:language];

        for (var i = 1; i < [relativeWords count]; i = i + 2)
        {
            var date = [CPDate date];
            [date _dateWithTimeZone:_timeZone];

            date.setHours(aDate.getHours());
            date.setMinutes(aDate.getMinutes());
            date.setSeconds(aDate.getSeconds());

            date.setMinutes([relativeWords objectAtIndex:i]);

            if (date.getDate() == aDate.getDate() && date.getMonth() && aDate.getMonth() && date.getFullYear() == aDate.getFullYear())
            {
                relativeWord = [relativeWords objectAtIndex:(i - 1)];
                format = @"";
                break;
            }
        }
    }

    if ((relativeWord || format.length) && _timeStyle != CPDateFormatterNoStyle)
        format += @" ";

    switch (_timeStyle)
    {
        case CPDateFormatterNoStyle:
            format += @"";
            break;

        case CPDateFormatterShortStyle:
            if ([self _isEnglishFormat])
                format += @"h:mm a";
            else
                format += @"H:mm";

            break;

        case CPDateFormatterMediumStyle:
            if ([self _isEnglishFormat])
                format += @"h:mm:ss a";
            else
                format += @"H:mm:ss"

            break;

        case CPDateFormatterLongStyle:
            if ([self _isEnglishFormat])
                format += @"h:mm:ss a z";
            else
                format += @"H:mm:ss z";

            break;

        case CPDateFormatterFullStyle:
            if ([self _isEnglishFormat])
                format += @"h:mm:ss a zzzz";
            else
                format += @"h:mm:ss zzzz";

            break;

        default:
            format += @"";
    }

    result = [self _stringFromDate:aDate format:format];

    if (relativeWord)
        result = relativeWord + result;

    return result;
}

/*! Return a string representation of the given objectValue.
    This method call the method stringFromDate if possible, otherwise it returns the description of the object
    @param anObject
    @return a string
*/
- (CPString)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[CPDate class]])
        return [self stringFromDate:anObject];
    else
        return nil;
}

/*! Return a string
    This method call the method stringForObjectValue
    @param anObject
    @return a string
*/
- (CPString)editingStringForObjectValue:(id)anObject
{
    return [self stringForObjectValue:anObject];
}

/*! Return a string representation of the given date and format
    @patam aDate
    @param aFormat
    @return a string
*/
- (CPString)_stringFromDate:(CPDate)aDate format:(CPString)aFormat
{
    var length = [aFormat length],
        currentToken = [CPString new],
        isTextToken = NO,
        result = [CPString new];

    for (var i = 0; i < length; i++)
    {
        var character = [aFormat characterAtIndex:i];

        if (isTextToken)
        {
            if ([character isEqualToString:@"'"])
            {
                isTextToken = NO;
                result += currentToken;
                currentToken = [CPString new];
            }
            else
            {
                currentToken += character;
            }

            continue;
        }

        if ([character isEqualToString:@"'"])
        {
            if (!isTextToken)
            {
                isTextToken = YES;
                result += currentToken;
                currentToken = [CPString new];
            }

            continue;
        }

        if ([character isEqualToString:@","] || [character isEqualToString:@":"] || [character isEqualToString:@"/"] || [character isEqualToString:@"-"] || [character isEqualToString:@" "])
        {
            result += [self _stringFromToken:currentToken date:aDate];
            result += character;
            currentToken = [CPString new];
        }
        else
        {
            if ([currentToken length] && ![[currentToken characterAtIndex:0] isEqualToString:character])
            {
                result += [self _stringFromToken:currentToken date:aDate];
                currentToken = [CPString new];
            }

            currentToken += character;

            if (i == (length - 1))
                result += [self _stringFromToken:currentToken date:aDate];
        }
    }

    return result;
}

/*! Return a string representation of the given token and date
    @param aToken
    @param aDate
    @return a string
*/
- (CPString)_stringFromToken:(CPString)aToken date:(CPDate)aDate
{
    if (![aToken length])
        return aToken;

    var character = [aToken characterAtIndex:0],
        length = [aToken length],
        timeZone = _timeZone;

    switch (character)
    {
        case @"G":
            // TODO
            CPLog.warn(@"Token not yet implemented " + aToken);
            return [CPString new];

        case @"y":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getFullYear()] length];

            return [self _stringValueForValue:aDate.getFullYear() length:(length == 2)?length:currentLength];

        case @"Y":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getFullYear()] length];

            return [self _stringValueForValue:aDate.getFullYear() length:(length == 2)?length:currentLength];

        case @"u":
            // TODO
            CPLog.warn(@"Token not yet implemented " + aToken);
            return [CPString new];

        case @"U":
            // TODO
            CPLog.warn(@"Token not yet implemented " + aToken);
            return [CPString new];

        case @"Q":
            var quarter = 1;

            if (aDate.getMonth() < 6 && aDate.getMonth() > 2)
                quarter = 2;

            if (aDate.getMonth() > 5 && aDate.getMonth() < 9)
                quarter = 3;

            if (aDate.getMonth() >= 9)
                quarter = 4;

            if (length <= 2)
                return [self _stringValueForValue:quarter length:MIN(2,length)];

            if (length == 3)
                return [[self shortQuarterSymbols] objectAtIndex:(quarter - 1)];

            if (length >= 4)
                return [[self quarterSymbols] objectAtIndex:(quarter - 1)];

        case @"q":
            var quarter = 1;

            if (aDate.getMonth() < 6 && aDate.getMonth() > 2)
                quarter = 2;

            if (aDate.getMonth() > 5 && aDate.getMonth() < 9)
                quarter = 3;

            if (aDate.getMonth() >= 9)
                quarter = 4;

            if (length <= 2)
                return [self _stringValueForValue:quarter length:MIN(2,length)];

            if (length == 3)
                return [[self shortStandaloneQuarterSymbols] objectAtIndex:(quarter - 1)];

            if (length >= 4)
                return [[self standaloneQuarterSymbols] objectAtIndex:(quarter - 1)];

        case @"M":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getMonth() + 1] length];

            if (length <= 2)
                return [self _stringValueForValue:(aDate.getMonth() + 1) length:MAX(currentLength,length)];

            if (length == 3)
                return [[self shortMonthSymbols] objectAtIndex:aDate.getMonth()];

            if (length == 4)
                return [[self monthSymbols] objectAtIndex:aDate.getMonth()];

            if (length >= 5)
                return [[self veryShortMonthSymbols] objectAtIndex:aDate.getMonth()];

        case @"L":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getMonth() + 1] length];

            if (length <= 2)
                return [self _stringValueForValue:(aDate.getMonth() + 1) length:MAX(currentLength,length)];

            if (length == 3)
                return [[self shortStandaloneMonthSymbols] objectAtIndex:aDate.getMonth()];

            if (length == 4)
                return [[self standaloneMonthSymbols] objectAtIndex:aDate.getMonth()];

            if (length >= 5)
                return [[self veryShortStandaloneMonthSymbols] objectAtIndex:aDate.getMonth()];

        case @"I":
            // Deprecated
            CPLog.warn(@"Depreacted - Token not yet implemented " + aToken);
            return [CPString new];

        case @"w":
            var d = [aDate copy];

            d.setHours(0, 0, 0);
            d.setDate(d.getDate() + 4 - (d.getDay() || 7));

            var yearStart = new Date(d.getFullYear(), 0, 1),
                weekOfYear = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);

            return [self _stringValueForValue:(weekOfYear + 1) length:MAX(2, length)];

        case @"W":
            var firstDay = new Date(aDate.getFullYear(), aDate.getMonth(), 1).getDay(),
                weekOfMonth =  Math.ceil((aDate.getDate() + firstDay) / 7);

            return [self _stringValueForValue:weekOfMonth length:1];

        case @"d":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getDate()] length];

            return [self _stringValueForValue:aDate.getDate() length:MAX(length, currentLength)];

        case @"D":
            var oneJan = new Date(aDate.getFullYear(), 0, 1),
                dayOfYear = Math.ceil((aDate - oneJan) / 86400000),
                currentLength = [[CPString stringWithFormat:@"%i", dayOfYear] length];

            return [self _stringValueForValue:dayOfYear length:MAX(currentLength, MIN(3, length))];

        case @"F":
            var dayOfWeek = 1,
                day = aDate.getDate();

            if (day > 7 && day < 15)
                dayOfWeek = 2;

            if (day > 14 && day < 22)
                dayOfWeek = 3;

            if (day > 21 && day < 29)
                dayOfWeek = 4;

            if (day > 28)
                dayOfWeek = 5;

            return [self _stringValueForValue:dayOfWeek length:1];

        case @"g":
            CPLog.warn(@"Token not yet implemented " + aToken);
            return [CPString new];

        case @"E":
            var day = aDate.getDay();

            if (length <= 3)
                return [[self shortWeekdaySymbols] objectAtIndex:day];

            if (length == 4)
                return [[self weekdaySymbols] objectAtIndex:day];

            if (length >= 5)
                return [[self veryShortWeekdaySymbols] objectAtIndex:day];

        case @"e":
            var day = aDate.getDay();

            if (length <= 2)
                return [self _stringValueForValue:(day + 1) length:MIN(2, length)];

            if (length == 3)
                return [[self shortWeekdaySymbols] objectAtIndex:day];

            if (length == 4)
                return [[self weekdaySymbols] objectAtIndex:day];

            if (length >= 5)
                return [[self veryShortWeekdaySymbols] objectAtIndex:day];

        case @"c":
            var day = aDate.getDay();

            if (length <= 2)
                return [self _stringValueForValue:(day + 1) length:aDate.getDay().toString().length];

            if (length == 3)
                return [[self shortStandaloneWeekdaySymbols] objectAtIndex:day];

            if (length == 4)
                return [[self standaloneWeekdaySymbols] objectAtIndex:day];

            if (length >= 5)
                return [[self veryShortStandaloneWeekdaySymbols] objectAtIndex:day];

        case @"a":

            if (aDate.getHours() > 11)
                return [self PMSymbol];
            else
                return [self AMSymbol];

        case @"h":
            var hours = aDate.getHours();

            if ([self _isAmericanFormat] || [self _isEnglishFormat])
            {
                if (hours == 0)
                    hours = 12;
                else if (hours > 12)
                    hours = hours - 12;
            }

            var currentLength = [[CPString stringWithFormat:@"%i", hours] length];

            return [self _stringValueForValue:hours length:MAX(currentLength, MIN(2, length))];

        case @"H":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getHours()] length];

            return [self _stringValueForValue:aDate.getHours() length:MAX(currentLength, MIN(2, length))];

        case @"K":
            var hours = aDate.getHours();

            if (hours > 12)
                hours -= 12;

            var currentLength = [[CPString stringWithFormat:@"%i", hours] length];

            return [self _stringValueForValue:hours length:MAX(currentLength, MIN(2, length))];

        case @"k":
            var hours = aDate.getHours();

            if (aDate.getHours() == 0)
                hours = 24;

            var currentLength = [[CPString stringWithFormat:@"%i", hours] length];

            return [self _stringValueForValue:hours length:MAX(currentLength, MIN(2, length))];

        case @"j":
            CPLog.warn(@"Token not yet implemented " + aToken);
            return [CPString new];

        case @"m":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getMinutes()] length];

            return [self _stringValueForValue:aDate.getMinutes() length:MAX(currentLength, MIN(2, length))];

        case @"s":
            var currentLength = [[CPString stringWithFormat:@"%i", aDate.getMinutes()] length];

            return [self _stringValueForValue:aDate.getSeconds() length:MIN(2, length)];

        case @"S":
            return [self _stringValueForValue:aDate.getMilliseconds() length:length];

        case @"A":
            var value = aDate.getHours() * 60 * 60 * 1000 + aDate.getMinutes() * 60 * 1000 + aDate.getSeconds() * 1000 + aDate.getMilliseconds();

            return [self _stringValueForValue:value length:value.toString().length];

        case @"z":
            if (length <= 3)
                return [timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale];
            else
                return [timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale];

        case @"Z":
            var seconds = [timeZone secondsFromGMT],
                minutes = seconds / 60,
                hours = minutes / 60,
                result,
                diffMinutes =  (hours - parseInt(hours)) * 100 * 60 / 100;

            if (length <= 3)
            {
                result = diffMinutes.toString();

                while ([result length] < 2)
                    result = @"0" + result;

                result = ABS(parseInt(hours)) + result;

                while ([result length] < 4)
                    result = @"0" + result;

                if (seconds > 0)
                    result = @"+" + result;
                else
                    result = @"-" + result;

                return result;
            }
            else if (length == 4)
            {
                result = diffMinutes.toString();

                while ([result length] < 2)
                    result = @"0" + result;

                result = @":" + result;
                result = ABS(parseInt(hours)) + result;

                while ([result length] < 5)
                    result = @"0" + result;

                if (seconds > 0)
                    result = @"+" + result;
                else
                    result = @"-" + result;

                return @"GMT" + result;
            }
            else
            {
                result = diffMinutes.toString();

                while ([result length] < 2)
                    result = @"0" + result;

                result = @":" + result;
                result = ABS(parseInt(hours)) + result;

                while ([result length] < 5)
                    result = @"0" + result;

                if (seconds > 0)
                    result = @"+" + result;
                else
                    result = @"-" + result;

                return result;
            }

        case @"v":
            if (length == 1)
                return [timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale];
            else if (length == 4)
                return [timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale];

            return @" ";

        case @"V":
            if (length == 1)
            {
                return [timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale];
            }
            else if (length == 4)
            {
                CPLog.warn(@"No pattern found for " + aToken);
                return @"";
            }

            return @" ";

        default:
            CPLog.warn(@"No pattern found for " + aToken);
            return aToken;
    }

    return [CPString new];
}


#pragma mark -
#pragma mark datefromString

/*! Return a date of the given string
    This method returns (if possible) a representation of the given string with the dateFormat of the CPDateFormatter, otherwise it takes the dateStyle and timeStyle
    @param aString
    @return CPDate the date
*/
- (CPDate)dateFromString:(CPString)aString
{
    if (aString == nil)
        return nil;

    var format;

    if (_dateFormat != nil)
        return [self _dateFromString:aString format:_dateFormat];

    switch (_dateStyle)
    {
        case CPDateFormatterNoStyle:
            format = @"";
            break;

        case CPDateFormatterShortStyle:
            if ([self _isAmericanFormat])
                format = @"M/d/yy";
            else
                format = @"dd/MM/yy";

            break;

        case CPDateFormatterMediumStyle:
            if ([self _isAmericanFormat])
                format = @"MMM d, Y";
            else
                format = @"d MMM Y";

            break;

        case CPDateFormatterLongStyle:
            if ([self _isAmericanFormat])
                format = @"MMMM d, Y";
            else
                format = @"d MMMM Y";

            break;

        case CPDateFormatterFullStyle:
            if ([self _isAmericanFormat])
                format = @"EEEE, MMMM d, Y";
            else
                format = @"EEEE d MMMM Y";

            break;

        default:
            format = @"";
    }

    switch (_timeStyle)
    {
        case CPDateFormatterNoStyle:
            format += @"";
            break;

        case CPDateFormatterShortStyle:
            if ([self _isEnglishFormat])
                format += @" h:mm a";
            else
                format += @" H:mm";
            break;

        case CPDateFormatterMediumStyle:
            if ([self _isEnglishFormat])
                format += @" h:mm:ss a";
            else
                format += @" H:mm:ss"
            break;

        case CPDateFormatterLongStyle:
            if ([self _isEnglishFormat])
                format += @" h:mm:ss a z";
            else
                format += @" H:mm:ss z";
            break;

        case CPDateFormatterFullStyle:
            if ([self _isEnglishFormat])
                format += @" h:mm:ss a zzzz";
            else
                format += @" h:mm:ss zzzz";
            break;

        default:
            format += @"";
    }

    return [self _dateFromString:aString format:format];
}

/*! Returns a boolean if the given object has been changed or not depending of the given string (use of ref)
    @param anObject the given object
    @param aString
    @param anError, if it returns NO the describe error will be in anError (use of ref)
    @return aBoolean for the success or fail of the method
*/
- (BOOL)getObjectValue:(id)anObject forString:(CPString)aString errorDescription:(CPString)anError
{
    var value = [self dateFromString:aString];
    @deref(anObject) = value;

    if (!value)
    {
        @deref(anError) = @"The value \"" + aString + "\" is invalid.";
        return NO;
    }

    return YES;
}

/*! Return a date representation of the given string and format
    @patam aDate
    @param aFormat
    @return a string
*/
- (CPDate)_dateFromString:(CPString)aString format:(CPString)aFormat
{
    if (aString == nil || aFormat == nil)
        return nil;

    var currentToken = [CPString new],
        isTextToken = NO,
        tokens = [CPArray array],
        dateComponents = [CPArray array],
        patternTokens = [CPArray array];

    for (var i = 0; i < [aFormat length]; i++)
    {
        var character = [aFormat characterAtIndex:i];

        if (isTextToken)
        {
            if ([character isEqualToString:@"'"])
                currentToken = [CPString new];

            continue;
        }

        if ([character isEqualToString:@"'"])
        {
            if (!isTextToken)
                isTextToken = YES;

            continue;
        }

        if ([character isEqualToString:@","] || [character isEqualToString:@":"] || [character isEqualToString:@"/"] || [character isEqualToString:@"-"] || [character isEqualToString:@" "])
        {
            [tokens addObject:currentToken];

            if ([patternStringTokens containsObject:currentToken])
                [patternTokens addObject:[tokens count] - 1];

            currentToken = [CPString new];
        }
        else
        {
            if ([currentToken length] && ![[currentToken characterAtIndex:0] isEqualToString:character])
            {
                [tokens addObject:currentToken];

                if ([patternStringTokens containsObject:currentToken])
                    [patternTokens addObject:[tokens count] - 1];

                currentToken = [CPString new];
            }

            currentToken += character;

            if (i == ([aFormat length] - 1))
            {
                [tokens addObject:currentToken];

                if ([patternStringTokens containsObject:currentToken])
                    [patternTokens addObject:[tokens count] - 1];
            }
        }
    }

    isTextToken = NO;
    currentToken = [CPString new];

    var currentIndexSpecialPattern = 0;

    if ([patternTokens count] == 0)
        [patternTokens addObject:CPNotFound];

    for (var i = 0; i < [aString length]; i++)
    {
        var character = [aString characterAtIndex:i];

        if (isTextToken)
        {
            if ([character isEqualToString:@"'"])
                currentToken = [CPString new];

            continue;
        }

        if ([character isEqualToString:@"'"])
        {
            if (!isTextToken)
                isTextToken = YES;

            continue;
        }

        // Need to do this to check if the word match with the token. We can get some words with space...
        if ([dateComponents count] == [patternTokens objectAtIndex:currentIndexSpecialPattern])
        {
            var j = [self _lastIndexMatchedString:aString token:[tokens objectAtIndex:[dateComponents count]] index:i];

            if (j == CPNotFound)
                return nil;

            currentIndexSpecialPattern++;
            [dateComponents addObject:[aString substringWithRange:CPMakeRange(i, (j - i))]];
            i = j;

            continue;
        }

        if ([character isEqualToString:@","] || [character isEqualToString:@":"] || [character isEqualToString:@"/"] || [character isEqualToString:@"-"] || [character isEqualToString:@" "])
        {
            [dateComponents addObject:currentToken];
            currentToken = [CPString new];
        }
        else
        {
            currentToken += character;

            if (i == ([aString length] - 1))
                [dateComponents addObject:currentToken];
        }
    }

    if ([dateComponents count] != [tokens count])
        return nil;

    return [self _dateFromTokens:tokens dateComponents:dateComponents];
}

- (CPDate)_dateFromTokens:(CPArray)tokens dateComponents:(CPArray)dateComponents
{
    var timeZoneseconds = [_timeZone secondsFromGMT],
        dateArray = [2000, 01, 01, 00, 00, 00, @"+0000"],
        isPM = NO,
        dayOfYear,
        dayIndexInWeek,
        weekOfYear,
        weekOfMonth;

    for (var i = 0; i < [tokens count]; i++)
    {
        var token = [tokens objectAtIndex:i],
            dateComponent = [dateComponents objectAtIndex:i],
            character = [token characterAtIndex:0],
            length = [token length];

        switch (character)
        {
            case @"G":
                // TODO
                CPLog.warn(@"Token not yet implemented " + token);
                break;

            case @"y":
                var u = _twoDigitStartDate.getFullYear() % 10,
                    d = parseInt(_twoDigitStartDate.getFullYear() / 10) % 10,
                    c = parseInt(_twoDigitStartDate.getFullYear() / 100) % 10,
                    m = parseInt(_twoDigitStartDate.getFullYear() / 1000) % 10;

                if (length == 2 && dateComponent.length == 2)
                {
                    if ((u + d * 10) >= parseInt(dateComponent))
                        dateArray[0] = (c + 1) * 100 + m * 1000 + parseInt(dateComponent);
                    else
                        dateArray[0] = c * 100 + m * 1000 + parseInt(dateComponent);
                }
                else
                {
                    dateArray[0] = parseInt(dateComponent);
                }

                break;

            case @"Y":
                var u = _twoDigitStartDate.getFullYear() % 10,
                    d = parseInt(_twoDigitStartDate.getFullYear() / 10) % 10,
                    c = parseInt(_twoDigitStartDate.getFullYear() / 100) % 10,
                    m = parseInt(_twoDigitStartDate.getFullYear() / 1000) % 10;

                if (length == 2 && dateComponent.length == 2)
                {
                    if ((u + d * 10) >= parseInt(dateComponent))
                        dateArray[0] = (c + 1) * 100 + m * 1000 + parseInt(dateComponent);
                    else
                        dateArray[0] = c * 100 + m * 1000 + parseInt(dateComponent);
                }
                else
                {
                    dateArray[0] = parseInt(dateComponent);
                }

                break;

            case @"u":
                // TODO
                CPLog.warn(@"Token not yet implemented " + token);
                break;

            case @"U":
                // TODO
                CPLog.warn(@"Token not yet implemented " + token);
                break;

            case @"Q":
                var month;

                if (length <= 2)
                    month = (parseInt(dateComponent) - 1) * 3;

                if (length == 3)
                {
                    if (![[self shortQuarterSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self shortQuarterSymbols] indexOfObject:dateComponent] * 3;
                }

                if (length >= 4)
                {
                    if (![[self quarterSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self quarterSymbols] indexOfObject:dateComponent] * 3;
                }

                if (month > 11)
                    return nil;

                dateArray[1] = month + 1;
                break;

            case @"q":
                var month;

                if (length <= 2)
                    month = (parseInt(dateComponent) - 1) * 3;

                if (length == 3)
                {
                    if (![[self shortQuarterSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self shortQuarterSymbols] indexOfObject:dateComponent] * 3;
                }

                if (length >= 4)
                {
                    if (![[self quarterSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self quarterSymbols] indexOfObject:dateComponent] * 3;
                }

                if (month > 11)
                    return nil;

                dateArray[1] = month + 1;
                break;

            case @"M":
                var month;

                if (length <= 2)
                    month = parseInt(dateComponent)

                if (length == 3)
                {
                    if (![[self shortMonthSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self shortMonthSymbols] indexOfObject:dateComponent] + 1;
                }

                if (length == 4)
                {
                    if (![[self monthSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self monthSymbols] indexOfObject:dateComponent] + 1;
                }

                if (month > 11 || length >= 5)
                    return nil;

                dateArray[1] = month;
                break;

            case @"L":
                var month;

                if (length <= 2)
                    month = parseInt(dateComponent);

                if (length == 3)
                {
                    if (![[self shortStandaloneMonthSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self shortStandaloneMonthSymbols] indexOfObject:dateComponent] + 1;
                }

                if (length == 4)
                {
                    if (![[self standaloneMonthSymbols] containsObject:dateComponent])
                        return nil;

                    month = [[self standaloneMonthSymbols] indexOfObject:dateComponent] + 1;
                }

                if (month > 11 || length >= 5)
                    return nil;

                dateArray[1] = month;
                break;

            case @"I":
                // Deprecated
                CPLog.warn(@"Depreacted - Token not yet implemented " + token);
                break;

            case @"w":
                if (dateComponent > 52)
                    return nil;

                weekOfYear = dateComponent;
                break;

            case @"W":
                if (dateComponent > 52)
                    return nil;

                weekOfMonth = dateComponent;
                break;

            case @"d":
                dateArray[2] = parseInt(dateComponent);
                break;

            case @"D":
                if (isNaN(parseInt(dateComponent)) || parseInt(dateComponent) > 345)
                    return nil;

                dayOfYear = parseInt(dateComponent);
                break;

            case @"F":
                if (isNaN(parseInt(dateComponent)) || parseInt(dateComponent) > 5 || parseInt(dateComponent) == 0)
                    return nil;

                if (parseInt(dateComponent) == 1)
                    dateArray[2] = 1;

                if (parseInt(dateComponent) == 2)
                    dateArray[2] = 8;

                if (parseInt(dateComponent) == 3)
                    dateArray[2] = 15;

                if (parseInt(dateComponent) == 4)
                    dateArray[2] = 22;

                if (parseInt(dateComponent) == 5)
                    dateArray[2] = 29;

                break;

            case @"g":
                CPLog.warn(@"Token not yet implemented " + token);
                break;

            case @"E":
                if (length <= 3)
                    dayIndexInWeek = [[self shortWeekdaySymbols] indexOfObject:dateComponent];

                if (length == 4)
                    dayIndexInWeek = [[self weekdaySymbols] indexOfObject:dateComponent];

                if (dayIndexInWeek == CPNotFound || length >= 5)
                    return nil;

                break;

            case @"e":
                if (length <= 2 && isNaN(parseInt(dateComponent)))
                    return nil;

                if (length <= 2)
                    dayIndexInWeek = parseInt(dateComponent);

                if (length == 3)
                    dayIndexInWeek = [[self shortWeekdaySymbols] indexOfObject:dateComponent];

                if (length == 4)
                    dayIndexInWeek = [[self weekdaySymbols] indexOfObject:dateComponent];

                if (dayIndexInWeek == CPNotFound || length >= 5)
                    return nil;

                break;

            case @"c":
                if (length <= 2 && isNaN(parseInt(dateComponent)))
                    return nil;

                if (length <= 2)
                    dayIndexInWeek = dateComponent;

                if (length == 3)
                    dayIndexInWeek = [[self shortStandaloneWeekdaySymbols] indexOfObject:dateComponent];

                if (length == 4)
                    dayIndexInWeek = [[self standaloneWeekdaySymbols] indexOfObject:dateComponent];

                if (length == 5)
                    dayIndexInWeek = [[self veryShortStandaloneWeekdaySymbols] indexOfObject:dateComponent];

                if (dayIndexInWeek == CPNotFound || length >= 5)
                    return nil;

                break;

            case @"a":
                if (![dateComponent isEqualToString:[self PMSymbol]] && ![dateComponent isEqualToString:[self AMSymbol]])
                    return nil;

                if ([dateComponent isEqualToString:[self PMSymbol]])
                    isPM = YES;

                break;

            case @"h":
                if (parseInt(dateComponent) < 0 || parseInt(dateComponent) > 12)
                    return nil;

                dateArray[3] = parseInt(dateComponent);
                break;

            case @"H":
                if (parseInt(dateComponent) < 0 || parseInt(dateComponent) > 23)
                    return nil;

                dateArray[3] = parseInt(dateComponent);
                break;

            case @"K":
                if (parseInt(dateComponent) < 0 || parseInt(dateComponent) > 11)
                    return nil;

                dateArray[3] = parseInt(dateComponent);
                break;

            case @"k":
                if (parseInt(dateComponent) < 0 || parseInt(dateComponent) > 12)
                    return nil;

                dateArray[3] = parseInt(dateComponent);
                break;

            case @"j":
                CPLog.warn(@"Token not yet implemented " + token);
                break;

            case @"m":
                var minutes = parseInt(dateComponent);

                if (minutes > 59)
                    return nil;

                dateArray[4] = minutes;
                break;

            case @"s":
                var seconds = parseInt(dateComponent);

                if (seconds > 59)
                    return nil;

                dateArray[5] = seconds;
                break;

            case @"S":
                if (isNaN(parseInt(dateComponent)))
                    return nil;

                break;

            case @"A":
                if (isNaN(parseInt(dateComponent)))
                    return nil;

                var millisecondsInDay = parseInt(dateComponent),
                    tmpDate = new Date();

                tmpDate.setHours(0);
                tmpDate.setMinutes(0);
                tmpDate.setSeconds(0);
                tmpDate.setMilliseconds(0);

                tmpDate.setMilliseconds(millisecondsInDay);

                dateArray[3] = tmpDate.getHours();
                dateArray[4] = tmpDate.getMinutes();
                dateArray[5] = tmpDate.getSeconds();
                break;

            case @"z":
                if (length < 4)
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleShortDaylightSaving];
                else
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleDaylightSaving];

                if (!timeZoneseconds)
                    timeZoneseconds = [self _secondsFromTimeZoneDefaultFormatString:dateComponent];

                if (!timeZoneseconds)
                    return nil;

                timeZoneseconds = timeZoneseconds + 60 * 60;

                break;

            case @"Z":
                timeZoneseconds = [self _secondsFromTimeZoneDefaultFormatString:dateComponent];

                if (!timeZoneseconds)
                    return nil;

                timeZoneseconds = timeZoneseconds + 60 * 60;

                break;

            case @"v":
                if (length <= 3)
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleShortGeneric];
                else
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleGeneric];

                if (!timeZoneseconds && length == 4)
                    timeZoneseconds = [self _secondsFromTimeZoneDefaultFormatString:dateComponent];

                if (!timeZoneseconds)
                    return nil;

                timeZoneseconds = timeZoneseconds + 60 * 60;

                break;

            case @"V":
                if (length <= 3)
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleShortStandard];
                else
                    timeZoneseconds = [self _secondsFromTimeZoneString:dateComponent style:CPTimeZoneNameStyleStandard];

                if (!timeZoneseconds)
                    timeZoneseconds = [self _secondsFromTimeZoneDefaultFormatString:dateComponent];

                if (!timeZoneseconds)
                    return nil;

                timeZoneseconds = timeZoneseconds + 60 * 60;

                break;

            default:
                CPLog.warn(@"No pattern found for " + token);
                return nil;
        }
    }

    // Make the calcul day of the year
    if (dayOfYear)
    {
        var tmpDate = new Date();
        tmpDate.setFullYear(dateArray[0]);
        tmpDate.setMonth(0);

        tmpDate.setDate(dayOfYear)

        dateArray[1] = tmpDate.getMonth() + 1;
        dateArray[2] = tmpDate.getDate();
    }

    if (weekOfMonth)
        dateArray[2] = (weekOfMonth - 1) * 7 + 1;

    if (weekOfYear)
    {
        var tmpDate = new Date();
        tmpDate.setFullYear(dateArray[0]);
        tmpDate.setMonth(0);
        tmpDate.setDate(1);

        while (tmpDate.getDay() != 0)
            tmpDate.setDate(tmpDate.getDate() + 1);

        tmpDate.setDate(tmpDate.getDate() + (weekOfYear - 1) * 7);

        dateArray[1] = tmpDate.getMonth() + 1;
        dateArray[2] = tmpDate.getDate() - 1;
    }

    // Check if the day is possible in the current month
    var tmpDate = new Date();
    tmpDate.setMonth(dateArray[1] - 1);
    tmpDate.setFullYear(dateArray[0]);

    if (dateArray[2] <= 0 || dateArray[2] > [tmpDate _daysInMonth])
        return nil;

    // PM hours
    if (isPM)
        dateArray[3] += 12;

    if (isNaN(parseInt(dateArray[0])) || isNaN(parseInt(dateArray[1])) || isNaN(parseInt(dateArray[2])) || isNaN(parseInt(dateArray[3])) || isNaN(parseInt(dateArray[4])) || isNaN(parseInt(dateArray[5])) || isNaN(parseInt(dateArray[6])))
        return nil;

    var dateResult = [[CPDate alloc] initWithString:[CPString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d %s", dateArray[0], dateArray[1], dateArray[2], dateArray[3], dateArray[4], dateArray[5], dateArray[6]]];
    dateResult.setSeconds(dateResult.getSeconds() - timeZoneseconds + 60 * 60);

    return dateResult;
}


#pragma mark -
#pragma mark Utils

- (CPString)_stringValueForValue:(id)aValue length:(int)length
{
    var string = [CPString stringWithFormat:@"%i", aValue];

    if ([string length] == length)
        return string;

    if ([string length] > length)
        return [string substringFromIndex:([string length] - length)];

    while ([string length] < length)
        string = [CPString stringWithFormat:@"0%s", string];

    return string;
}

/*! Check if we are in the american format or not. Depending on the locale
*/
- (BOOL)_isAmericanFormat
{
    return [[_locale objectForKey:CPLocaleCountryCode] isEqualToString:@"US"];
}

/*! Check if we are in the english format or not. Depending on the locale
*/
- (BOOL)_isEnglishFormat
{
    return [[_locale objectForKey:CPLocaleLanguageCode] isEqualToString:@"en"];
}

/*! Returns the number of second from a time zone (-8000 or HGP-8:35 or GMT-08:00)
*/
- (int)_secondsFromTimeZoneDefaultFormatString:(CPString)aTimeZoneFormatString
{
    var format =  /\w*([HPG-GMT])?([+-])(\d{1,2})([:])?(\d{2})\w*/,
        result = aTimeZoneFormatString.match(new RegExp(format)),
        seconds = 0;

    if (!result)
        return nil;

    seconds = result[3] * 60 * 60 + result[5] * 60;

    if ([result[2] isEqualToString:@"-"])
        seconds = -seconds;

    return seconds;
}

/*! Return the number of seconds from a timeZoneString
*/
- (int)_secondsFromTimeZoneString:(CPString)aTimeZoneString style:(NSTimeZoneNameStyle)aStyle
{
    var timeZone = [CPTimeZone _timeZoneFromString:aTimeZoneString style:aStyle locale:_locale];

    if (!timeZone)
        return nil;

    return [timeZone secondsFromGMT];
}

/*! This method is used to know if the given string match with the token.
    @param aString
    @param aToken
    @param anIndex the current index in the string
    @return an index who describes the position of the end of the word for the token
*/
- (int)_lastIndexMatchedString:(CPString)aString token:(CPString)aToken index:anIndex
{
    var character = [aToken characterAtIndex:0],
        length = [aToken length],
        targetedArray,
        format = /\w*([HPG-GMT])?([+-])(\d{1,2})([:])?(\d{2})\w*/,
        result = aString.match(new RegExp(format));

    switch (character)
    {
        case @"Q":
            if (length == 3)
                targetedArray = [self shortQuarterSymbols];

            if (length >= 4)
                targetedArray = [self quarterSymbols];

            break;

        case @"q":
            if (length == 3)
                targetedArray = [self shortStandaloneQuarterSymbols];

            if (length >= 4)
                targetedArray = [self standaloneQuarterSymbols];

            break;

        case @"M":
            if (length == 3)
                targetedArray = [self shortMonthSymbols];

            if (length == 4)
                targetedArray = [self monthSymbols];

            if (length >= 5)
                targetedArray = [self veryShortMonthSymbols];

            break;

        case @"L":
            if (length == 3)
                targetedArray = [self shortStandaloneMonthSymbols];

            if (length == 4)
                targetedArray = [self standaloneMonthSymbols];

            if (length >= 5)
                targetedArray = [self veryShortStandaloneMonthSymbols];

            break;

        case @"E":
            if (length <= 3)
                targetedArray = [self shortWeekdaySymbols];

            if (length == 4)
                targetedArray = [self weekdaySymbols];

            if (length >= 5)
                targetedArray = [self veryShortWeekdaySymbols];

            break;

        case @"e":
            if (length == 3)
                targetedArray = [self shortWeekdaySymbols];

            if (length == 4)
                targetedArray = [self weekdaySymbols];

            if (length >= 5)
                targetedArray = [self veryShortWeekdaySymbols];

            break;

        case @"c":
            if (length == 3)
                targetedArray = [self shortStandaloneWeekdaySymbols];

            if (length == 4)
                targetedArray = [self standaloneWeekdaySymbols];

            if (length >= 5)
                targetedArray = [self veryShortStandaloneWeekdaySymbols];

            break;

        case @"a":
            targetedArray = [[self PMSymbol], [self AMSymbol]];
            break;

        case @"z":
            if (length <= 3)
                targetedArray =  [CPTimeZone _namesForStyle:CPTimeZoneNameStyleShortDaylightSaving locale:_locale];
            else
                targetedArray =  [CPTimeZone _namesForStyle:CPTimeZoneNameStyleDaylightSaving locale:_locale];

            if (result)
                return anIndex + [result objectAtIndex:0].length;

            break;

        case @"Z":
            if (result)
                return anIndex + [result objectAtIndex:0].length;

            return CPNotFound;

        case @"v":
            if (length == 1)
                targetedArray =  [CPTimeZone _namesForStyle:CPTimeZoneNameStyleShortGeneric locale:_locale];
            else if (length == 4)
                targetedArray =  [CPTimeZone _namesForStyle:CPTimeZoneNameStyleGeneric locale:_locale];

            if (result)
                return anIndex + [result objectAtIndex:0].length;

            break;

        case @"V":
            if (length == 1)
                targetedArray = [CPTimeZone _namesForStyle:CPTimeZoneNameStyleShortStandard locale:_locale];

            if (result)
                return anIndex + [result objectAtIndex:0].length;

            break;

        default:
            CPLog.warn(@"No pattern found for " + aToken);
            return CPNotFound;
    }

    for (var i = 0; i < [targetedArray count]; i++)
    {
        var currentObject = [targetedArray objectAtIndex:i],
            range = [aString rangeOfString:currentObject];

        if (range.length == 0)
            continue;

        character = [aString characterAtIndex:(anIndex + range.length)];

        if ([character isEqualToString:@"'"] || [character isEqualToString:@","] || [character isEqualToString:@":"] || [character isEqualToString:@"/"] || [character isEqualToString:@"-"] || [character isEqualToString:@" "] || [character isEqualToString:@""])
            return anIndex + range.length;
    }

    return CPNotFound;
}

@end

var CPDateFormatterDateStyleKey = @"CPDateFormatterDateStyle",
    CPDateFormatterTimeStyleKey = @"CPDateFormatterTimeStyleKey",
    CPDateFormatterFormatterBehaviorKey = @"CPDateFormatterFormatterBehaviorKey",
    CPDateFormatterDoseRelativeDateFormattingKey = @"CPDateFormatterDoseRelativeDateFormattingKey",
    CPDateFormatterDateFormatKey = @"CPDateFormatterDateFormatKey",
    CPDateFormatterAllowNaturalLanguageKey = @"CPDateFormatterAllowNaturalLanguageKey",
    CPDateFormatterLocaleKey = @"CPDateFormatterLocaleKey";

@implementation CPDateFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _allowNaturalLanguage = [aCoder decodeBoolForKey:CPDateFormatterAllowNaturalLanguageKey];
        _dateFormat = [aCoder decodeObjectForKey:CPDateFormatterDateFormatKey];
        _dateStyle = [aCoder decodeIntForKey:CPDateFormatterDateStyleKey];
        _doesRelativeDateFormatting = [aCoder decodeBoolForKey:CPDateFormatterDoseRelativeDateFormattingKey];
        _formatterBehavior = [aCoder decodeIntForKey:CPDateFormatterFormatterBehaviorKey];
        _locale = [aCoder decodeObjectForKey:CPDateFormatterLocaleKey];
        _timeStyle = [aCoder decodeIntForKey:CPDateFormatterTimeStyleKey];
    }

    [self _init];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_allowNaturalLanguage forKey:CPDateFormatterAllowNaturalLanguageKey];
    [aCoder encodeInt:_dateStyle forKey:CPDateFormatterDateStyleKey];
    [aCoder encodeObject:_dateFormat forKey:CPDateFormatterDateFormatKey];
    [aCoder encodeBool:_doesRelativeDateFormatting forKey:CPDateFormatterDoseRelativeDateFormattingKey];
    [aCoder encodeInt:_formatterBehavior forKey:CPDateFormatterFormatterBehaviorKey];
    [aCoder encodeInt:_locale forKey:CPDateFormatterLocaleKey];
    [aCoder encodeInt:_timeStyle forKey:CPDateFormatterTimeStyleKey];
}

@end


@implementation CPDate (CPTimeZone)

/*! Convert a date from a timeZone
*/
- (void)_dateWithTimeZone:(CPTimeZone)aTimeZone
{
    self.setSeconds(self.getSeconds() - [aTimeZone secondsFromGMTForDate:self]);
    self.setSeconds(self.getSeconds() + [aTimeZone secondsFromGMT]);
}

@end