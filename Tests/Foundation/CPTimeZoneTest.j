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

- (void)testTimeZoneWithName
{
    var timeZone = [CPTimeZone timeZoneWithName:@"America/Los_Angeles"];

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PDT"];
        [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    } else {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PST"];
        [self assert:[timeZone secondsFromGMT] equals:(-480 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PST) offset -28800"];
    }
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
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

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PDT"];
        [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    } else {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PST"];
        [self assert:[timeZone secondsFromGMT] equals:(-480 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PST) offset -28800"];
    }
    [self assert:[timeZone data] equals:_data];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
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

- (void)testInitTimeZoneWithName
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PDT"];
        [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    } else {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PST"];
        [self assert:[timeZone secondsFromGMT] equals:(-480 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PST) offset -28800"];
    }
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
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

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PDT"];
        [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    } else {
        [self assert:[timeZone name] equals:@"America/Los_Angeles"];
        [self assert:[timeZone abbreviation] equals:@"PST"];
        [self assert:[timeZone secondsFromGMT] equals:(-480 * 60)];
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PST) offset -28800"];
    }
    [self assert:[timeZone data] equals:_data];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleStandard locale:_locale] equals:@"Pacific Standard Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortStandard locale:_locale] equals:@"PST"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleDaylightSaving locale:_locale] equals:@"Pacific Daylight Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortDaylightSaving locale:_locale] equals:@"PDT"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleGeneric locale:_locale] equals:@"Pacific Time"];
    [self assert:[timeZone localizedName:CPTimeZoneNameStyleShortGeneric locale:_locale] equals:@"PT"];
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

- (void)testSecondsFromGMT
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone secondsFromGMT] equals:(-420 * 60)];
    } else {
        [self assert:[timeZone secondsFromGMT] equals:(-480 * 60)];
    }
}

- (void)testDescription
{
    var timeZone = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles"];

    // The current implementation can return daylight saving time or standard time depending on the current implmentation on CPDictionary
    if ([timeZone abbreviation] === @"PDT") {
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PDT) offset -25200"];
    } else {
        [self assert:[timeZone description] equals:@"America/Los_Angeles (PST) offset -28800"];
    }
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
    // This test verifies that initWithName: correctly selects the abbreviation
    // (e.g., PST vs. PDT) based on the current date's daylight saving status.

    // 1. Test a time zone that observes DST, like America/Los_Angeles.
    var laTimeZoneName = @"America/Los_Angeles";
    var expectedAbbreviationLA;

    try {
        // This logic mimics the _abbreviationForNameAndDate helper function in CPTimeZone.j
        var options = { timeZone: laTimeZoneName, timeZoneName: 'long' };
        var dateString = (new Date()).toLocaleString('en-US', options);
        var longTZName = dateString.replace(/^([0]?\d|[1][0-2])\/((?:[0]?|[1-2])\d|[3][0-1])\/([2][01]|[1][6-9])\d{2}(,?\s*([0]?\d|[1][0-2])(\:[0-5]\d){1,2})*\s*([aApP][mM]{0,2})?\s*/, "");
        expectedAbbreviationLA = longTZName.split(" ").map(function(l) { return l[0]}).join("");
    } catch (e) {
        [self fail:"Could not determine expected abbreviation for America/Los_Angeles"];
        return;
    }

    var timeZoneLA = [[CPTimeZone alloc] initWithName:laTimeZoneName];

    if (timeZoneLA == nil)
        [self fail:"Time zone for America/Los_Angeles should be created successfully."];

    [self assert:[timeZoneLA abbreviation] equals:expectedAbbreviationLA];

    // 2. Test a time zone that does not observe DST, like Pacific/Honolulu.
    var hnlTimeZoneName = @"Pacific/Honolulu";
    var timeZoneHNL = [[CPTimeZone alloc] initWithName:hnlTimeZoneName];

    if (timeZoneHNL == nil)
        [self fail:"Time zone for Pacific/Honolulu should be created successfully."];

    // For a non-DST zone, the abbreviation is constant.
    [self assert:[timeZoneHNL abbreviation] equals:@"HST"];
}

@end
