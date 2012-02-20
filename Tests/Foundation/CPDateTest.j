@import <Foundation/CPDate.j>

@implementation CPDateTest : OJTestCase

- (void)testSince1970
{
    /* These two dates should be equal to Fri Feb 13 2009 15:31:30 GMT-0800 */
    unixDate = [CPDate dateWithTimeIntervalSince1970: 1234567890];
    cocoaDate = [CPDate dateWithTimeIntervalSinceReferenceDate: 253582290];
    [self assertTrue:[unixDate isEqualToDate: cocoaDate]];
}

- (void)testDate
{
    var before = new Date();
    var middle = [CPDate date];
    var after = new Date();
    var future = [CPDate distantFuture];
    var past = [CPDate distantPast];

    [self assertTrue:(before <= middle) message:"before not less than middle"];
    [self assertTrue:(middle <= after) message:"middle not less than after ("+middle+","+after+")"];

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

- (void)testInitWithString
{
    var tests = [
        ["1970-01-01 00:00:00 +0000", 0],
        ["1970-01-01 00:01:00 +0000", 60],
        ["1970-01-01 01:00:00 +0000", 60*60],
        ["1970-01-02 00:00:00 +0000", 24*60*60],
        ["2009-11-17 17:52:04 +0000", 1258480324],
    ];

    for (var i = 0; i < tests.length; i++)
    {
        var parsed = [[CPDate alloc] initWithString:tests[i][0]];
        var correctSeconds = tests[i][1];
        [self assert:correctSeconds equals:[parsed timeIntervalSince1970]];
    }
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
    var date = [CPDate dateWithTimeIntervalSince1970: 1234567890],
        expectedDay = 13,
        expectedHour = 23,
        expectedMinute = 31,
        offsetPositive = date.getTimezoneOffset() >= 0,
        offsetHours = Math.floor(date.getTimezoneOffset() / 60),
        offsetMinutes = date.getTimezoneOffset() - offsetHours * 60,
        expectedString;
    expectedHour -= offsetHours;
    expectedMinute -= offsetMinutes;
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
