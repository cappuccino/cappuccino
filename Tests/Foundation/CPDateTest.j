import <Foundation/CPDate.j>

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

@end
