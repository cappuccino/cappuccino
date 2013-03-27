/* CPLocale.j
* Foundation
*
* Created by Alexandre Wilhelm
* Copyright 2012 <alexandre.wilhelmfr@gmail.com>
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

@import "CPObject.j"

@class CPDictionary

CPLocaleIdentifier = @"CPLocaleIdentifier";
CPLocaleLanguageCode = @"CPLocaleLanguageCode";
CPLocaleCountryCode = @"CPLocaleCountryCode";
CPLocaleScriptCode = @"CPLocaleScriptCode";
CPLocaleVariantCode = @"CPLocaleVariantCode";
CPLocaleExemplarCharacterSet = @"CPLocaleExemplarCharacterSet";
CPLocaleCalendar = @"CPLocaleCalendar";
CPLocaleCollationIdentifier = @"CPLocaleCollationIdentifier";
CPLocaleUsesMetricSystem = @"CPLocaleUsesMetricSystem";
CPLocaleMeasurementSystem = @"CPLocaleMeasurementSystem";
CPLocaleDecimalSeparator = @"CPLocaleDecimalSeparator";
CPLocaleGroupingSeparator = @"CPLocaleGroupingSeparator";
CPLocaleCurrencySymbol = @"CPLocaleCurrencySymbol";
CPLocaleCurrencyCode = @"CPLocaleCurrencyCode";
CPLocaleCollatorIdentifier = @"CPLocaleCollatorIdentifier";
CPLocaleQuotationBeginDelimiterKey = @"CPLocaleQuotationBeginDelimiterKey";
CPLocaleQuotationEndDelimiterKey = @"CPLocaleQuotationEndDelimiterKey";
CPLocaleAlternateQuotationBeginDelimiterKey = @"CPLocaleAlternateQuotationBeginDelimiterKey";
CPLocaleAlternateQuotationEndDelimiterKey = @"CPLocaleAlternateQuotationEndDelimiterKey";

CPGregorianCalendar = @"CPGregorianCalendar";
CPBuddhistCalendar = @"CPBuddhistCalendar";
CPChineseCalendar = @"CPChineseCalendar";
CPHebrewCalendar = @"CPHebrewCalendar";
CPIslamicCalendar = @"CPIslamicCalendar";
CPIslamicCivilCalendar = @"CPIslamicCivilCalendar";
CPJapaneseCalendar = @"CPJapaneseCalendar";
CPRepublicOfChinaCalendar = @"CPRepublicOfChinaCalendar";
CPPersianCalendar = @"CPPersianCalendar";
CPIndianCalendar = @"CPIndianCalendar";
CPISO8601Calendar = @"CPISO8601Calendar";

CPLocaleLanguageDirectionUnknown = @"CPLocaleLanguageDirectionUnknown";
CPLocaleLanguageDirectionLeftToRight = @"CPLocaleLanguageDirectionLeftToRight";
CPLocaleLanguageDirectionRightToLeft = @"CPLocaleLanguageDirectionRightToLeft";
CPLocaleLanguageDirectionTopToBottom = @"CPLocaleLanguageDirectionTopToBottom";
CPLocaleLanguageDirectionBottomToTop = @"CPLocaleLanguageDirectionBottomToTop";

var countryCodes = [@"DE", @"FR", @"ES", @"GB", @"US"],
    languageCodes = [@"en", @"de", @"es", @"fr"],
    availableLocaleIdentifiers = [@"de_DE", @"en_EN", @"en_US", @"es_ES", @"fr_FR"];

var sharedSystemLocale = nil,
    sharedCurrentLocale = nil;

@implementation CPLocale : CPObject
{
    CPDictionary _locale;
}

/*! Return the system locale. By default is en_US
*/
+ (id)systemLocale
{
    if (!sharedSystemLocale)
        sharedSystemLocale = [[CPLocale alloc] initWithLocaleIdentifier:@"en_US"];

    return sharedSystemLocale;
}

/*! Return the current locale base on the navigator
*/
+ (id)currentLocale
{
    if (!sharedCurrentLocale)
    {
        var localeIdentifier,
            language;

        if (typeof navigator != "undefined")
        {
            if (navigator.appVersion.indexOf("MSIE") >= 0)
                language = navigator.browserLanguage.substring(0,2);
            else
                language = navigator.language.substring(0,2);

            language = [CPString stringWithFormat:@"%s_%s", [language lowercaseString], [language uppercaseString]];

            if ([availableLocaleIdentifiers indexOfObject:language])
                localeIdentifier = language;
        }

        if (!localeIdentifier)
            localeIdentifier = @"en_US";

        sharedCurrentLocale = [[CPLocale alloc] initWithLocaleIdentifier:localeIdentifier];
    }

    return sharedCurrentLocale
}

/*! Return an array of the availableLocaleIdentifiers
*/
+ (CPArray)availableLocaleIdentifiers
{
    return availableLocaleIdentifiers;
}

/*! Return an array with the ISOCountryCodes
*/
+ (CPArray)ISOCountryCodes
{
    return countryCodes;
}

// + (CPArray)ISOCurrencyCodes
// {
//     // TODO
//     return;
// }

/*! Return an array with the ISOLanguageCodes
*/
+ (CPArray)ISOLanguageCodes
{
    return languageCodes;
}

// + (CPArray)commonISOCurrencyCodes
// {
//     // TODO
//     return;
// }

/*! Init a new instance of CPLocale with a given identifier.
    This method will call the class method _platformLocaleAdditionalDescriptionForIdentifier:. It's usefull if you want to implement your CPLocale.
    @parameter anIdentifier
*/
- (id)initWithLocaleIdentifier:(CPString)anIdentifier
{
    if (self == [super init])
    {
    	var parts = [anIdentifier componentsSeparatedByString:@"_"],
    	    language = [parts objectAtIndex:0],
    	    country = nil;

        if ([parts count] > 1)
    		country = [parts objectAtIndex:1];
        else
    	    country = anIdentifier;

        _locale = [[CPDictionary alloc] init];
        [_locale setObject:anIdentifier forKey:CPLocaleIdentifier];
        [_locale setObject:language forKey:CPLocaleLanguageCode];
        [_locale setObject:country forKey:CPLocaleCountryCode];

        if([[self class] respondsToSelector:@selector(_platformLocaleAdditionalDescriptionForIdentifier:)])
        {
        	// Use any platform specific method to fill the locale info if one is defined
        	var info = [[self class] performSelector:@selector(_platformLocaleAdditionalDescriptionForIdentifier:) withObject:anIdentifier];
        	[_locale addEntriesFromDictionary:info];
        }
        else
        {
            [_locale setObject:CPGregorianCalendar forKey:CPLocaleCalendar];
        }
    }

    return self;
}

// - (CPString)displayNameForKey:(id)aKey value:(id)aValue
// {
//     // TODO
//     return;
// }

/*! Return the CPLocaleIdentifier
*/
- (CPString)localeIdentifier
{
    return [_locale objectForKey:CPLocaleIdentifier];
}

/*! Return the object depending of the key
    @param aKey
    @return an object
*/
- (id)objectForKey:(id)aKey
{
    return [_locale objectForKey:aKey];
}

@end


var CPLocaleIdentifierLocaleKey = @"CPLocaleIdentifierLocaleKey";

@implementation CPLocale (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        _locale = [aCoder decodeObjectForKey:CPLocaleIdentifierLocaleKey];
    }

    return self
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    //[super encodeWithCoder:aCoder];

    [aCoder encodeObject:_locale forKey:CPLocaleIdentifierLocaleKey];
}

@end
