@import <AppKit/CPImage.j>

@implementation CPImageTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)testInitWithContentsOfFile_nil
{
    var image = [[CPImage alloc] initWithContentsOfFile:nil];

    [self assert:nil equals:image message:@"- CPImage initWithContentsOfFile:nil should return nil"];
}

// MARK: Archiving

/*
    A theme records its system images on a CPImage, and the blend task archives that image
    before it records it. The theme values therefore survive archiving.
*/
- (void)testAnImageKeepsItsThemeValuesThroughArchiving
{
    var image = [[CPImage alloc] init],
        value = [CPImage imageWithCSSDictionary:@{ "background-color": "red" } size:CGSizeMake(24.0, 24.0)];

    [image setValue:value forThemeAttribute:@"font-panel"];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:image]];

    [self assert:[value cssDictionary] equals:[[decoded valueForThemeAttribute:@"font-panel"] cssDictionary]];
}

- (void)testAnImageWithoutThemeValuesArchivesNoThemeObjects
{
    var image = [CPImage imageWithCSSDictionary:@{ "background-color": "red" } size:CGSizeMake(24.0, 24.0)],
        data = [CPKeyedArchiver archivedDataWithRootObject:image];

    [self assertFalse:[[data rawString] containsString:@"CPViewThemeClassKey"]];
}

@end
