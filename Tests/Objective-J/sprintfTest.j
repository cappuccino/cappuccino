var sprintf = ObjectiveJ.sprintf;

@implementation sprintfTest : OJTestCase

// TODO: add many many more of these...

- (void)testObjectWithPrefixAndSuffix
{
  [self assert:@"[hello world]" equals:sprintf(@"[%@]", @"hello world")];
}

- (void)testDecimalWithPrefixAndSuffix
{
  [self assert:@"[123]" equals:sprintf(@"[%d]", 123)];
}

- (void)testFloatWithPrefixAndSuffix
{
  [self assert:@"[123.1234]" equals:sprintf(@"[%f]", 123.1234)];
}

- (void)testZeroPaddingWithWidthAndPercentEscaping
{
  [self assert:@"099%" equals:sprintf(@"%03d%%", 99)];
}

- (void)testOutOfOrderExplicitFormatParameterIndexes
{
  [self assert:@"2 > 1" equals:sprintf(@"%2$d > %1$d", 1, 2)];
}

- (void)testMixingImplicitAndExplicitFormatParameterIndexes
{
  [self assert:@"a < b && b > a" equals:sprintf(@"%@ < %2$@ && %@ > %1$@", @"a", @"b")];
}

@end
