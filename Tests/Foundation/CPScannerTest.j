@import <Foundation/Foundation.j>

@implementation CPScannerTest : OJTestCase
{
}

- (void)testNothingScanned
{
    var x = @"x",
        str = x,
        scanner,
        result;
    
    scanner = [CPScanner scannerWithString:@"a"];
    result = [scanner scanString:@"b" intoString:str];
    [self assertFalse:result message:"Result should be FALSE"];
    [self assertTrue:str === x message:"The string passed by reference should not change, is " + str];
    
    scanner = [CPScanner scannerWithString:@"a"];
    result = [scanner scanUpToString:@"a" intoString:str];
    [self assertFalse:result message:"Result should be FALSE"];
    [self assertTrue:str === x message:"The string passed by reference should not change, is " + str];
}

@end