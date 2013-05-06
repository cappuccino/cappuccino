/* CPDateFormatterTest.j
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

@import <Foundation/CPDateFormatter.j>
@import <Foundation/CPLocale.j>
@import <Foundation/CPDate.j>

@import <OJUnit/OJTestCase.j>

@global CPDateFormatterNoStyle
@global CPDateFormatterShortStyle
@global CPDateFormatterMediumStyle
@global CPDateFormatterLongStyle
@global CPDateFormatterFullStyle

@implementation CPDateFormatterTest : OJTestCase
{
    CPDate _date;
    CPDateFormatter _dateFormatter;
}

- (void)setUp
{
    _date = [[CPDate alloc] initWithString:@"2011-10-05 16:34:38 -0900"];
    _dateFormatter = [[CPDateFormatter alloc] init];
    [_dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterShortStyle];
    [_dateFormatter setLocale:[[CPLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [_dateFormatter setTimeZone:[CPTimeZone timeZoneWithAbbreviation:@"PDT"]];
}


#pragma mark -
#pragma mark Setter

- (void)testSetterAMSymbol
{
    [_dateFormatter setAMSymbol:@"Hej hej"];
    [self assert:[_dateFormatter AMSymbol] equals:@"Hej hej"];
}

- (void)testSetterPMSymbol
{
    [_dateFormatter setPMSymbol:@"Hej hej"];
    [self assert:[_dateFormatter PMSymbol] equals:@"Hej hej"];
}

- (void)testSetterWeekdaySymbols
{
    [_dateFormatter setWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter weekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortWeekdaySymbols
{
    [_dateFormatter setShortWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortWeekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterVeryShortWeekdaySymbols
{
    [_dateFormatter setVeryShortWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter veryShortWeekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterStandaloneWeekdaySymbols
{
    [_dateFormatter setStandaloneWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter standaloneWeekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortStandaloneWeekdaySymbols
{
    [_dateFormatter setShortStandaloneWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortStandaloneWeekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterVeryShortStandaloneWeekdaySymbols
{
    [_dateFormatter setVeryShortStandaloneWeekdaySymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter veryShortStandaloneWeekdaySymbols] equals:[@"Hej hej"]];
}

- (void)testSetterMonthSymbols
{
    [_dateFormatter setMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter monthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortMonthSymbols
{
    [_dateFormatter setShortMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortMonthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterVeryShortMonthSymbols
{
    [_dateFormatter setVeryShortMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter veryShortMonthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterStandaloneMonthSymbols
{
    [_dateFormatter setStandaloneMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter standaloneMonthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortStandaloneMonthSymbols
{
    [_dateFormatter setShortStandaloneMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortStandaloneMonthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterVeryShortStandaloneMonthSymbols
{
    [_dateFormatter setVeryShortStandaloneMonthSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter veryShortStandaloneMonthSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterQuarterSymbols
{
    [_dateFormatter setQuarterSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter quarterSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortQuarterSymbols
{
    [_dateFormatter setShortQuarterSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortQuarterSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterStandaloneQuarterSymbols
{
    [_dateFormatter setStandaloneQuarterSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter standaloneQuarterSymbols] equals:[@"Hej hej"]];
}

- (void)testSetterShortStandaloneQuarterSymbols
{
    [_dateFormatter setShortStandaloneQuarterSymbols:[@"Hej hej"]];
    [self assert:[_dateFormatter shortStandaloneQuarterSymbols] equals:[@"Hej hej"]];
}

#pragma mark -
#pragma mark string from date

- (void)testLocalizedStringFromDate
{
    var result = [CPDateFormatter localizedStringFromDate:[[CPDate alloc] initWithString:@"2011-10-05 23:59:59 +1200"] dateStyle:CPDateFormatterMediumStyle timeStyle:CPDateFormatterNoStyle];

    if (![[[CPLocale currentLocale] objectForKey:CPLocaleCountryCode] isEqualToString:@"US"])
        [self assert:result equals:@"5 Oct 2011"];
    else
        [self assert:result equals:@"Oct 5, 2011"];
}

- (void)testInit
{
    var dateFormatter = [[CPDateFormatter alloc] init],
        result = [dateFormatter stringFromDate:_date];

    [self assert:result.length equals:@"".length];
}

- (void)testInitWithDateFormat
{
    var dateFormatter = [[CPDateFormatter alloc] initWithDateFormat:@"d EEEE, MMM, Y 'at' H:mm:ss a z" allowNaturalLanguage:NO];
    [dateFormatter setLocale:[[CPLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setTimeZone:[CPTimeZone timeZoneWithAbbreviation:@"PDT"]];

    var result = [dateFormatter stringFromDate:_date];

    [self assert:result equals:@"5 Wednesday, Oct, 2011 at 18:34:38 PM PDT"]
}

- (void)testStringFromDateDateNoStyleTimeNoStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterNoStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result.length equals:@"".length];
}

- (void)testStringFromDateDateShortStyleTimeNoStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterShortStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"10/5/11"];
}

- (void)testStringFromDateDateMediumStyleTimeNoStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"Oct 5, 2011"];
}

- (void)testStringFromDateDateLongStyleTimeNoStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterLongStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"October 5, 2011"];
}

- (void)testStringFromDateDateFullStyleTimeNoStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterFullStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"Wednesday, October 5, 2011"];
}

- (void)testStringFromDateDateNoStyleTimeShortStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterNoStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterShortStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"6:34 PM"];
}

- (void)testStringFromDateDateNoStyleTimeMediumStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterNoStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterMediumStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"6:34:38 PM"];
}

- (void)testStringFromDateDateNoStyleTimeLongStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterNoStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterLongStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"6:34:38 PM PDT"];
}

- (void)testStringFromDateDateNoStyleTimeFullStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterNoStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterFullStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"6:34:38 PM Pacific Daylight Time"];
}

- (void)testStringFromDateDateFullStyleTimeFullStyle
{
    [_dateFormatter setDateStyle:CPDateFormatterFullStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterFullStyle];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"Wednesday, October 5, 2011 6:34:38 PM Pacific Daylight Time"];
}

- (void)testStringForObjectValueWithDate
{
    [_dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterShortStyle];

    var result = [_dateFormatter stringForObjectValue:_date];
    [self assert:result equals:@"Oct 5, 2011 6:34 PM"];
}

- (void)testStringForObjectValueWithString
{
    [_dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterShortStyle];

    var result = [_dateFormatter stringForObjectValue:@"Test String"];
    [self assert:result equals:nil];
}

- (void)testEditingStringForObjectValueWithDate
{
    [_dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:CPDateFormatterShortStyle];

    var result = [_dateFormatter editingStringForObjectValue:_date];
    [self assert:result equals:@"Oct 5, 2011 6:34 PM"];
}

- (void)testDoesRelativeDateFormatting
{
    [_dateFormatter setTimeStyle:CPDateFormatterNoStyle];
    [_dateFormatter setDoesRelativeDateFormatting:YES];

    var date = [CPDate date];
    date.setDate(date.getDate() + 1);

    var result = [_dateFormatter editingStringForObjectValue:date];
    [self assert:result equals:@"tomorrow"];

    date.setDate(date.getDate() - 2);

    result = [_dateFormatter editingStringForObjectValue:date];
    [self assert:result equals:@"yesterday"];
}

- (void)testStringFromDateTokensYears
{
    [_dateFormatter setDateFormat:@"y yy yyy yyyy Y YY YYY YYYY"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"2011 11 2011 2011 2011 11 2011 2011"];
}

- (void)testStringFromDateTokensQuarters
{
    [_dateFormatter setDateFormat:@"Q QQ QQQ QQQQ q qq qqq qqqq"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"4 04 Q4 4th quarter 4 04 Q4 4th quarter"];
}

- (void)testStringFromDateTokensMonths
{
    [_dateFormatter setDateFormat:@"M MM MMM MMMM MMMMM L LL LLL LLLL LLLLL"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"10 10 Oct October O 10 10 Oct October O"];
}

- (void)testStringFromDateTokensWeeks
{
    [_dateFormatter setDateFormat:@"w ww W"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"41 41 2"];
}

- (void)testStringFromDateTokensDays
{
    [_dateFormatter setDateFormat:@"d dd D DD DDD F"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"5 05 278 278 278 1"];
}

- (void)testStringFromDateTokensWeekDays
{
    [_dateFormatter setDateFormat:@"E EE EEE EEEE EEEEE e ee eee eeee eeeee c cc ccc cccc ccccc"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"Wed Wed Wed Wednesday W 4 04 Wed Wednesday W 4 4 Wed Wednesday W"];
}

- (void)testStringFromDateTokensPeriods
{
    [_dateFormatter setDateFormat:@"a"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"PM"];

    _date = [[CPDate alloc] initWithString:@"2011-10-05 05:34:38 -0900"];

    var result = [_dateFormatter stringFromDate:_date];
    [self assert:result equals:@"AM"];
}

- (void)testStringFromDateTokensSeconds
{
    [_dateFormatter setDateFormat:@"s ss S SS SSS SSSS A AA AAA AAAA"];
    _date.setSeconds(8);

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"8 08 0 00 000 0000 66848000 66848000 66848000 66848000"];
}

- (void)testStringFromDateTokensMinutes
{
    [_dateFormatter setDateFormat:@"m mm"];
    _date.setMinutes(5);

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"5 05"];
}

- (void)testStringFromDateTokensHours
{
    var date = [[CPDate alloc] initWithString:@"2011-10-05 22:34:08 -0900"];

    [_dateFormatter setDateFormat:@"h hh HH k kk K KK"];
    var result = [_dateFormatter stringFromDate:date];
    [self assert:result equals:@"12 12 00 24 24 0 00"];

    date = [[CPDate alloc] initWithString:@"2011-10-05 06:34:08 -0900"];
    [_dateFormatter setDateFormat:@"h hh HH k kk K KK"];
    result = [_dateFormatter stringFromDate:date];
    [self assert:result equals:@"8 08 08 8 08 8 08"];

    date = [[CPDate alloc] initWithString:@"2011-10-05 16:34:08 -0900"];
    [_dateFormatter setDateFormat:@"h hh HH k kk K KK"];
    var result = [_dateFormatter stringFromDate:date];
    [self assert:result equals:@"6 06 18 18 18 6 06"];
}

- (void)testStringFromDateTokensZones
{
    [_dateFormatter setDateFormat:@"z zz zzz zzzz Z ZZ ZZZ ZZZZ ZZZZ v vvvv V"];

    var result = [_dateFormatter stringFromDate:_date];

    [self assert:result equals:@"PDT PDT PDT Pacific Daylight Time -0700 -0700 -0700 GMT-07:00 GMT-07:00 PT Pacific Time PDT"];
}


#pragma mark -
#pragma mark Date From string

- (void)testDateFromStringToken
{
    [_dateFormatter setDateFormat:@""];
    var result = [_dateFormatter dateFromString:@""];

    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]] equals:YES];
}

- (void)testDateFromStringTokeny
{
    [_dateFormatter setDateFormat:@"y"];
    var result = [_dateFormatter dateFromString:@"9"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"0009-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"yy"];
    result = [_dateFormatter dateFromString:@"49"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"2049-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"yy"];
    result = [_dateFormatter dateFromString:@"56"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"1956-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"yy"];
    result = [_dateFormatter dateFromString:@"563"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"0563-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"yyy"];
    result = [_dateFormatter dateFromString:@"563"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"0563-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"yyyy"];
    result = [_dateFormatter dateFromString:@"2012"];
    [self assert:[result isEqualToDate:[[CPDate alloc] initWithString:@"2012-01-01 08:00:00 +0000"]] equals:YES];

    [_dateFormatter setDateFormat:@"y"];
    var result = [_dateFormatter dateFromString:@"eze"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"yy"];
    result = [_dateFormatter dateFromString:@"dezd"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"yyy"];
    result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"yyyy"];
    result = [_dateFormatter dateFromString:@"dezdezd"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenY
{
    [_dateFormatter setDateFormat:@"Y"];
    var result = [_dateFormatter dateFromString:@"9"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"0009-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"YY"];
    result = [_dateFormatter dateFromString:@"49"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2049-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"YY"];
    result = [_dateFormatter dateFromString:@"56"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"1956-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"YY"];
    result = [_dateFormatter dateFromString:@"563"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"0563-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"YYY"];
    result = [_dateFormatter dateFromString:@"563"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"0563-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"YYYY"];
    result = [_dateFormatter dateFromString:@"2012"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2012-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"Y"];
    var result = [_dateFormatter dateFromString:@"eze"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"YY"];
    result = [_dateFormatter dateFromString:@"dezd"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"YYY"];
    result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"YYYY"];
    result = [_dateFormatter dateFromString:@"dezdezd"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenq
{
    [_dateFormatter setDateFormat:@"q"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"qq"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"qqq"];
    var result = [_dateFormatter dateFromString:@"Q3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"qqqq"];
    var result = [_dateFormatter dateFromString:@"2nd quarter"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"q"];
    var result = [_dateFormatter dateFromString:@"12"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"q"];
    var result = [_dateFormatter dateFromString:@"eze"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"qq"];
    var result = [_dateFormatter dateFromString:@"12"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"qq"];
    var result = [_dateFormatter dateFromString:@"zaz"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"qqq"];
    var result = [_dateFormatter dateFromString:@"Q8"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"qqqq"];
    var result = [_dateFormatter dateFromString:@"2nd quarteer"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenQ
{
    [_dateFormatter setDateFormat:@"Q"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"QQ"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"QQQ"];
    var result = [_dateFormatter dateFromString:@"Q3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"QQQQ"];
    var result = [_dateFormatter dateFromString:@"2nd quarter"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-04-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"Q"];
    var result = [_dateFormatter dateFromString:@"12"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"Q"];
    var result = [_dateFormatter dateFromString:@"ezeze"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"QQ"];
    var result = [_dateFormatter dateFromString:@"12"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"QQ"];
    var result = [_dateFormatter dateFromString:@"zazasz"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"QQQ"];
    var result = [_dateFormatter dateFromString:@"Q6"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"QQQQ"];
    var result = [_dateFormatter dateFromString:@"2nd quarteereze"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenM
{
    [_dateFormatter setDateFormat:@"M"];
    var result = [_dateFormatter dateFromString:@"10"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-10-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"MM"];
    var result = [_dateFormatter dateFromString:@"7"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"MMM"];
    var result = [_dateFormatter dateFromString:@"Sep"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-09-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"MMMM"];
    var result = [_dateFormatter dateFromString:@"September"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-09-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"MMMMM"];
    var result = [_dateFormatter dateFromString:@"S"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"M"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"M"];
    var result = [_dateFormatter dateFromString:@"ezeze"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"MM"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"MM"];
    var result = [_dateFormatter dateFromString:@"zdazdza"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"MMM"];
    var result = [_dateFormatter dateFromString:@"Seepre"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"MMMM"];
    var result = [_dateFormatter dateFromString:@"Septembeer"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenL
{
    [_dateFormatter setDateFormat:@"L"];
    var result = [_dateFormatter dateFromString:@"10"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-10-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"LL"];
    var result = [_dateFormatter dateFromString:@"7"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"LLL"];
    var result = [_dateFormatter dateFromString:@"Sep"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-09-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"LLLL"];
    var result = [_dateFormatter dateFromString:@"September"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-09-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"LLLLL"];
    var result = [_dateFormatter dateFromString:@"S"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"L"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"L"];
    var result = [_dateFormatter dateFromString:@"dzadza"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"LL"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"LL"];
    var result = [_dateFormatter dateFromString:@"dzadza"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"LLL"];
    var result = [_dateFormatter dateFromString:@"Seepre"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"LLLL"];
    var result = [_dateFormatter dateFromString:@"Septemberezd"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenw
{
    [_dateFormatter setDateFormat:@"w"];
    var result = [_dateFormatter dateFromString:@"26"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-06-24 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"w"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"w"];
    var result = [_dateFormatter dateFromString:@"dzadza"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenW
{
    [_dateFormatter setDateFormat:@"W"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-08 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"W LL"];
    var result = [_dateFormatter dateFromString:@"2 7"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-08 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"W"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"W"];
    var result = [_dateFormatter dateFromString:@"dzadzad"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokend
{
    [_dateFormatter setDateFormat:@"d"];
    var result = [_dateFormatter dateFromString:@"6"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-06 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"dd"];
    var result = [_dateFormatter dateFromString:@"16"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-16 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"d LL"];
    var result = [_dateFormatter dateFromString:@"6 7"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-07-06 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"ddd"];
    var result = [_dateFormatter dateFromString:@"6"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-06 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"ddd"];
    var result = [_dateFormatter dateFromString:@"62"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"ddd"];
    var result = [_dateFormatter dateFromString:@"dzadza"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenD
{
    [_dateFormatter setDateFormat:@"D"];
    var result = [_dateFormatter dateFromString:@"76"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-03-16 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"D"];
    var result = [_dateFormatter dateFromString:@"1076"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"D"];
    var result = [_dateFormatter dateFromString:@"dzeezd"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenF
{
    [_dateFormatter setDateFormat:@"F"];
    var result = [_dateFormatter dateFromString:@"2"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-08 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"F"];
    var result = [_dateFormatter dateFromString:@"23"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"F"];
    var result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenE
{
    // No logic in cocoa (or I didn't get it :/)
    [_dateFormatter setDateFormat:@"EEE"];
    var result = [_dateFormatter dateFromString:@"Tue"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"EEEE"];
    var result = [_dateFormatter dateFromString:@"Tuesday"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"EEEEE"];
    var result = [_dateFormatter dateFromString:@"T"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"EEE"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"EEEE"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokene
{
    // No logic in cocoa (or I didn't get it :/)
    [_dateFormatter setDateFormat:@"ee"];
    var result = [_dateFormatter dateFromString:@"1"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"eee"];
    var result = [_dateFormatter dateFromString:@"Tue"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"eeee"];
    var result = [_dateFormatter dateFromString:@"Tuesday"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"eeeee"];
    var result = [_dateFormatter dateFromString:@"T"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"ee"];
    var result = [_dateFormatter dateFromString:@"frefre"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"eee"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"eeee"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenc
{
    // No logic in cocoa (or I didn't get it :/)
    [_dateFormatter setDateFormat:@"cc"];
    var result = [_dateFormatter dateFromString:@"1"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"ccc"];
    var result = [_dateFormatter dateFromString:@"Tue"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"cccc"];
    var result = [_dateFormatter dateFromString:@"Tuesday"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"ccccc"];
    var result = [_dateFormatter dateFromString:@"T"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"cc"];
    var result = [_dateFormatter dateFromString:@"dezde"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"ccc"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"cccc"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokena
{
    [_dateFormatter setDateFormat:@"a"];
    var result = [_dateFormatter dateFromString:@"PM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 20:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"a"];
    var result = [_dateFormatter dateFromString:@"AM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"a"];
    var result = [_dateFormatter dateFromString:@"PdM"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenh
{
    [_dateFormatter setDateFormat:@"h"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 19:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh"];
    var result = [_dateFormatter dateFromString:@"3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh"];
    var result = [_dateFormatter dateFromString:@"0"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh a"];
    var result = [_dateFormatter dateFromString:@"3 PM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 23:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh a"];
    var result = [_dateFormatter dateFromString:@"3 AM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh"];
    var result = [_dateFormatter dateFromString:@"13"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"hh"];
    var result = [_dateFormatter dateFromString:@"edze"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenH
{
    [_dateFormatter setDateFormat:@"H"];
    var result = [_dateFormatter dateFromString:@"18"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-02 02:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"HH"];
    var result = [_dateFormatter dateFromString:@"3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"HH a"];
    var result = [_dateFormatter dateFromString:@"2 PM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 22:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"HH"];
    var result = [_dateFormatter dateFromString:@"24"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"HH"];
    var result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenK
{
    [_dateFormatter setDateFormat:@"K"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 19:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"KK"];
    var result = [_dateFormatter dateFromString:@"3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"KK"];
    var result = [_dateFormatter dateFromString:@"0"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"KK a"];
    var result = [_dateFormatter dateFromString:@"3 PM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 23:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"KK a"];
    var result = [_dateFormatter dateFromString:@"3 AM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"KK"];
    var result = [_dateFormatter dateFromString:@"13"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"KK"];
    var result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenk
{
    [_dateFormatter setDateFormat:@"k"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 19:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"kk"];
    var result = [_dateFormatter dateFromString:@"3"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 11:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"kk"];
    var result = [_dateFormatter dateFromString:@"0"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"kk a"];
    var result = [_dateFormatter dateFromString:@"3 PM"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 23:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"kk"];
    var result = [_dateFormatter dateFromString:@"13"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"kk"];
    var result = [_dateFormatter dateFromString:@"dezdezd"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenm
{
    [_dateFormatter setDateFormat:@"m"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:11:00 +0000"]];

    [_dateFormatter setDateFormat:@"mm"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:11:00 +0000"]]

    [_dateFormatter setDateFormat:@"mm"];
    var result = [_dateFormatter dateFromString:@"61"];
    [self assert:result equals:nil]

    [_dateFormatter setDateFormat:@"mm"];
    var result = [_dateFormatter dateFromString:@"ezdezd"];
    [self assert:result equals:nil]
}

- (void)testDateFromStringTokens
{
    [_dateFormatter setDateFormat:@"s"];
    var result = [_dateFormatter dateFromString:@"11"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:11 +0000"]];

    [_dateFormatter setDateFormat:@"ss"];
    var result = [_dateFormatter dateFromString:@"4"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:04 +0000"]]

    [_dateFormatter setDateFormat:@"ss"];
    var result = [_dateFormatter dateFromString:@"64"];
    [self assert:result equals:nil]

    [_dateFormatter setDateFormat:@"ss"];
    var result = [_dateFormatter dateFromString:@"dezdez"];
    [self assert:result equals:nil]
}

- (void)testDateFromStringTokenS
{
    // No logic in cocoa (or I didn't get it :/)
    [_dateFormatter setDateFormat:@"SSS"];
    var result = [_dateFormatter dateFromString:@"21212"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 08:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"SSS"];
    var result = [_dateFormatter dateFromString:@"rer"];
    [self assert:result equals:nil];
}

- (void)testDateFromStringTokenA
{
    [_dateFormatter setDateFormat:@"AAAAAAAA"];
    var result = [_dateFormatter dateFromString:@"69540000"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-02 03:19:00 +0000"]];

    [_dateFormatter setDateFormat:@"AAAAAAAA"];
    var result = [_dateFormatter dateFromString:@"ezde"];
    [self assert:result equals:nil];
}

- (void)testDataFromStringTokenz
{
    [_dateFormatter setDateFormat:@"hh zzz"];
    var result = [_dateFormatter dateFromString:@"10 PDT"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 17:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh zzzz"];
    var result = [_dateFormatter dateFromString:@"10 GMT+08:35"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 01:25:00 +0000"]];

    [_dateFormatter setDateFormat:@"zzz"];
    var result = [_dateFormatter dateFromString:@"PezST"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"zzzz"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}

- (void)testDataFromStringTokenZ
{
    [_dateFormatter setDateFormat:@"hh ZZZ"];
    var result = [_dateFormatter dateFromString:@"10 -0600"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 16:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh ZZZZ"];
    var result = [_dateFormatter dateFromString:@"10 GMT-05:00"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 15:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh ZZZZZ"];
    var result = [_dateFormatter dateFromString:@"10 +04:00"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 06:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"ZZZ"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"ZZZZ"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"ZZZZZ"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}
//
- (void)testDataFromStringTokenv
{
    [_dateFormatter setDateFormat:@"hh v"];
    var result = [_dateFormatter dateFromString:@"02 PT"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 10:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh vvvv"];
    var result = [_dateFormatter dateFromString:@"8 GMT-08:35"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 16:35:00 +0000"]];

    [_dateFormatter setDateFormat:@"v"];
    var result = [_dateFormatter dateFromString:@"PezST"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"vvvv"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];

}

- (void)testDataFromStringTokenV
{
    [_dateFormatter setDateFormat:@"hh V"];
    var result = [_dateFormatter dateFromString:@"6 PST"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"2000-01-01 14:00:00 +0000"]];

    [_dateFormatter setDateFormat:@"hh VVVV"];
    var result = [_dateFormatter dateFromString:@"6 GMT+06:35"];
    [self assert:result equals:[[CPDate alloc] initWithString:@"1999-12-31 23:25:00 +0000"]];

    [_dateFormatter setDateFormat:@"V"];
    var result = [_dateFormatter dateFromString:@"PezST"];
    [self assert:result equals:nil];

    [_dateFormatter setDateFormat:@"VVVV"];
    var result = [_dateFormatter dateFromString:@"dehez"];
    [self assert:result equals:nil];
}

- (void)testGetObjectValueReturnYes
{
    [_dateFormatter setDateFormat:@"d mm"];

    var date = nil,
        error = @"",
        result = [_dateFormatter getObjectValue:@ref(date) forString:@"10 12" errorDescription:@ref(error)];

    [self assert:result equals:YES];
    [self assert:date equals:[[CPDate alloc] initWithString:@"2000-01-10 08:12:00 +0000"]];
    [self assert:error equals:@""];
}

- (void)testGetObjectValueReturnNo
{
    [_dateFormatter setDateFormat:@"d mm"];

    var date = nil,
        error = @"",
        result = [_dateFormatter getObjectValue:@ref(date) forString:@"ezr 12" errorDescription:@ref(error)];

    [self assert:result equals:NO];
    [self assert:date equals:nil];
    [self assert:error equals:@"The value \"ezr 12\" is invalid."];
}

@end
