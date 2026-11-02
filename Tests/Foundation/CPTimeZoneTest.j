/* CPTimeZoneTest.j
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

@import <Foundation/Foundation.j>
@import <OJUnit/OJTestCase.j>

@implementation CPTimeZoneTest : OJTestCase
{
    CPLocale    _locale;
    CPData      _data;
    CPDate      _date;
    CPDate      _januaryDate;
    CPDate      _julyDate;
}

- (void)setUp
{
    _locale = [[CPLocale alloc] initWithLocaleIdentifier:@"en_US"];
    _data = [CPData dataWithRawString:@"Data with string"];
    _date = [[CPDate alloc] initWithString:@"2011-10-05 16:34:38 +0900"];

    /*
        The rules of a zone decide its offset and abbreviation on a given date. Fixed
        dates in January and July give the same result on any day and on any host.
        A zone with daylight saving time differs between them, and a zone without it
        has the same offset on both.
    */
    _januaryDate = [[CPDate alloc] initWithString:@"2026-01-15 12:00:00 +0000"];
    _julyDate = [[CPDate alloc] initWithString:@"2026-07-15 12:00:00 +0000"];
}

- (void)assertPacificTimeZone:(CPTimeZone)timeZone
{
    [self assert:@"America/Los_Angeles" equals:[timeZone name]];

    [self assert:@"PST" equals:[timeZone abbreviationForDate:_januaryDate]];
    [self assert:(-480 * 60) equals:[timeZone secondsFromGMTForDate:_januaryDate]];
    [self assertFalse:[timeZone isDaylightSavingTimeForDate:_januaryDate]];

    [self assert:@"PDT" equals:[timeZone abbreviationForDate:_julyDate]];
    [self assert:(-420 * 60) equals:[timeZone secondsFromGMTForDate:_julyDate]];
    [self assertTrue:[timeZone isDaylightSavingTimeForDate:_julyDate]];

    // The abbreviation and the offset are both those of the current date.
    var now = [CPDate date];

    [self assert:[timeZone abbreviationForDate:now] equals:[timeZone abbreviation]];
    [self assert:[timeZone secondsFromGMTForDate:now] equals:[timeZone secondsFromGMT]];
    [self assert:@"America/Los_Angeles (" + [timeZone abbreviation] + ") offset " + [timeZone secondsFromGMT] equals:[timeZone description]];

    [self assert:@"Pacific Standard Time" equals:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale]];
    [self assert:@"PST" equals:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale]];
    [self assert:@"Pacific Daylight Time" equals:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale]];
    [self assert:@"PDT" equals:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale]];
    [self assert:@"Pacific Time" equals:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale]];
    [self assert:@"PT" equals:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale]];
}

- (void)tearDown
{

}

- (void)testTimeZoneWithAbbreviation
{
    [self assertPacificTimeZone:[CPTimeZone timeZoneWithAbbreviation:@"PDT"]];
    [self assertPacificTimeZone:[CPTimeZone timeZoneWithAbbreviation:@"PST"]];
}

- (void)testTimeZoneWithWrongAbbreviation
{
    var timeZone = [CPTimeZone timeZoneWithAbbreviation:@"PDTezdez"];
    [self assert:timeZone equals:nil];
}

- (void)testTimeZoneWithName
{
    [self assertPacificTimeZone:[CPTimeZone timeZoneWithName:@"America/Los_Angeles"]];
}

- (void)testTimeZoneWithWrongName
{
    var timeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angelesezdez"];
    [self assert:timeZone equals:nil];
}

- (void)testexceptionTimeZoneWithNilName
{
    try
    {
        [CPTimeZone timeZoneWithName:nil];
        [self fail:"Invalid value provided for tzName"];
    }
    catch (e)
    {

    }
}

- (void)testTimeZoneWithNameWithData
{
    var timeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angeles" data:_data];

    [self assertPacificTimeZone:timeZone];
    [self assert:_data equals:[timeZone data]];
}

- (void)testTimeZoneWithWrongNameWithData
{
    var timeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angelesezdez" data:_data];
    [self assert:timeZone equals:nil];
}

- (void)testexceptionTimeZoneWithNilNameWithData
{
    try
    {
        [CPTimeZone timeZoneWithName:nil data:_data];
        [self fail:"Invalid value provided for tzName"];
    }
    catch (e)
    {

    }
}

- (void)testTimeZoneWithSecondsFromGMT
{
    // timeZoneForSecondsFromGMT returns a fixed-offset zone. It does not
    // back-resolve to geographical regions (like Pacific/Honolulu).
    var timeZone = [CPTimeZone timeZoneForSecondsFromGMT:(-600 * 60)];
    [self assert:[timeZone name] equals:@"GMT-10:00"];
    [self assert:[timeZone abbreviation] equals:@"GMT-10:00"];
    [self assert:[timeZone secondsFromGMT] equals:(-600 * 60)];
    [self assert:[timeZone description] equals:@"GMT-10:00 (GMT-10:00) offset -36000"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"GMT-10:00"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"GMT-10:00"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"GMT-10:00"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"GMT-10:00"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"GMT-10:00"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"GMT-10:00"];
}

- (void)testTimeZoneWithWrongSecondsFromGMT
{
    // +/- 18 hours is the limit. -421 * 60 is valid and creates a fixed zone.
    var timeZone = [CPTimeZone timeZoneForSecondsFromGMT:(-421 * 60)];
    [self assert:[timeZone name] equals:@"GMT-07:01"];
    [self assert:[timeZone secondsFromGMT] equals:(-421 * 60)];

    // An offset strictly outside the +/- 18 hour range should return nil.
    var invalidTimeZone = [CPTimeZone timeZoneForSecondsFromGMT:(19 * 3600)];
    [self assert:invalidTimeZone equals:nil];
}

- (void)testInitTimeZoneWithName
{
    [self assertPacificTimeZone:[[CPTimeZone alloc] initWithName:@"America/Los_Angeles"]];
}

- (void)testInitTimeZoneWithWrongName
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angelesezdez"];
    [self assert:timeZone equals:nil];
}

- (void)testexceptionInitTimeZoneWithNilName
{
    try
    {
        [[CPTimeZone alloc] initWithName:nil];
        [self fail:"Invalid value provided for tzName"];
    }
    catch (e)
    {

    }
}

- (void)testInitTimeZoneWithNameWithData
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles" data:_data];

    [self assertPacificTimeZone:timeZone];
    [self assert:_data equals:[timeZone data]];
}

- (void)testInitTimeZoneWithWrongNameWithData
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angelesezdez" data:_data];
    [self assert:timeZone equals:nil];
}

- (void)testexceptionInitTimeZoneWithNilNameWithData
{
    try
    {
        [[CPTimeZone alloc] initWithName:nil data:_data];
        [self fail:"Invalid value provided for tzName"];
    }
    catch (e)
    {

    }
}

/*
    The local time zone depends on the host, and many zones have no curated
    abbreviation, so a named zone is used.
*/
- (void)testAbbreviationWithDate
{
    var timeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angeles"];

    [self assert:@"PDT" equals:[timeZone abbreviationForDate:_date]];
    [self assert:@"PST" equals:[timeZone abbreviationForDate:_januaryDate]];
    [self assertNotNull:[[CPTimeZone localTimeZone] abbreviationForDate:_date]];
}

- (void)testAbbreviationWithNilDate
{
    var timeZone = [CPTimeZone localTimeZone],
    abbreviation = [timeZone abbreviationForDate:nil];

    [self assert:abbreviation equals:nil];
}


- (void)testSecondsFromGMTForDate
{
    var timeZone = [CPTimeZone localTimeZone],
    seconds = [timeZone secondsFromGMTForDate:_date];

    [self assert:seconds equals:(_date.getTimezoneOffset() * -60)];
}

- (void)testSecondsFromGMTForDateWithNilDate
{
    var timeZone = [CPTimeZone localTimeZone],
    seconds = [timeZone secondsFromGMTForDate:nil];

    [self assert:seconds equals:nil];
}

- (void)testSecondsFromGMT
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];

    [self assert:(-480 * 60) equals:[timeZone secondsFromGMTForDate:_januaryDate]];
    [self assert:(-420 * 60) equals:[timeZone secondsFromGMTForDate:_julyDate]];
    [self assert:[timeZone secondsFromGMTForDate:[CPDate date]] equals:[timeZone secondsFromGMT]];
}

- (void)testDescription
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"],
        expected = [timeZone secondsFromGMT] === -480 * 60 ? @"America/Los_Angeles (PST) offset -28800" : @"America/Los_Angeles (PDT) offset -25200";

    [self assert:expected equals:[timeZone description]];
}

- (void)testLocalizedName
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
}

- (void)testEqualTrueToTimeZone
{
    var timeZone1 = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"],
    timeZone2 = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];

    [self assert:[timeZone1 isEqualToTimeZone:timeZone2] equals:YES];
}

- (void)testEqualFalseToTimeZone
{
    var timeZone1 = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"],
    timeZone2 = [[CPTimeZone alloc] initWithName:@"Pacific/Honolulu"];

    [self assert:[timeZone1 isEqualToTimeZone:timeZone2] equals:NO];
}

- (void)testInitWithNameRespectsDaylightSaving
{
    var laTimeZoneName = @"America/Los_Angeles";
    var expectedAbbreviationLA;

    try {
        var options = { timeZone: laTimeZoneName, timeZoneName: 'short' };
        var parts = new Intl.DateTimeFormat('en-US', options).formatToParts(new Date());
        var tzPart = parts.filter(function (p) { return p.type === 'timeZoneName'; })[0];
        expectedAbbreviationLA = tzPart ? tzPart.value : nil;
    } catch (e) {
        [self fail:"Could not determine expected abbreviation for America/Los_Angeles"];
        return;
    }

    var timeZoneLA = [[CPTimeZone alloc] initWithName:laTimeZoneName];

    if (timeZoneLA == nil)
        [self fail:"Time zone for America/Los_Angeles should be created successfully."];

    [self assert:[timeZoneLA abbreviation] equals:expectedAbbreviationLA];

    var hnlTimeZoneName = @"Pacific/Honolulu";
    var timeZoneHNL = [[CPTimeZone alloc] initWithName:hnlTimeZoneName];

    if (timeZoneHNL == nil)
        [self fail:"Time zone for Pacific/Honolulu should be created successfully."];

    [self assert:[timeZoneHNL abbreviation] equals:@"HST"];
}

- (void)testCorrectedOffsets
{
    // Validate IANA name resolution for legacy abbreviations.
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"MDT"] name] equals:@"America/Denver"];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"MSK"] name] equals:@"Europe/Moscow"];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"NZDT"] name] equals:@"Pacific/Auckland"];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"NZST"] name] equals:@"Pacific/Auckland"];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"WAT"] name] equals:@"Africa/Lagos"];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"WIT"] name] equals:@"Asia/Jakarta"];

    // Evaluate against fixed dates to prevent seasonal failures during CI runs.
    var janDate = [[CPDate alloc] initWithString:@"2026-01-15 12:00:00 +0000"];
    var julDate = [[CPDate alloc] initWithString:@"2026-07-15 12:00:00 +0000"];

    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"MDT"] secondsFromGMTForDate:julDate] equals:(-360 * 60)];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"MSK"] secondsFromGMTForDate:janDate] equals:(180 * 60)];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"NZDT"] secondsFromGMTForDate:janDate] equals:(780 * 60)];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"NZST"] secondsFromGMTForDate:julDate] equals:(720 * 60)];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"WAT"] secondsFromGMTForDate:janDate] equals:(60 * 60)];
    [self assert:[[CPTimeZone timeZoneWithAbbreviation:@"WIT"] secondsFromGMTForDate:janDate] equals:(420 * 60)];
}

- (void)testMSKCorrectCurrentValue
{
    // MSD and MSK resolve to Europe/Moscow, which has no daylight saving time.
    var timeZone = [CPTimeZone timeZoneWithAbbreviation:@"MSD"];

    [self assert:@"Europe/Moscow" equals:[timeZone name]];
    [self assert:(180 * 60) equals:[timeZone secondsFromGMTForDate:_januaryDate]];
    [self assert:(180 * 60) equals:[timeZone secondsFromGMTForDate:_julyDate]];
    [self assertFalse:[timeZone isDaylightSavingTimeForDate:_julyDate]];
    [self assert:[timeZone secondsFromGMTForDate:[CPDate date]] equals:[timeZone secondsFromGMT]];
}

- (void)testKnownTimeZoneNamesUsesIntlWhenAvailable
{
    if (typeof Intl === "undefined" || typeof Intl.supportedValuesOf !== "function")
        return;

    var names = [CPTimeZone knownTimeZoneNames];

    [self assertTrue:([names count] > 48)
             message:"knownTimeZoneNames should use Intl.supportedValuesOf when available, not the small hardcoded fallback list"];
    [self assertTrue:[names containsObject:@"Europe/Berlin"]
             message:"a zone absent from the old hardcoded list should be present via Intl"];
}

- (void)disabled_testLocalizedNameFrenchLocale
{
    var frenchLocale = [[CPLocale alloc] initWithLocaleIdentifier:@"fr_FR"],
    timeZone = [CPTimeZone timeZoneWithAbbreviation:@"PST"];

    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:frenchLocale] equals:@"Heure normale du Pacifique"];
}

- (void)disabled_testTimeZoneForSecondsFromGMTOffsetCollisionIsAmbiguous
{
    var timeZone = [CPTimeZone timeZoneForSecondsFromGMT:(-360 * 60)];
    [self assert:timeZone equals:nil];
}

@end
