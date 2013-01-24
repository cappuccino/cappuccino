@import <Foundation/CPDate.j>

@implementation CPDateTest : OJTestCase

- (void)testSince1970
{
    /* These two dates should be equal to Fri Jan 13 2009 23:31:30 +0000 */
    var unixDate = [CPDate dateWithTimeIntervalSince1970:1231889490],
        cocoaDate = [CPDate dateWithTimeIntervalSinceReferenceDate:253582290];
    [self assertTrue:[unixDate isEqualToDate:cocoaDate] message:[unixDate description] + " isEqualToDate: " + [cocoaDate description]];
}

- (void)testDistantPast
{
    [self assert:[CPDate dateWithTimeIntervalSinceReferenceDate:-63113817600.0] equals:[CPDate distantPast]];
}

- (void)testDistantFuture
{
    [self assert:[CPDate dateWithTimeIntervalSinceReferenceDate:63113990400.0] equals:[CPDate distantFuture]];
}

- (void)testDate
{
    var before = new Date(),
        middle = [CPDate date],
        after = new Date(),
        future = [CPDate distantFuture],
        past = [CPDate distantPast];

    [self assertTrue:(before <= middle) message:"before not less than middle"];
    [self assertTrue:(middle <= after) message:"middle not less than after (" + middle + "," + after + ")"];

    [self assert:middle equals:[middle earlierDate:future] message:"earlierDate incorrect"];
    [self assert:middle equals:[middle laterDate:past] message:"laterDate incorrect"];
}

- (void)testEquals
{
    var now = [CPDate date];
    [self assert:now equals:now];
    [self assertFalse:[now isEqual:[CPNull null]]];
    [self assertFalse:[now isEqual:nil]];
}

/*!
    [date description] displays time in the current timezone. This test is a crude
    way to validate that this works right for different timezones: just run the test
    with different timezones configured.
*/
- (void)testParseNow
{
    var now = [CPDate new],
        alsoNow = [[CPDate alloc] initWithString:[now description]];

    [self assert:[now description] equals:[alsoNow description]];
}

- (void)testInitWithString
{
    var tests = [
            ["1800-01-01 00:00:00 +0000", -5364662400],
            ["1970-01-01 00:00:00 +0000", 0],
            ["1970-01-01 00:01:00 +0000", 60],
            ["1970-01-01 01:00:00 +0000", 60 * 60],
            ["1970-01-02 00:00:00 +0000", 24 * 60 * 60],
            ["2009-11-17 17:52:04 +0000", 1258480324],
            ["2009-11-17 18:52:04 +0200", 1258476724],
        ];

    for (var i = 0; i < tests.length; i++)
    {
        var parsed = [[CPDate alloc] initWithString:tests[i][0]],
            correctSeconds = tests[i][1];
        [self assert:correctSeconds equals:[parsed timeIntervalSince1970]];
    }
}

- (void)testInitWithTimeIntervalSinceReferenceDate_
{
    // Related issue #1556: "CPDateReferenceDate should be 'Jan 1 2001' instead of 'Feb 1 2001'".
    var referenceDate = [[CPDate alloc] initWithTimeIntervalSinceReferenceDate:0],
        referenceDatePlusOneHour = [[CPDate alloc] initWithTimeIntervalSinceReferenceDate:3600];

    [self assert:[[CPDate alloc] initWithString:@"2001-01-01 00:00:00 +0000"] equals:referenceDate message:@"reference date"];
    [self assert:[[CPDate alloc] initWithString:@"2001-01-01 01:00:00 +0000"] equals:referenceDatePlusOneHour message:@"reference date plus one hour"];
}

- (void)testEncoding
{
    var date = new Date(),
        encodedDate = [CPKeyedArchiver archivedDataWithRootObject:date],
        decodedDate = [CPKeyedUnarchiver unarchiveObjectWithData:encodedDate];

    [self assert:date equals:decodedDate];
}

- (void)testDescription
{
    // Unfortunately the result will be different depending on the testing machine's timezone, so
    // this test turns out to be more complex than the code tested. We can't just reuse the
    // original code as then we'd have exactly the same bugs.
    var date = [CPDate dateWithTimeIntervalSince1970:1234567890],
        expectedDay = 13,
        expectedHour = 23,
        expectedMinute = 31,
        offset = -date.getTimezoneOffset(),
        offsetPositive = offset >= 0,
        offsetHours = offsetPositive ? FLOOR(offset / 60) : CEIL(offset / 60),
        offsetMinutes = offset - offsetHours * 60,
        expectedString;
    expectedHour += offsetHours;
    expectedMinute += offsetMinutes;
    if (expectedMinute < 0)
    {
        expectedMinute += 60;
        expectedHour--;
    }
    else if (expectedMinute > 59)
    {
        expectedMinute -= 60;
        expectedHour++;
    }
    if (expectedHour < 0)
    {
        expectedHour += 24;
        expectedDay--;
    }
    else if (expectedHour > 23)
    {
        expectedHour -= 24;
        expectedDay++;
    }

    if (offsetPositive)
        expectedString = [CPString stringWithFormat:"2009-02-%02d %02d:%02d:30 +%02d%02d", expectedDay, expectedHour, expectedMinute, offsetHours, offsetMinutes];
    else
        expectedString = [CPString stringWithFormat:"2009-02-%02d %02d:%02d:30 -%02d%02d", expectedDay, expectedHour, expectedMinute, ABS(offsetHours), ABS(offsetMinutes)];

    [self assert:expectedString equals: [date description]];

    // Now test that timezone convertion algorithm in CPDate works correctly for
    // different timezones
    [self assert:"+0000" equals:[CPDate timezoneOffsetString:0]];
    [self assert:"-0900" equals:[CPDate timezoneOffsetString:+540]];
    [self assert:"+0300" equals:[CPDate timezoneOffsetString:-180]];
    [self assert:"-0130" equals:[CPDate timezoneOffsetString:+90]];
    [self assert:"+0130" equals:[CPDate timezoneOffsetString:-90]];
}

- (void)testCopy
{
    var original = [[CPDate alloc] initWithString:"2009-11-17 17:52:04 +0000"],
        original2 = [[CPDate alloc] initWithString:"2009-11-17 17:52:04 +0000"],
        copy = [original copy];

    // Now they're the same...
    [self assert:original equals:original2];
    [self assert:copy equals:original2];

    original.setFullYear(2008);
    // Now they better not be.
    [self assert:original notEqual:original2];
    [self assert:copy equals:original2];
}

@end
