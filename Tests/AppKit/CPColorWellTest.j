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

    [self assertNotNull:unarchived];
    [self assertFalse:[colorWell isBordered] message:"color well archived bordered state"];
    [self assert:[CPColor greenColor] equals:[colorWell color] message:"color well archived color"];
}

/**
 * Tests that color well objects maintain visual state consistency.
 * 
 * Validates the object's responsibility to synchronize public properties
 * with internal theme state management.
 */
- (void)testColorWellMaintainsVisualStateConsistency
{
    [colorWell setBordered:NO];
    [self assertFalse:[colorWell isBordered] message:"object correctly reports bordered state"];
    
    [colorWell setBordered:YES];
    [self assertTrue:[colorWell isBordered] message:"object correctly reports changed bordered state"];
}

/**
 * Tests that color well objects properly handle activation responsibilities.
 * 
 * Validates the object's role in responder chain participation and
 * exclusive activation behavior.
 */
- (void)testColorWellHandlesActivationResponsibilities
{
    // Note: We test activation through observable effects, not internal state
    [colorWell activate:YES];
    [self assertTrue:[colorWell acceptsFirstResponder] message:"activated object accepts responder chain participation"];
}

/**
 * Tests that disabled color well objects behave appropriately.
 * 
 * Validates the object's responsibility to modify its behavior
 * when in a disabled state.
 */
- (void)testDisabledColorWellModifiesBehaviorAppropriately
{
    [colorWell setEnabled:NO];
    [self assertFalse:[colorWell acceptsFirstResponder] message:"disabled object modifies responder behavior"];
    
    [colorWell setEnabled:YES];
    [self assertTrue:[colorWell acceptsFirstResponder] message:"re-enabled object restores normal behavior"];
}

/**
 * Tests that color well objects interact correctly with other wells.
 * 
 * Validates the object's responsibility to handle exclusive activation
 * scenarios with other color well instances.
 */
- (void)testColorWellInteractsCorrectlyWithOtherWells
{
    var well1 = colorWell,
        well2 = [[CPColorWell alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    
    [well1 activate:YES]; // Exclusive activation
    [well2 activate:NO]; // Non-exclusive should still work
    
    [self assertTrue:[well2 acceptsFirstResponder] message:"objects maintain independence where appropriate"];
}

/**
 * Tests basic color assignment functionality.
 * 
 * Validates the core contract: setting a color should change what's
 * returned by the color getter.
 */
- (void)testBasicColorAssignment
{
    var testColor = [CPColor colorWithCalibratedRed:0.2 green:0.4 blue:0.6 alpha:0.8];
    [colorWell setColor:testColor];
    [self assert:[colorWell color] equals:testColor message:"object correctly handles color assignment"];
}

/**
 * Tests default initialization properties.
 * 
 * Validates that newly created objects have expected default state.
 */
- (void)testDefaultInitializationProperties
{
    [self assertNotNull:colorWell message:"object can be initialized"];
    [self assert:[colorWell color] equals:[CPColor whiteColor] message:"object has correct default color"];
    [self assertTrue:[colorWell isBordered] message:"object has correct default bordered state"];
    [self assertFalse:[colorWell isActive] message:"object starts inactive"];
}
@end
