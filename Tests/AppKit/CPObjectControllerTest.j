@import <AppKit/AppKit.j>

@implementation CPObjectControllerTest : OJTestCase
{
}

- (void)setUp
{
}

- (void)testObjectControllerSelectionWithNil
{
    var controller = [[CPObjectController alloc] init];
    [controller setContent:@{@"name": @"Martin"}];
    [self assert:@"Martin" equals:[[controller selection] valueForKeyPath:@"name"] message:@"name equals 'Martin'"];
    [self assert:nil equals:[[controller selection] valueForKeyPath:@"lastName"] message:@"name equals 'nil'"];
    [self assert:@"Martin" equals:[controller valueForKeyPath:@"selection.name"] message:@"selection.name equals 'Martin'"];
    [self assert:nil equals:[controller valueForKeyPath:@"selection.lastName"] message:@"selection.name equals 'nil'"];
}

@end
