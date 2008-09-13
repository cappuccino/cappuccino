import <Foundation/CPDate.j>

@implementation CPDateTest : OJTestCase

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