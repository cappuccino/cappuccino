/* CPTimeZone.j
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
@import "CPString.j"
@import "CPDate.j"
@import "CPLocale.j"

CPTimeZoneNameStyleStandard = 0;
CPTimeZoneNameStyleShortStandard = 1;
CPTimeZoneNameStyleDaylightSaving = 2;
CPTimeZoneNameStyleShortDaylightSaving = 3;
CPTimeZoneNameStyleGeneric = 4;
CPTimeZoneNameStyleShortGeneric = 5;

CPSystemTimeZoneDidChangeNotification = @"CPSystemTimeZoneDidChangeNotification";

var abbreviationDictionary,
    timeDifferenceFromUTC,
    knownTimeZoneNames,
    defaultTimeZone,
    localTimeZone,
    systemTimeZone,
    timeZoneDataVersion,
    localizedName;

/*!
    @class CPTimeZone
    @ingroup foundation
    @brief CPTimeZone is a class to define the behvior of time zone object (like CPDatePicker)
*/
@implementation CPTimeZone : CPObject
{
    CPData      _data           @accessors(property=data, readonly);
    CPInteger   _secondsFromGMT @accessors(property=secondFromGMT, readonly);
    CPString    _abbreviation   @accessors(property=abbreviation, readonly);
    CPString    _name           @accessors(property=name, readonly);
}

/*! Initialize the default value of the class
*/
+ (void)initialize
{
    if (self !== [CPTimeZone class])
        return;

    knownTimeZoneNames = [
        @"America/Halifax",
        @"America/Juneau",
        @"America/Juneau",
        @"America/Argentina/Buenos_Aires",
        @"America/Halifax",
        @"Asia/Dhaka",
        @"America/Sao_Paulo",
        @"America/Sao_Paulo",
        @"Europe/London",
        @"Africa/Harare",
        @"America/Chicago",
        @"Europe/Paris",
        @"Europe/Paris",
        @"America/Santiago",
        @"America/Santiago",
        @"America/Bogota",
        @"America/Chicago",
        @"Africa/Addis_Ababa",
        @"America/New_York",
        @"Europe/Istanbul",
        @"Europe/Istanbul",
        @"America/New_York",
        @"GMT",
        @"Asia/Dubai",
        @"Asia/Hong_Kong",
        @"Pacific/Honolulu",
        @"Asia/Bangkok",
        @"Asia/Tehran",
        @"Asia/Calcutta",
        @"Asia/Tokyo",
        @"Asia/Seoul",
        @"America/Denver",
        @"Europe/Moscow",
        @"Europe/Moscow",
        @"America/Denver",
        @"Pacific/Auckland",
        @"Pacific/Auckland",
        @"America/Los_Angeles",
        @"America/Lima",
        @"Asia/Manila",
        @"Asia/Karachi",
        @"America/Los_Angeles",
        @"Asia/Singapore",
        @"UTC",
        @"Africa/Lagos",
        @"Europe/Lisbon",
        @"Europe/Lisbon",
        @"Asia/Jakarta"
     ];

    abbreviationDictionary = @{
        @"ADT" :   @"America/Halifax",
        @"AKDT" :  @"America/Juneau",
        @"AKST" :  @"America/Juneau",
        @"ART" :   @"America/Argentina/Buenos_Aires",
        @"AST" :   @"America/Halifax",
        @"BDT" :   @"Asia/Dhaka",
        @"BRST" :  @"America/Sao_Paulo",
        @"BRT" :   @"America/Sao_Paulo",
        @"BST" :   @"Europe/London",
        @"CAT" :   @"Africa/Harare",
        @"CDT" :   @"America/Chicago",
        @"CEST" :  @"Europe/Paris",
        @"CET" :   @"Europe/Paris",
        @"CLST" :  @"America/Santiago",
        @"CLT" :   @"America/Santiago",
        @"COT" :   @"America/Bogota",
        @"CST" :   @"America/Chicago",
        @"EAT" :   @"Africa/Addis_Ababa",
        @"EDT" :   @"America/New_York",
        @"EEST" :  @"Europe/Istanbul",
        @"EET" :   @"Europe/Istanbul",
        @"EST" :   @"America/New_York",
        @"GMT" :   @"GMT",
        @"GST" :   @"Asia/Dubai",
        @"HKT" :   @"Asia/Hong_Kong",
        @"HST" :   @"Pacific/Honolulu",
        @"ICT" :   @"Asia/Bangkok",
        @"IRST" :  @"Asia/Tehran",
        @"IST" :   @"Asia/Calcutta",
        @"JST" :   @"Asia/Tokyo",
        @"KST" :   @"Asia/Seoul",
        @"MDT" :   @"America/Denver",
        @"MSD" :   @"Europe/Moscow",
        @"MSK" :   @"Europe/Moscow",
        @"MST" :   @"America/Denver",
        @"NZDT" :  @"Pacific/Auckland",
        @"NZST" :  @"Pacific/Auckland",
        @"PDT" :   @"America/Los_Angeles",
        @"PET" :   @"America/Lima",
        @"PHT" :   @"Asia/Manila",
        @"PKT" :   @"Asia/Karachi",
        @"PST" :   @"America/Los_Angeles",
        @"SGT" :   @"Asia/Singapore",
        @"UTC" :   @"UTC",
        @"WAT" :   @"Africa/Lagos",
        @"WEST" :  @"Europe/Lisbon",
        @"WET" :   @"Europe/Lisbon",
        @"WIT" :   @"Asia/Jakarta"
    };

    timeDifferenceFromUTC = @{
        @"ADT" :    -180,
        @"AKDT" :   -480,
        @"AKST" :   -540,
        @"ART" :    -180,
        @"AST" :    -240,
        @"BDT" :    360,
        @"BRST" :   -120,
        @"BRT" :    -180,
        @"BST" :    60,
        @"CAT" :    120,
        @"CDT" :    -300,
        @"CEST" :   120,
        @"CET" :    60,
        @"CLST" :   -180,
        @"CLT" :    -240,
        @"COT" :    -300,
        @"CST" :    -360,
        @"EAT" :    180,
        @"EDT" :    -240,
        @"EEST" :   180,
        @"EET" :    120,
        @"EST" :    -300,
        @"GMT" :    0,
        @"GST" :    240,
        @"HKT" :    480,
        @"HST" :    -600,
        @"ICT" :    420,
        @"IRST" :   210,
        @"IST" :    330,
        @"JST" :    540,
        @"KST" :    540,
        @"MDT" :    -300,
        @"MSD" :    240,
        @"MSK" :    240,
        @"MST" :    -420,
        @"NZDT" :   900,
        @"NZST" :   900,
        @"PDT" :    -420,
        @"PET" :    -300,
        @"PHT" :    480,
        @"PKT" :    300,
        @"PST" :    -480,
        @"SGT" :    480,
        @"UTC" :    0,
        @"WAT" :    -540,
        @"WEST" :   60,
        @"WET" :    0,
        @"WIT" :    540
    };

    var englishLocalizedName = @{
        @"EDT" :    [@"Eastern Standard Time", @"EST", @"Eastern Daylight Time", @"EDT", @"Eastern Time", @"ET"],
        @"GMT" :    [@"GMT", @"GMT", @"GMT", @"GMT", @"GMT", @"GMT"],
        @"AST" :    [@"Atlantic Standard Time", @"AST", @"Atlantic Daylight Time", @"ADT", @"Atlantic Time", @"AT"],
        @"IRST" :   [@"Iran Standard Time", @"GMT+03:30", @"Iran Daylight Time", @"GMT+03:30", @"Iran Time", @"Iran Time"],
        @"ICT" :    [@"Indochina Time", @"GMT+07:00", @"GMT+07:00", @"GMT+07:00", @"Indochina Time", @"Thailand Time"],
        @"PET" :    [@"Peru Standard Time", @"GMT-05:00", @"Peru Summer Time", @"GMT-05:00", @"Peru Standard Time", @"Peru Time"],
        @"KST" :    [@"Korean Standard Time", @"GMT+09:00", @"Korean Daylight Time", @"GMT+09:00", @"Korean Standard Time", @"South Korea Time"],
        @"PST" :    [@"Pacific Standard Time", @"PST", @"Pacific Daylight Time", @"PDT", @"Pacific Time", @"PT"],
        @"CDT" :    [@"Central Standard Time", @"CST", @"Central Daylight Time", @"CDT", @"Central Time", @"CT"],
        @"EEST" :   [@"Eastern European Standard Time", @"GMT+02:00", @"Eastern European Summer Time", @"GMT+03:00", @"Eastern European Time", @"Turkey Time"],
        @"NZDT" :   [@"New Zealand Standard Time", @"GMT+12:00", @"New Zealand Daylight Time", @"GMT+13:00", @"New Zealand Time", @"New Zealand Time (Auckland)"],
        @"WEST" :   [@"Western European Standard Time", @"GMT", @"Western European Summer Time", @"GMT+01:00", @"Western European Time", @"Portugal Time (Lisbon)"],
        @"EAT" :    [@"East Africa Time", @"GMT+03:00", @"GMT+03:00", @"GMT+03:00", @"East Africa Time", @"Ethiopia Time"],
        @"HKT" :    [@"Hong Kong Standard Time", @"GMT+08:00", @"Hong Kong Summer Time", @"GMT+08:00", @"Hong Kong Standard Time", @"Hong Kong SAR China Time"],
        @"IST" :    [@"India Standard Time", @"GMT+05:30", @"GMT+05:30", @"GMT+05:30", @"India Standard Time", @"India Time"],
        @"MDT" :    [@"Mountain Standard Time", @"MST", @"Mountain Daylight Time", @"MDT", @"Mountain Time", @"MT"],
        @"NZST" :   [@"New Zealand Standard Time", @"GMT+12:00", @"New Zealand Daylight Time", @"GMT+13:00", @"New Zealand Time", @"New Zealand Time (Auckland)"],
        @"WIT" :    [@"Western Indonesia Time", @"GMT+07:00", @"GMT+07:00", @"GMT+07:00", @"Western Indonesia Time", @"Indonesia Time (Jakarta)"],
        @"ADT" :    [@"Atlantic Standard Time", @"AST", @"Atlantic Daylight Time", @"ADT", @"Atlantic Time", @"AT"],
        @"BST" :    [@"Greenwich Mean Time", @"GMT", @"British Summer Time", @"GMT+01:00", @"United Kingdom Time", @"United Kingdom Time"],
        @"ART" :    [@"Argentina Standard Time", @"GMT-03:00", @"Argentina Summer Time", @"GMT-03:00", @"Argentina Standard Time", @"Argentina Time (Buenos Aires)"],
        @"CAT" :    [@"Central Africa Time", @"GMT+02:00", @"GMT+02:00", @"GMT+02:00", @"Central Africa Time", @"Zimbabwe Time"],
        @"GST" :    [@"Gulf Standard Time", @"GMT+04:00", @"GMT+04:00", @"GMT+04:00", @"Gulf Standard Time", @"United Arab Emirates Time"],
        @"PDT" :    [@"Pacific Standard Time", @"PST", @"Pacific Daylight Time", @"PDT", @"Pacific Time", @"PT"],
        @"SGT" :    [@"Singapore Standard Time", @"GMT+08:00", @"GMT+08:00", @"GMT+08:00", @"Singapore Standard Time", @"Singapore Time"],
        @"COT" :    [@"Colombia Standard Time", @"GMT-05:00", @"Colombia Summer Time", @"GMT-05:00", @"Colombia Standard Time", @"Colombia Time"],
        @"PKT" :    [@"Pakistan Standard Time", @"GMT+05:00", @"Pakistan Summer Time", @"GMT+05:00", @"Pakistan Standard Time", @"Pakistan Time"],
        @"EET" :    [@"Eastern European Standard Time", @"GMT+02:00", @"Eastern European Summer Time", @"GMT+03:00", @"Eastern European Time", @"Turkey Time"],
        @"UTC" :    [@"GMT", @"GMT", @"GMT", @"GMT", @"GMT", @"GMT"],
        @"WAT" :    [@"West Africa Standard Time", @"GMT+01:00", @"West Africa Summer Time", @"GMT+01:00", @"West Africa Standard Time", @"Nigeria Time"],
        @"EST" :    [@"Eastern Standard Time", @"EST", @"Eastern Daylight Time", @"EDT", @"Eastern Time", @"ET"],
        @"JST" :    [@"Japan Standard Time", @"GMT+09:00", @"Japan Daylight Time", @"GMT+09:00", @"Japan Standard Time", @"Japan Time"],
        @"CLST" :   [@"Chile Standard Time", @"GMT-04:00", @"Chile Summer Time", @"GMT-04:00", @"Chile Time", @"Chile Time (Santiago)"],
        @"CET" :    [@"Central European Standard Time", @"GMT+01:00", @"Central European Summer Time", @"GMT+02:00", @"Central European Time", @"France Time"],
        @"BDT" :    [@"Bangladesh Standard Time", @"GMT+06:00", @"Bangladesh Summer Time", @"GMT+06:00", @"Bangladesh Standard Time", @"Bangladesh Time"],
        @"MSK" :    [@"Moscow Standard Time", @"GMT+04:00", @"Moscow Summer Time", @"GMT+04:00", @"Moscow Standard Time", @"Russia Time (Moscow)"],
        @"AKDT" :   [@"Alaska Standard Time", @"AKST", @"Alaska Daylight Time", @"AKDT", @"Alaska Time", @"AKT"],
        @"CLT" :    [@"Chile Standard Time", @"GMT-04:00", @"Chile Summer Time", @"GMT-04:00", @"Chile Time", @"Chile Time (Santiago)"],
        @"AKST" :   [@"Alaska Standard Time", @"AKST", @"Alaska Daylight Time", @"AKDT", @"Alaska Time", @"AKT"],
        @"BRST" :   [@"Brasilia Standard Time", @"GMT-03:00", @"Brasilia Summer Time", @"GMT-03:00", @"Brasilia Time", @"Brazil Time (Sao Paulo)"],
        @"BRT" :    [@"Brasilia Standard Time", @"GMT-03:00", @"Brasilia Summer Time", @"GMT-03:00", @"Brasilia Time", @"Brazil Time (Sao Paulo)"],
        @"CEST" :   [@"Central European Standard Time", @"GMT+01:00", @"Central European Summer Time", @"GMT+02:00", @"Central European Time", @"France Time"],
        @"CST" :    [@"Central Standard Time", @"CST", @"Central Daylight Time", @"CDT", @"Central Time", @"CT"],
        @"HST" :    [@"Hawaii-Aleutian Standard Time", @"HST", @"Hawaii-Aleutian Daylight Time", @"HDT", @"Hawaii-Aleutian Standard Time", @"HST"],
        @"MSD" :    [@"Moscow Standard Time", @"GMT+04:00", @"Moscow Summer Time", @"GMT+04:00", @"Moscow Standard Time", @"Russia Time (Moscow)"],
        @"MST" :    [@"Mountain Standard Time", @"MST", @"Mountain Daylight Time", @"MDT", @"Mountain Time", @"MT"],
        @"PHT" :    [@"Philippine Standard Time", @"GMT+08:00", @"Philippine Summer Time", @"GMT+08:00", @"Philippine Standard Time", @"Philippines Time"],
        @"WET" :    [@"Western European Standard Time", @"GMT", @"Western European Summer Time", @"GMT+01:00", @"Western European Time", @"Portugal Time (Lisbon)"]
    };

    var date = [CPDate date],
        abbreviation = String(String(date).split("(")[1]).split(")")[0];

    localTimeZone = [self timeZoneWithAbbreviation:abbreviation];
    systemTimeZone = [self timeZoneWithAbbreviation:abbreviation];
    defaultTimeZone = [self timeZoneWithAbbreviation:abbreviation];

    localizedName = @{
        @"en" : englishLocalizedName,
        @"fr" : @{},
        @"de" : @{},
        @"es" : @{}
    };

    timeZoneDataVersion = nil;
}


#pragma mark -
#pragma mark Class constructor

/*! Returns a time zone from the given abbreviation.
    Returns nil if the given abbreviation doesn't match with any abbreviations
    @param abbreviation the given abreviation
    @return a new instance of CPTimeZone
*/
+ (id)timeZoneWithAbbreviation:(CPString)abbreviation
{
    if (![abbreviationDictionary containsKey:abbreviation])
        return nil;

    return [[CPTimeZone alloc] _initWithName:[abbreviationDictionary valueForKey:abbreviation] abbreviation:abbreviation];
}

/*! Return a time zone from the given timeZone name
    Returns nil if the given timeZone name doesn't match with any abbreviations
    Raises an exception if tzName is nil
    @param tzName the timeZone name
    @return a new instance of CPTimeZone
*/
+ (id)timeZoneWithName:(CPString)tzName
{
    return [[CPTimeZone alloc] initWithName:tzName];
}

/*! Return a time zone from the given timeZone name and data
    Returns nil if the given timeZone name doesn't match with any abbreviations
    Raises an exception if tzName is nil
    @param tzName the timeZone name
    @param data the data
    @return a new instance of CPTimeZone
*/
+ (id)timeZoneWithName:(CPString)tzName data:(CPData)data
{
    return [[CPTimeZone alloc] initWithName:tzName data:data];
}

/*! Return a time zone from the given seconds
    Returns nil if the number of seconds doesn't match with any offset
    @param seconds the number of seconds
    @return a new instance of CPTimeZone
*/
+ (id)timeZoneForSecondsFromGMT:(CPInteger)seconds
{
    var minutes = seconds / 60,
        keys = [timeDifferenceFromUTC keyEnumerator],
        key,
        abbreviation = nil;

    while (key = [keys nextObject])
    {
        var value = [timeDifferenceFromUTC valueForKey:key];

        if (value == minutes)
        {
            abbreviation = key;
            break;
        }
    }

    if (!abbreviation)
        return nil;

    return [self timeZoneWithAbbreviation:abbreviation];
}

/*! @ignore
*/
+ (id)_timeZoneFromString:(CPString)aTimeZoneString style:(NSTimeZoneNameStyle)style locale:(CPLocale)_locale
{
    if ([abbreviationDictionary containsKey:aTimeZoneString])
        return [self timeZoneWithAbbreviation:aTimeZoneString];

    var dict = [localizedName valueForKey:[_locale objectForKey:CPLocaleLanguageCode]];
        keys = [dict keyEnumerator],
        key;

    while (key = [keys nextObject])
    {
        var value = [[dict valueForKey:key] objectAtIndex:style];

        if ([value isEqualToString:aTimeZoneString])
            return [self timeZoneWithAbbreviation:key];
    }

    return nil;
}

/*! @ignore
*/
+ (CPArray)_namesForStyle:(NSTimeZoneNameStyle)style locale:(CPLocale)aLocale
{
    var array = [CPArray array],
        dict = [localizedName valueForKey:[aLocale objectForKey:CPLocaleLanguageCode]];
        keys = [dict keyEnumerator],
        key;

    while (key = [keys nextObject])
        [array addObject:[[dict valueForKey:key] objectAtIndex:style]];

    return array;
}

#pragma mark -
#pragma mark Class accessors

/*! Return the timeZoneDataVersion (not yet implemented)
*/
+ (CPString)timeZoneDataVersion
{
    // TODO : don't know what to do ^^
    return timeZoneDataVersion;
}

/*! Return the localTimeZone
*/
+ (CPTimeZone)localTimeZone
{
    return localTimeZone;
}

/*! Return the defaultTimeZone
*/
+ (CPTimeZone)defaultTimeZone
{
    return defaultTimeZone;
}

/*! Set the defaultTimeZone
    @param aTimeZone the defaultTimeZone
*/
+ (void)setDefaultTimeZone:(CPTimeZone)aTimeZone
{
    defaultTimeZone = aTimeZone;
}

/*! Reset the systemTimeZone
    This will send the notification CPSystemTimeZoneDidChangeNotification
*/
+ (void)resetSystemTimeZone
{
    var date = [CPDate date],
        abbreviation = String(String(date).split("(")[1]).split(")")[0];

    systemTimeZone = [self timeZoneWithAbbreviation:abbreviation];

    [[CPNotification defaultCenter] postNotificationName:CPSystemTimeZoneDidChangeNotification object:systemTimeZone];
}

/*! Return the systemTimeZone
*/
+ (CPTimeZone)systemTimeZone
{
    return systemTimeZone;
}

/*! Return the abbreviationDictionary
*/
+ (CPDictionary)abbreviationDictionary
{
    return abbreviationDictionary;
}

/*! Set the abbreviationDictionary
    @param dict
*/
+ (void)setAbbreviationDictionary:(CPDictionary)dict
{
    abbreviationDictionary = dict;
}

/*! Return the knownTimeZoneNames
*/
+ (CPArray)knownTimeZoneNames
{
    return knownTimeZoneNames;
}


#pragma mark -
#pragma mark Consructors

/*! Init a new time zone with the given time zone name and abbreviation
    Returns nil if tzName doesn't match with any timeZoneNames or if abbreviation is nil
    Raises an exception if tzName is nil
    @param tzName the timeZone name
    @param abbreviation the abbreviation
    @return a new timeZone
*/
- (id)_initWithName:(CPString)tzName abbreviation:(CPString)abbreviation
{
    if (!tzName)
        [CPException raise:CPInvalidArgumentException reason:"Invalid value provided for tzName"];

    if (![knownTimeZoneNames containsObject:tzName] || !abbreviation)
        return nil;

    if (self = [super init])
    {
        _name = tzName;
        _abbreviation = abbreviation;
    }

    return self;
}

/*! Init a new time zone from the given timeZone name
    Returns nil if the given timeZone name doesn't match with any abbreviations
    Raises an exception if tzName is nil
    @param tzName the timeZone name
    @return a new instance of CPTimeZone
*/
- (id)initWithName:(CPString)tzName
{
    if (!tzName)
        [CPException raise:CPInvalidArgumentException reason:"Invalid value provided for tzName"];

    if (![knownTimeZoneNames containsObject:tzName])
        return nil;

    if (self = [super init])
    {
        _name = tzName;

        var keys = [abbreviationDictionary keyEnumerator],
            key;

        while (key = [keys nextObject])
        {
            var value = [abbreviationDictionary valueForKey:key];

            if ([value isEqualToString:_name])
            {
                _abbreviation = key;
                break;
            }
        }
    }

    return self;
}

/*! Return a time zone from the given timeZone name and data
    Returns nil if the given timeZone name doesn't match with any abbreviations
    Raises an exception if tzName is nil
    @param tzName the timeZone name
    @param data the data
    @return a new instance of CPTimeZone
*/
- (id)initWithName:(CPString)tzName data:(CPData)data
{
    if (self = [self initWithName:tzName])
    {
        _data = data;
    }

    return self;
}


#pragma mark -
#pragma mark Methods for CPDate

/*! Returns the abbreviation from a date
    Returns nil if the date is nil
    @return the abbreviation
*/
- (CPString)abbreviationForDate:(CPDate)date
{
    if (!date)
        return nil;

    return String(String(date).split("(")[1]).split(")")[0];
}

/*! Returns the number of seconds from GMT for the given date
    Returns nil if the date is nil
    @param date
    @return the number of seconds
*/
- (CPInteger)secondsFromGMTForDate:(CPDate)date
{
    if (!date)
        return nil;

    var abbreviation = String(String(date).split("(")[1]).split(")")[0];

    return [timeDifferenceFromUTC valueForKey:abbreviation] * 60;
}

/*! Returns the number of seconds from GMT
    @return the number of seconds
*/
- (CPInteger)secondsFromGMT
{
    return [timeDifferenceFromUTC valueForKey:_abbreviation] * 60;
}


#pragma mark -
#pragma mark Compars methods

/*! Returns a bool to compare tow timeZones.
    This is made by the compare of the name and the data of the timeZones
    @return a bool
*/
- (BOOL)isEqualToTimeZone:(CPTimeZone)aTimeZone
{
    return [[aTimeZone name] isEqualToString:_name] && [aTimeZone data] == _data
}


#pragma mark -
#pragma mark Description

/*! Returns the description of the timeZone
    The pattern of the description is : 'name of the timeZone' ('abbreviation of the timeZone') offset 'the timeDifferenceFromGMT'
    @return the description
*/
- (CPString)description
{
    return [CPString stringWithFormat:@"%s (%s) offset %i", _name, _abbreviation, [self secondsFromGMT]];
}


#pragma mark -
#pragma mark Localized methods

/*! Return a localized string from the given style and locale
    @param style the style
    @param locale the locale
    @return a string
*/
- (CPString)localizedName:(NSTimeZoneNameStyle)style locale:(CPLocale)locale
{
    if (style > 5)
        return nil;

    return [[[localizedName valueForKey:[locale objectForKey:CPLocaleLanguageCode]] valueForKey:_abbreviation] objectAtIndex:style];
}

@end