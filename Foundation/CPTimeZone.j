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

@class CPData
@class CPNotificationCenter

CPTimeZoneNameStyleStandard = 0;
CPTimeZoneNameStyleShortStandard = 1;
CPTimeZoneNameStyleDaylightSaving = 2;
CPTimeZoneNameStyleShortDaylightSaving = 3;
CPTimeZoneNameStyleGeneric = 4;
CPTimeZoneNameStyleShortGeneric = 5;

CPSystemTimeZoneDidChangeNotification = @"CPSystemTimeZoneDidChangeNotification";

/*
 * Time zone identity is defined by its IANA name.
 * Offsets, abbreviations, and localized names are resolved dynamically
 * using the runtime's Intl API rather than static tables.
 *
 * Dynamic resolution prevents the silent data drift of hardcoded tables
 * caused by DST rule changes and newly added zones. It also avoids the
 * inherent ambiguity of abbreviations (e.g., CST, IST), which are not
 * globally unique and cannot serve as primary keys.
 */
var abbreviationDictionary,
knownTimeZoneNames,
defaultTimeZone,
localTimeZone,
systemTimeZone,
timeZoneDataVersion;

// Per-zone cache of the sampled standard/daylight offsets (see
// _standardAndDaylightOffsetsForZone). A zone's DST rule doesn't change
// within a process lifetime, so this is safe to keep for the session.
var _stdDstOffsetCache = {};

// Per (locale, style) cache of display-name -> zone name, used by
// +_timeZoneFromString:style:locale: and built lazily on first lookup.
var _nameToZoneCache = {};

/*!
 Validates a given time zone name by attempting to construct a lightweight
 Intl.DateTimeFormat object. The engine throws a RangeError if the timeZone
 is not recognized.
 */
function _isValidTimeZoneName(tzName)
{
    try
    {
        new Intl.DateTimeFormat('en-US', { timeZone: tzName });
        return YES;
    }
    catch (e)
    {
        return NO;
    }
}

/*!
 Live UTC offset, in minutes, for an IANA zone name at a given date.
 DST-aware by construction, since it asks Intl to render the actual wall
 clock time in that zone at that instant, rather than reading a static
 per-abbreviation number. Returns nil if tzName isn't a zone Intl accepts.
 */
function _offsetMinutesForZone(tzName, date)
{
    if (tzName === @"GMT" || tzName === @"UTC")
        return 0;

    try
    {
        var dtf = new Intl.DateTimeFormat("en-US", {
            timeZone: tzName,
            hourCycle: "h23",
            year: "numeric", month: "2-digit", day: "2-digit",
            hour: "2-digit", minute: "2-digit", second: "2-digit"
        }),
        parts = dtf.formatToParts(date),
        map = {};

        for (var i = 0; i < parts.length; i++)
            map[parts[i].type] = parts[i].value;

        // Date.UTC normalizes out-of-range fields (e.g. an hour of "24"),
        // so no special-casing is needed for that formatting quirk.
        var asUTC = Date.UTC(map.year, map.month - 1, map.day, map.hour, map.minute, map.second);

        return Math.round((asUTC - date.getTime()) / 60000);
    }
    catch (e)
    {
        // tzName isn't a zone this engine's Intl implementation accepts.
        return nil;
    }
}

/*!
 Short abbreviation (e.g. "PDT") for an IANA zone name at a given date,
 read directly from Intl.formatToParts so it reflects DST for that date.
 */
function _abbreviationForNameAndDate(tzName, date)
{
    try
    {
        var parts = new Intl.DateTimeFormat("en-US", { timeZone: tzName, timeZoneName: "short" }).formatToParts(date),
        tzPart = parts.filter(function (p) { return p.type === "timeZoneName"; })[0];

        return tzPart ? tzPart.value : nil;
    }
    catch (e)
    {
        // The tzName might be invalid for Intl.DateTimeFormat, which throws a RangeError.
        return nil;
    }
}

/*!
 Renders a "GMT+HH:MM" style label for a fixed offset. Used both for
 zones created with +timeZoneForSecondsFromGMT: and as a last-resort
 abbreviation when Intl can't produce a short name for a real zone.
 */
function _fixedOffsetName(seconds)
{
    var sign = (seconds < 0) ? "-" : "+",
    absSeconds = Math.abs(seconds),
    hours = Math.floor(absSeconds / 3600),
    minutes = Math.floor((absSeconds % 3600) / 60);

    return @"GMT" + sign + (hours < 10 ? "0" : "") + hours + ":" + (minutes < 10 ? "0" : "") + minutes;
}

/*!
 Determines, for a real IANA zone, which of its two yearly offsets is the
 standard (non-DST) one and which is the daylight one, by sampling a
 January and a July instant and comparing: DST is always the more-advanced
 of the two, regardless of hemisphere. Also hands back a UTC instant that
 falls in each so callers can ask Intl for the name at that instant. Does
 not model historical rule changes mid-year; this is a current-rules
 snapshot, same boundary the underlying Intl/tzdata itself has.
 */
function _standardAndDaylightOffsetsForZone(tzName)
{
    var cached = _stdDstOffsetCache[tzName];

    if (cached)
        return cached;

    var year       =  new Date().getUTCFullYear(),
    janDate    =  new Date(Date.UTC(year, 0, 15, 12)),
    julDate    =  new Date(Date.UTC(year, 6, 15, 12)),
    janOffset  =  _offsetMinutesForZone(tzName, janDate),
    julOffset  =  _offsetMinutesForZone(tzName, julDate);

    if (janOffset === nil || julOffset === nil)
        return nil;

    var result = (janOffset <= julOffset)
    ? { standard: janOffset, daylight: julOffset, standardSampleDate: janDate, daylightSampleDate: julDate, observesDST: janOffset !== julOffset }
    : { standard: julOffset, daylight: janOffset, standardSampleDate: julDate, daylightSampleDate: janDate, observesDST: janOffset !== julOffset };

    _stdDstOffsetCache[tzName] = result;

    return result;
}

/*!
 Asks Intl for a zone's display name at a given instant, with a fallback
 chain for engines that don't support the requested timeZoneName option
 (e.g. the newer "shortGeneric"/"longGeneric" values) or the given locale
 tag, so a display name is still produced rather than nothing.
 */
function _formatZoneName(tzName, localeCode, date, preferredOption, fallbackOption)
{
    var dtf;

    try
    {
        dtf = new Intl.DateTimeFormat(localeCode, { timeZone: tzName, timeZoneName: preferredOption });
    }
    catch (e)
    {
        try
        {
            dtf = new Intl.DateTimeFormat(localeCode, { timeZone: tzName, timeZoneName: fallbackOption });
        }
        catch (e2)
        {
            dtf = new Intl.DateTimeFormat("en", { timeZone: tzName, timeZoneName: fallbackOption });
        }
    }

    var parts = dtf.formatToParts(date),
    tzPart = parts.filter(function (p) { return p.type === "timeZoneName"; })[0];

    return tzPart ? tzPart.value : nil;
}

/*!
 Resolves the localized name for a zone at a given style. Standard and
 DaylightSaving styles must name that specific offset regardless of what
 date is currently in effect, so they're rendered at a sampled instant
 known to fall in that offset rather than "now". A fixed-offset zone (see
 +timeZoneForSecondsFromGMT:) has no separate long/generic name in any
 style; its GMT-offset label is returned for all six.
 */
function _localizedNameForZone(tzName, style, locale, fixedOffsetSecondsOrNil)
{
    if (fixedOffsetSecondsOrNil !== nil && fixedOffsetSecondsOrNil !== undefined)
        return _fixedOffsetName(fixedOffsetSecondsOrNil);

    var localeCode = (locale && [locale objectForKey:CPLocaleLanguageCode]) || "en";

    try
    {
        switch (style)
        {
            case CPTimeZoneNameStyleShortGeneric:
                return _formatZoneName(tzName, localeCode, [CPDate date], "shortGeneric", "short");

            case CPTimeZoneNameStyleGeneric:
                return _formatZoneName(tzName, localeCode, [CPDate date], "longGeneric", "long");

            case CPTimeZoneNameStyleShortStandard:
            case CPTimeZoneNameStyleShortDaylightSaving:
            {
                var offsets = _standardAndDaylightOffsetsForZone(tzName);

                if (!offsets)
                    return nil;

                var wantsDaylight = (style === CPTimeZoneNameStyleShortDaylightSaving) && offsets.observesDST,
                refDate = wantsDaylight ? offsets.daylightSampleDate : offsets.standardSampleDate;

                return _formatZoneName(tzName, localeCode, refDate, "short", "short");
            }

            case CPTimeZoneNameStyleStandard:
            case CPTimeZoneNameStyleDaylightSaving:
            {
                var offsets = _standardAndDaylightOffsetsForZone(tzName);

                if (!offsets)
                    return nil;

                var wantsDaylight = (style === CPTimeZoneNameStyleDaylightSaving) && offsets.observesDST,
                refDate = wantsDaylight ? offsets.daylightSampleDate : offsets.standardSampleDate;

                return _formatZoneName(tzName, localeCode, refDate, "long", "long");
            }
        }
    }
    catch (e)
    {
        return nil;
    }

    return nil;
}

/*!
 Resolves the runtime's own current zone as a CPTimeZone: prefer the
 IANA name Intl resolves to (DST-correct), and fall back to a fixed-offset zone
 built from the JS Date offset if Intl isn't available at all. Always
 succeeds.
 */
function _systemTimeZoneFromRuntime()
{
    var date = new Date();

    try
    {
        var ianaName = new Intl.DateTimeFormat().resolvedOptions().timeZone;

        if (ianaName && _isValidTimeZoneName(ianaName))
        {
            var zone = [CPTimeZone timeZoneWithName:ianaName];

            if (zone)
                return zone;
        }
    }
    catch (e)
    {
        // Intl unsupported, or resolvedOptions().timeZone unavailable.
    }

    return [CPTimeZone timeZoneForSecondsFromGMT:-date.getTimezoneOffset() * 60];
}

/*!
 @class CPTimeZone
 @ingroup foundation
 @brief CPTimeZone is a class to define the behavior of time zone object (like CPDatePicker)
 */
@implementation CPTimeZone : CPObject
{
    CPData      _data                @accessors(property=data, readonly);
    CPInteger   _secondsFromGMT      @accessors(property=secondFromGMT, readonly);
    CPString    _abbreviation        @accessors(property=abbreviation, readonly);
    CPString    _name                @accessors(property=name, readonly);

    // Set only for zones created with +timeZoneForSecondsFromGMT:, which per
    // Apple's contract never observe daylight saving time.
    BOOL        _hasFixedOffset;
    CPInteger   _fixedOffsetSeconds;
}

/*! Initialize the default value of the class
 */
+ (void)initialize
{
    if (self !== [CPTimeZone class])
        return;

    knownTimeZoneNames = [];

    // Prefer the runtime's own IANA database when it exposes one.
    if (typeof Intl !== "undefined" && typeof Intl.supportedValuesOf === "function")
    {
        try
        {
            var supportedZones = Intl.supportedValuesOf("timeZone");

            if (supportedZones && supportedZones.length > 0)
            {
                var count = supportedZones.length;

                for (var i = 0; i < count; i++)
                {
                    knownTimeZoneNames[i] = supportedZones[i];
                }
            }
        }
        catch (e)
        {
            // Fall through.
        }
    }

    var hasGMT = false;
    var hasUTC = false;

    for (var i = 0, count = knownTimeZoneNames.length; i < count; i++)
    {
        if (knownTimeZoneNames[i] === @"GMT")
            hasGMT = true;
        else if (knownTimeZoneNames[i] === @"UTC")
            hasUTC = true;
    }

    if (!hasGMT)
        knownTimeZoneNames[knownTimeZoneNames.length] = @"GMT";

    if (!hasUTC)
        knownTimeZoneNames[knownTimeZoneNames.length] = @"UTC";

    // A curated abbreviation -> canonical name lookup for +timeZoneWithAbbreviation:.
    // This stays a fixed, hand-maintained set deliberately: abbreviations are
    // not unique across regions (CST, IST, EST each name more than one real
    // zone), so this table is a documented best-effort convenience, not a
    // source of truth for offsets or names the way it was before.
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
        @"CUT" :   @"UTC",
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

    timeZoneDataVersion = nil;

    localTimeZone = _systemTimeZoneFromRuntime();
    systemTimeZone = localTimeZone;
    defaultTimeZone = localTimeZone;
}


// MARK: -
// MARK: Class constructor

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

/*! Return a fixed-offset time zone for the given number of seconds from GMT.
 Per Apple's documented contract for this constructor, the returned zone
 never observes daylight saving time. Offsets are rounded to the nearest
 minute; offsets more than +/- 18 hours are disallowed and return nil.
 @param seconds the number of seconds
 @return a new instance of CPTimeZone
 */
+ (id)timeZoneForSecondsFromGMT:(CPInteger)seconds
{
    if (Math.abs(seconds) > 18 * 3600)
        return nil;

    var roundedSeconds = Math.round(seconds / 60) * 60;

    return [[CPTimeZone alloc] _initWithFixedOffsetSeconds:roundedSeconds];
}

/*! @ignore
 */
+ (id)_timeZoneFromString:(CPString)aTimeZoneString style:(NSTimeZoneNameStyle)style locale:(CPLocale)_locale
{
    if ([abbreviationDictionary containsKey:aTimeZoneString])
        return [self timeZoneWithAbbreviation:aTimeZoneString];

    var localeCode = (_locale && [_locale objectForKey:CPLocaleLanguageCode]) || "en",
    cacheKey = localeCode + "|" + style,
    map = _nameToZoneCache[cacheKey];

    if (!map)
    {
        map = {};

        for (var i = 0, count = knownTimeZoneNames.length; i < count; i++)
        {
            var tzName = knownTimeZoneNames[i],
            displayName = _localizedNameForZone(tzName, style, _locale, nil);

            // First zone found for a given display name wins; a handful of
            // zones legitimately share a display name (e.g. generic-style
            // "GMT+02:00" style fallbacks), and any one of them is as valid
            // a match as another for parsing purposes.
            if (displayName && !(displayName in map))
                map[displayName] = tzName;
        }

        _nameToZoneCache[cacheKey] = map;
    }

    var matchedName = map[aTimeZoneString];

    return matchedName ? [self timeZoneWithName:matchedName] : nil;
}

/*! @ignore
 */
+ (CPArray)_namesForStyle:(NSTimeZoneNameStyle)style locale:(CPLocale)aLocale
{
    var array = [CPArray array];

    for (var i = 0, count = knownTimeZoneNames.length; i < count; i++)
    {
        var displayName = _localizedNameForZone(knownTimeZoneNames[i], style, aLocale, nil);

        if (displayName)
            [array addObject:displayName];
    }

    return array;
}

// MARK: -
// MARK: Class accessors

/*! Return the timeZoneDataVersion (not yet implemented)
 */
+ (CPString)timeZoneDataVersion
{
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
    systemTimeZone = _systemTimeZoneFromRuntime();

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSystemTimeZoneDidChangeNotification object:systemTimeZone];
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


// MARK: -
// MARK: Constructors

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

    if (!_isValidTimeZoneName(tzName) || !abbreviation)
        return nil;

    if (self = [super init])
    {
        _name = tzName;
        _abbreviation = abbreviation;
    }

    return self;
}

/*! Init a fixed-offset time zone (see +timeZoneForSecondsFromGMT:).
 @param seconds the fixed offset, already rounded to the nearest minute
 */
- (id)_initWithFixedOffsetSeconds:(CPInteger)seconds
{
    if (self = [super init])
    {
        _name = _fixedOffsetName(seconds);
        _abbreviation = _name;
        _hasFixedOffset = YES;
        _fixedOffsetSeconds = seconds;
    }

    return self;
}

/*! Init a new time zone from the given timeZone name
 Returns nil if the given timeZone name isn't a known IANA zone name
 Raises an exception if tzName is nil
 @param tzName the timeZone name
 @return a new instance of CPTimeZone
 */
- (id)initWithName:(CPString)tzName
{
    if (!tzName)
        [CPException raise:CPInvalidArgumentException reason:"Invalid value provided for tzName"];

    if (!_isValidTimeZoneName(tzName))
        return nil;

    if (self = [super init])
    {
        _name = tzName;

        // Determine the abbreviation based on the current date, so it
        // reflects DST if this zone is presently observing it.
        var now = [CPDate date],
        currentAbbreviation = _abbreviationForNameAndDate(tzName, now);

        if (currentAbbreviation)
        {
            _abbreviation = currentAbbreviation;
        }
        else
        {
            // Intl couldn't produce a short name for this zone on this
            // engine (rare). Synthesize a GMT-offset label from the live
            // offset instead of failing construction for an otherwise
            // valid, known zone name.
            var offsetMinutes = _offsetMinutesForZone(tzName, now);

            if (offsetMinutes === nil)
                return nil;

            _abbreviation = _fixedOffsetName(offsetMinutes * 60);
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


// MARK: -
// MARK: Methods for CPDate

/*! Returns this time zone's abbreviation at the given date, reflecting DST
 if this zone observes it and the date falls in it.
 Returns nil if the date is nil
 @return the abbreviation
 */
- (CPString)abbreviationForDate:(CPDate)date
{
    if (!date)
        return nil;

    if (_hasFixedOffset)
        return _abbreviation;

    return _abbreviationForNameAndDate(_name, date) || _abbreviation;
}

/*! Returns the number of seconds this time zone differs from GMT at the
 given date. DST-aware: the value varies across the year for zones that
 observe it. A fixed-offset zone (see +timeZoneForSecondsFromGMT:) always
 returns the same value regardless of date.
 Returns nil if the date is nil
 @param date
 @return the number of seconds
 */
- (CPInteger)secondsFromGMTForDate:(CPDate)date
{
    if (!date)
        return nil;

    if (_hasFixedOffset)
        return _fixedOffsetSeconds;

    var offsetMinutes = _offsetMinutesForZone(_name, date);

    return (offsetMinutes === nil) ? nil : offsetMinutes * 60;
}

/*! Returns the number of seconds this time zone differs from GMT right now.
 @return the number of seconds
 */
- (CPInteger)secondsFromGMT
{
    return [self secondsFromGMTForDate:[CPDate date]];
}

/*! Returns whether this time zone is currently observing daylight saving time.
 Always NO for a fixed-offset zone (see +timeZoneForSecondsFromGMT:).
 @return a bool
 */
- (BOOL)isDaylightSavingTime
{
    return [self isDaylightSavingTimeForDate:[CPDate date]];
}

/*! Returns whether this time zone is observing daylight saving time at the given date.
 Always NO for a fixed-offset zone (see +timeZoneForSecondsFromGMT:).
 @param date
 @return a bool
 */
- (BOOL)isDaylightSavingTimeForDate:(CPDate)date
{
    if (_hasFixedOffset || !date)
        return NO;

    var offsets = _standardAndDaylightOffsetsForZone(_name);

    if (!offsets || !offsets.observesDST)
        return NO;

    var current = _offsetMinutesForZone(_name, date);

    return current !== nil && current > offsets.standard;
}

/*! Returns the daylight saving time offset, in seconds, this time zone is
 currently applying on top of its standard offset. 0 if not presently
 observing daylight saving time.
 @return the number of seconds
 */
- (CPTimeInterval)daylightSavingTimeOffset
{
    return [self daylightSavingTimeOffsetForDate:[CPDate date]];
}

/*! Returns the daylight saving time offset, in seconds, this time zone
 applies on top of its standard offset at the given date. 0 if the date
 doesn't fall within daylight saving time for this zone.
 @param date
 @return the number of seconds
 */
- (CPTimeInterval)daylightSavingTimeOffsetForDate:(CPDate)date
{
    if (![self isDaylightSavingTimeForDate:date])
        return 0;

    var offsets = _standardAndDaylightOffsetsForZone(_name);

    return (offsets.daylight - offsets.standard) * 60;
}


// MARK: -
// MARK: Compare methods

/*! Returns a bool to compare two timeZones.
 This is made by comparing the name and the data of the timeZones
 @return a bool
 */
- (BOOL)isEqualToTimeZone:(CPTimeZone)aTimeZone
{
    return [[aTimeZone name] isEqualToString:_name] && [aTimeZone data] == _data;
}


// MARK: -
// MARK: Description

/*! Returns the description of the timeZone
 The pattern of the description is : 'name of the timeZone' ('abbreviation of the timeZone') offset 'the timeDifferenceFromGMT'
 @return the description
 */
- (CPString)description
{
    return [CPString stringWithFormat:@"%s (%s) offset %i", _name, _abbreviation, [self secondsFromGMT]];
}


// MARK: -
// MARK: Localized methods

/*! Return a localized string from the given style and locale
 @param style the style
 @param locale the locale
 @return a string
 */
- (CPString)localizedName:(NSTimeZoneNameStyle)style locale:(CPLocale)locale
{
    if (style < 0 || style > 5)
        return nil;

    return _localizedNameForZone(_name, style, locale, _hasFixedOffset ? _fixedOffsetSeconds : nil);
}

@end
