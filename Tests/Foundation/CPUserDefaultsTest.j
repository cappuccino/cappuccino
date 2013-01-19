@import <Foundation/Foundation.j>


CPUserDefaultsTestKey1 = @"KEY1";
CPUserDefaultsTestKey2 = @"KEY2";

@implementation CPUserDefaultsCookieStore (test)

- (void)setData:(CPData)aData
{
    // deactive real storage
}

@end

//CPLogRegister(CPLogPrint)

@implementation CPUserDefaultsTest : OJTestCase
{
    CPUserDefaults  target;
    id              lastObservedCPUserDefaultsTestKey1;
}

- (void)setUp
{
    target = [CPUserDefaults standardUserDefaults];
}

- (void)tearDown
{
    [CPUserDefaults resetStandardUserDefaults];
}

- (void)testAppDefault
{
    var appDefaults = [CPDictionary dictionaryWithObjectsAndKeys:YES, CPUserDefaultsTestKey1, @"Hello!", CPUserDefaultsTestKey2];
    [target registerDefaults:appDefaults];

    [self assertTrue:[target boolForKey:CPUserDefaultsTestKey1]];
    [self assert:[target objectForKey:CPUserDefaultsTestKey2] equals:@"Hello!"];

}

- (void)testSetObjectForKey
{
    [target setObject:[CPArray arrayWithObjects:@"cell1", @"cell2"] forKey:CPUserDefaultsTestKey1];

    var cell1 = [[target objectForKey:CPUserDefaultsTestKey1] objectAtIndex:0],
        cell2 = [[target objectForKey:CPUserDefaultsTestKey1] objectAtIndex:1];

    [self assert:cell1 equals:@"cell1"];
    [self assert:cell2 equals:@"cell2"];
}

- (void)testBool
{
    [target setBool:YES forKey:CPUserDefaultsTestKey1];
    [self assertTrue:[target boolForKey:CPUserDefaultsTestKey1]];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assertFalse:[target boolForKey:CPUserDefaultsTestKey1]];
}

- (void)testInteger
{
    [target setInteger:1 forKey:CPUserDefaultsTestKey1];
    [self assert:[target integerForKey:CPUserDefaultsTestKey1] equals:1];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target integerForKey:CPUserDefaultsTestKey1] equals:0];
}

- (void)testFloat
{
    [target setFloat:1.0 forKey:CPUserDefaultsTestKey1];
    [self assert:[target floatForKey:CPUserDefaultsTestKey1] equals:1.0];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target floatForKey:CPUserDefaultsTestKey1] equals:0.0];
}

- (void)testDouble
{
    [target setDouble:1.0 forKey:CPUserDefaultsTestKey1];
    [self assert:[target doubleForKey:CPUserDefaultsTestKey1] equals:1.0];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target doubleForKey:CPUserDefaultsTestKey1] equals:0.0];
}

- (void)testString
{
    [target setObject:@"Hello World" forKey:CPUserDefaultsTestKey1];

    var string = [target stringForKey:CPUserDefaultsTestKey1];
    [self assert:string equals:@"Hello World"];
    [self assertTrue:[string isKindOfClass:[CPString class]]];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target stringForKey:CPUserDefaultsTestKey1] equals:nil];
}

- (void)testURL
{
    [target setURL:[CPURL URLWithString:@"http://cappuccino-project.org"] forKey:CPUserDefaultsTestKey1];
    [self assert:[[target URLForKey:CPUserDefaultsTestKey1] class] equals:CPURL];
    [self assert:[[target URLForKey:CPUserDefaultsTestKey1] absoluteString] equals:@"http://cappuccino-project.org"];

    [target setURL:@"http://cappuccino-project.org" forKey:CPUserDefaultsTestKey1];
    [self assert:[[target URLForKey:CPUserDefaultsTestKey1] class] equals:CPURL];
    [self assert:[[target URLForKey:CPUserDefaultsTestKey1] absoluteString] equals:@"http://cappuccino-project.org"];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target URLForKey:CPUserDefaultsTestKey1] equals:nil];
}

- (void)testArray
{
    [target setObject:[@"a", @"b", 3] forKey:CPUserDefaultsTestKey1];
    [self assertTrue:[[target arrayForKey:CPUserDefaultsTestKey1] isKindOfClass:CPArray]];
    [self assert:[[target arrayForKey:CPUserDefaultsTestKey1] objectAtIndex:1] equals:@"b"];
    [self assert:[[target arrayForKey:CPUserDefaultsTestKey1] objectAtIndex:2] equals:3];
    [self assert:[target stringArrayForKey:CPUserDefaultsTestKey1] equals:nil];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target arrayForKey:CPUserDefaultsTestKey1] equals:nil];
}

- (void)testData
{
    [target setObject:[CPData dataWithRawString:@"data"] forKey:CPUserDefaultsTestKey1];
    [self assert:[[target dataForKey:CPUserDefaultsTestKey1] class] equals:CPData];

    [target removeObjectForKey:CPUserDefaultsTestKey1];
    [self assert:[target dataForKey:CPUserDefaultsTestKey1] equals:nil];
}

- (void)testNotification
{
    [target setDouble:5.0 forKey:CPUserDefaultsTestKey1];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:CPUserDefaultsDidChangeNotification object:target];

    // Prod the class to resolve any outstanding _searchListNeedsReload's.
    [self assert:5.0 equals:[target objectForKey:CPUserDefaultsTestKey1] message:"normal read"];
    [target setDouble:10.0 forKey:CPUserDefaultsTestKey1];
    [self assert:[target objectForKey:CPUserDefaultsTestKey1] equals:lastObservedCPUserDefaultsTestKey1 message:"should observe new value"];
}

- (void)userDefaultsDidChange:(CPNotification)aNotification
{
   lastObservedCPUserDefaultsTestKey1 = [target objectForKey:CPUserDefaultsTestKey1];
}

@end
