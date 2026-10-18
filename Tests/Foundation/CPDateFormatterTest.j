@import <Foundation/Foundation.j>
@import <Foundation/CPDateFormatter.j>
@import <Foundation/CPLocale.j>
@import <Foundation/CPTimeZone.j>

@implementation CPDateFormatterTest : OJTestCase
{
    CPDateFormatter _formatter;
    CPTimeZone      _utcTimeZone;
    CPLocale        _posixLocale;
}

- (void)setUp
{
    _formatter = [[CPDateFormatter alloc] init];

    /*
     * FALLACY: Relying on the host environment's default locale for localized string assertions.
     * FACT: System locales change based on user preference or OS updates.
     * SOLUTION: Enforce an immutable POSIX locale for all deterministic string generation.
     */
    _posixLocale = [[CPLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [_formatter setLocale:_posixLocale];

    /*
     * FALLACY: Assuming named time zones (e.g., "PST" or "America/Los_Angeles") are stable.
     * FACT: Geopolitical entities alter time zone boundaries and DST definitions continually.
     * SOLUTION: Isolate tests using absolute GMT/UTC offsets. Mathematical seconds from GMT do not drift.
     */
    _utcTimeZone = [CPTimeZone timeZoneForSecondsFromGMT:0];
    [_formatter setTimeZone:_utcTimeZone];
}

- (void)testFormatterDeterministicUTCOutput
{
    /*
     * FALLACY: Parsing a string to generate a test date evaluates the formatter fairly.
     * FACT: String parsing introduces external dependencies and compounds parser bugs with formatter bugs.
     * SOLUTION: Initialize dates using absolute epoch seconds. 1,000,000,000 is invariably 2001-09-09 01:46:40 UTC.
     */
    var absoluteDate = [CPDate dateWithTimeIntervalSince1970:1000000000];

    [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    var formattedString = [_formatter stringFromDate:absoluteDate];

    [self assert:formattedString
          equals:@"2001-09-09 01:46:40 +0000"
         message:@"Formatter output must match fixed UTC temporal baseline."];
}

- (void)testFormatterFixedOffsetOutput
{
    // Validate that the formatter accurately shifts absolute time to a localized fixed offset.
    // We apply a strict mathematical offset (-25200 seconds) rather than a named geographical zone.
    var offsetTimeZone = [CPTimeZone timeZoneForSecondsFromGMT:-25200]; // -0700
    [_formatter setTimeZone:offsetTimeZone];
    [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    var absoluteDate = [CPDate dateWithTimeIntervalSince1970:1000000000];
    var formattedString = [_formatter stringFromDate:absoluteDate];

    [self assert:formattedString
          equals:@"2001-09-08 18:46:40 -0700"
         message:@"Formatter output must match fixed offset temporal baseline."];
}

@end
