@import <AppKit/CPLevelIndicator.j>

// You should never do this. This is only for testing purposes.
#define GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, i) [(levelIndicator) layoutEphemeralSubviewNamed:@"segment-bezel-" + (i) positioned:CPWindowAbove relativeToEphemeralSubviewNamed:"bezel"]

@implementation CPLevelIndicatorTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

+ (CPLevelIndicator)indicatorWithLowWarning
{
    var levelIndicator = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [levelIndicator setMinValue:0];
    [levelIndicator setMaxValue:10];
    [levelIndicator setWarningValue:4];
    [levelIndicator setCriticalValue:2];
    [levelIndicator setValue:[CPColor greenColor] forThemeAttribute:@"color-normal"];
    [levelIndicator setValue:[CPColor yellowColor] forThemeAttribute:@"color-warning"];
    [levelIndicator setValue:[CPColor redColor] forThemeAttribute:@"color-critical"];
    return levelIndicator;
}

+ (CPLevelIndicator)indicatorWithHighWarning
{
    var levelIndicator = [self indicatorWithLowWarning];
    [levelIndicator setWarningValue:6];
    [levelIndicator setCriticalValue:8];
    return levelIndicator;
}

- (void)testLevelIndicatorWithLowWarningAndCriticalShouldShowNormalColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithLowWarning];

    [levelIndicator setObjectValue:5];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor greenColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}

- (void)testLevelIndicatorWithLowWarningAndCriticalShouldShowWarningColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithLowWarning];

    [levelIndicator setObjectValue:4];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor yellowColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}

- (void)testLevelIndicatorWithLowWarningAndCriticalShouldShowCriticalColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithLowWarning];

    [levelIndicator setObjectValue:2];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor redColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}

- (void)testLevelIndicatorWithHighWarningAndCriticalShouldShowNormalColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithHighWarning];

    [levelIndicator setObjectValue:5];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor greenColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}

- (void)testLevelIndicatorWithHighWarningAndCriticalShouldShowWarningColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithHighWarning];

    [levelIndicator setObjectValue:6];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor yellowColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}

- (void)testLevelIndicatorWithHighWarningAndCriticalShouldShowCriticalColor
{
    var levelIndicator = [CPLevelIndicatorTest indicatorWithHighWarning];

    [levelIndicator setObjectValue:8];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:[CPColor redColor] equals:[GET_LEVEL_INDICATOR_SEGMENT(levelIndicator, 0) backgroundColor]];
}
@end
