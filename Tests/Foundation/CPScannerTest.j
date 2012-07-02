
@import <Foundation/CPScanner.j>

@implementation CPScannerTest : OJTestCase

- (void)performScanMethod:(SEL)selector searchFor:(id)search inScanner:(CPString)scanner succeeded:(BOOL)success found:/*accumulated result or nil if nothing should be accumulated*/(id)accumulator endedAt:(int)endLocation
{
    if ([scanner isKindOfClass:[CPString class]])
        scanner = [CPScanner scannerWithString:scanner];
        
    var objj_args = [scanner, selector],
        value = @"initialValue";

    if (accumulator == nil)
        accumulator = value;

    if (search != nil)
        objj_args.push(search);

    objj_args.push(function(v){value = v;});

    var didScan = objj_msgSend.apply(this, objj_args);

    [self assert:success equals:didScan message:scanner + " Scan operation: "];
    [self assert:accumulator equals:value message:scanner + " Accumulator: "];
    if (endLocation != nil)
        [self assert:endLocation equals:[scanner scanLocation] message:scanner + " Scan location: "];
}

- (void)testScanInt
{
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@"1" succeeded:YES found:1 endedAt:1];
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@" 12" succeeded:YES found:12 endedAt:3];
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@"01" succeeded:YES found:1 endedAt:2];
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@"131F02" succeeded:YES found:131 endedAt:3];
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@"word" succeeded:NO found:nil endedAt:0];
    [self performScanMethod:@selector(scanInt:) searchFor:nil inScanner:@"0S" succeeded:YES found:0 endedAt:1];
}

- (void)testScanFloat
{
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"1" succeeded:YES found:1 endedAt:1];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"1.2" succeeded:YES found:1.2 endedAt:3];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"-1.2" succeeded:YES found:-1.2 endedAt:4];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"1.2x" succeeded:YES found:1.2 endedAt:3];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"word" succeeded:NO found:nil endedAt:0];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"0.00" succeeded:YES found:0 endedAt:4];

// wrong end location
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@".1-2" succeeded:YES found:0.1 endedAt:nil];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"1.2.3" succeeded:YES found:1.2 endedAt:nil];
    [self performScanMethod:@selector(scanFloat:) searchFor:nil inScanner:@"-1.2-3" succeeded:YES found:-1.2 endedAt:nil];
}

- (void)testScanString
{
    [self performScanMethod:@selector(scanString:intoString:) searchFor:@"t" inScanner:@"topaz" succeeded:YES found:@"t" endedAt:1];
    [self performScanMethod:@selector(scanString:intoString:) searchFor:@"z" inScanner:@"topaz" succeeded:NO found:nil endedAt:0];
    [self performScanMethod:@selector(scanString:intoString:) searchFor:@"tt" inScanner:@"topaz" succeeded:NO found:nil endedAt:0];

    [self performScanMethod:@selector(scanUpToString:intoString:) searchFor:@"a" inScanner:@"topaz" succeeded:YES found:@"top" endedAt:3];
    [self performScanMethod:@selector(scanUpToString:intoString:) searchFor:@"x" inScanner:@"topaz" succeeded:YES found:@"topaz" endedAt:5];
    [self performScanMethod:@selector(scanUpToString:intoString:) searchFor:@"x" inScanner:@"" succeeded:NO found:nil endedAt:0];
}

- (void)testScanCharactersFromSet
{
    [self performScanMethod:@selector(scanCharactersFromSet:intoString:) searchFor:[CPCharacterSet lowercaseLetterCharacterSet] inScanner:@"topAz" succeeded:YES found:@"top" endedAt:3];

    [self performScanMethod:@selector(scanCharactersFromSet:intoString:) searchFor:[CPCharacterSet alphanumericCharacterSet] inScanner:@"top12Az&x" succeeded:YES found:@"top12Az" endedAt:7];
    [self performScanMethod:@selector(scanCharactersFromSet:intoString:) searchFor:[CPCharacterSet decomposableCharacterSet] inScanner:@"êñço" succeeded:YES found:@"êñç" endedAt:3];

}
@end