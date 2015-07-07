@import <AppKit/CPColorWell.j>
@import <AppKit/CPApplication.j>

@implementation CPColorWellTest : OJTestCase
{
    CPColorWell colorWell;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    colorWell = [[CPColorWell alloc] initWithFrame:CGRectMakeZero()];
}

- (void)testCoding
{
    [self assertTrue:[colorWell isBordered] message:"color well bordered"];
    [self assert:[CPColor whiteColor] equals:[colorWell color] message:"color well default color"];

    [colorWell setColor:[CPColor greenColor]];
    [colorWell setBordered:NO];

    // Test archiving.
    var archived = [CPKeyedArchiver archivedDataWithRootObject:colorWell],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assertFalse:[colorWell isBordered] message:"color well archived bordered state"];
    [self assert:[CPColor greenColor] equals:[colorWell color] message:"color well archived color"];
}

@end
