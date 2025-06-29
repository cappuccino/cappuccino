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
}

- (void)setUp
{
    _locale = [[CPLocale alloc] initWithLocaleIdentifier:@"en_US"];
    _data = [CPData dataWithRawString:@"Data with string"];
    _date = [[CPDate alloc] initWithString:@"2011-10-05 16:34:38 +0900"];
}

- (void)tearDown
{

}

- (void)testTimeZoneWithAbbreviation
{
    var timeZone = [CPTimeZone timeZoneWithAbbreviation:@"PDT"];
    [self assert:[timeZone name] equals:@"America/Los_Angeles"];
    [self assert:[timeZone abbreviation] equals:@"PDT"];
    [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
    [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
}

- (void)testTimeZoneWithWrongAbbreviation
{
    var timeZone = [CPTimeZone timeZoneWithAbbreviation:@"PDTezdez"];
    [self assert:timeZone equals:nil];
}

- (void)testInitWithNameSelectsCorrectAbbreviationForDate
{
    // This test verifies the fix for issue #2382.
    // We need to test that initializing a time zone with a name (e.g., 'America/Los_Angeles')
    // and a specific date correctly selects the abbreviation for that date (PST vs. PDT).

    // Let's find the time zone for 'America/Los_Angeles'.
    var pacificTimeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angeles"];
    [self assertTrue:pacificTimeZone !== nil message:@"Time zone for America/Los_Angeles should be found"];

    // A date in winter, when standard time (PST) is active. (e.g., January 15)
    var standardDate = [CPDate dateWithTimeIntervalSinceReferenceDate:474681600]; // Jan 15, 2016
    [self assertTrue:standardDate !== nil message:@"Should be able to create a date in standard time."];

    // A date in summer, when daylight saving time (PDT) is active. (e.g., July 15)
    var daylightDate = [CPDate dateWithTimeIntervalSinceReferenceDate:490219200]; // Jul 15, 2016
    [self assertTrue:daylightDate !== nil message:@"Should be able to create a date in daylight saving time."];

    // Get the abbreviation for the winter date. It should be "PST".
    var standardAbbr = [pacificTimeZone abbreviationForDate:standardDate];
    [self assert:standardAbbr equals:@"PST" message:@"Abbreviation for a date in winter should be PST."];

    // Get the abbreviation for the summer date. It should be "PDT".
    var daylightAbbr = [pacificTimeZone abbreviationForDate:daylightDate];
    [self assert:daylightAbbr equals:@"PDT" message:@"Abbreviation for a date in summer should be PDT."];
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
    var timeZone = [CPTimeZone timeZoneForSecondsFromGMT:(-600 * 60)];
    [self assert:[timeZone name] equals:@"Pacific/Honolulu"];
    [self assert:[timeZone abbreviation] equals:@"HST"];
    [self assert:[timeZone secondsFromGMT] equals:(-600 * 60)];
    [self assert:[timeZone description] equals:@"Pacific/Honolulu (HST) offset -36000"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Hawaii-Aleutian Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"HST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Hawaii-Aleutian Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"HDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Hawaii-Aleutian Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"HST"];
}

- (void)testTimeZoneWithWrongSecondsFromGMT
{
    var timeZone = [CPTimeZone timeZoneForSecondsFromGMT:(-421 * 60)];
    [self assert:timeZone equals:nil];
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

- (void)testAbbreviationWithDate
{
    var timeZone = [CPTimeZone localTimeZone],
        abbreviation = [timeZone abbreviationForDate:_date],
        expected = _date.toLocaleString('en-US', {timeZoneName : 'long'}).replace(/^([0]?\d|[1][0-2])\/((?:[0]?|[1-2])\d|[3][0-1])\/([2][01]|[1][6-9])\d{2}(,?\s*([0]?\d|[1][0-2])(\:[0-5]\d){1,2})*\s*([aApP][mM]{0,2})?\s*/, "").split(" ").map(function(l) { return l[0]}).join("");

    [self assert:abbreviation equals:expected];
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

- (void)testLocalizedName
{
    // This test works because the localized strings for PDT and PST are identical.
    // The abbreviation chosen will depend on when the test is run.
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

@end
