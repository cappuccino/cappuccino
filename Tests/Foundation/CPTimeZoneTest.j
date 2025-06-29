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
    var originalDateClassMethod = CPDate.date;

    try
    {
        // Test 1: Date is during Daylight Saving Time (e.g., July in Northern Hemisphere for "America/Los_Angeles")
        var summerDate = [[CPDate alloc] initWithString:@"2022-07-01 12:00:00 +0000"];
        CPDate.date = function() { return summerDate; };

        // Test instance method init
        var timeZonePDT = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles" data:_data];
        [self assertNotNil:timeZonePDT message:"Time zone should not be nil for a valid name."];
        [self assert:[timeZonePDT abbreviation] equals:@"PDT" message:"Abbreviation should be PDT during summer"];
        [self assert:[timeZonePDT secondsFromGMT] equals:(-420 * 60) message:"Seconds from GMT should be correct for PDT"];
        [self assert:[timeZonePDT description] equals:@"America/Los_Angeles (PDT) offset -25200" message:"Description should be correct for PDT"];
        [self assert:[timeZonePDT data] equals:_data message:@"Data should be correctly associated with time zone"];

        // Test class method factory
        var timeZonePDTClass = [CPTimeZone timeZoneWithName:@"America/Los_Angeles"];
        [self assert:[timeZonePDTClass abbreviation] equals:@"PDT" message:"Class method should return zone with PDT abbreviation during summer"];


        // Test 2: Date is during Standard Time (e.g., January)
        var winterDate = [[CPDate alloc] initWithString:@"2022-01-01 12:00:00 +0000"];
        CPDate.date = function() { return winterDate; };

        // Test instance method init
        var timeZonePST = [[CPTimeZone alloc] initWithName:@"America/Los_Angeles" data:_data];
        [self assertNotNil:timeZonePST message:"Time zone should not be nil for a valid name."];
        [self assert:[timeZonePST abbreviation] equals:@"PST" message:"Abbreviation should be PST during winter"];
        [self assert:[timeZonePST secondsFromGMT] equals:(-480 * 60) message:"Seconds from GMT should be correct for PST"];
        [self assert:[timeZonePST description] equals:@"America/Los_Angeles (PST) offset -28800" message:"Description should be correct for PST"];
        [self assert:[timeZonePST data] equals:_data message:"Data should be correctly associated with time zone"];

        // Test class method factory
        var timeZonePSTClass = [CPTimeZone timeZoneWithName:@"America/Los_Angeles"];
        [self assert:[timeZonePSTClass abbreviation] equals:@"PST" message:"Class method should return zone with PST abbreviation during winter"];
    }
    finally
    {
        // Restore the original class method to avoid side-effects in other tests
        CPDate.date = originalDateClassMethod;
    }
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
