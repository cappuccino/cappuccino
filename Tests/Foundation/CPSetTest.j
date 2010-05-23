
@import <Foundation/CPSet.j>

@implementation CPSetTest : OJTestCase
{
    CPSet set;
}

- (void)setUp
{
    set = [CPSet new];
}

- (void)testAddObject
{
    [self assertFalse:[set containsObject:"foo"]];
    [set addObject:"foo"];
    [self assertTrue:[set containsObject:"foo"]];
}

- (void)testAddZeroObject
{
    [self assertFalse:[set containsObject:0]];
    [set addObject:0];
    [self assertTrue:[set containsObject:0]];
}

- (void)testRemoveObject
{
    [set addObject:"foo"];
    [self assertTrue:[set containsObject:"foo"]];
    [set removeObject:"foo"];
    [self assertFalse:[set containsObject:"foo"]];
}

- (void)testRemoveZeroObject
{
    [set addObject:0];
    [self assertTrue:[set containsObject:0]];
    [set removeObject:0];
    [self assertFalse:[set containsObject:0]];
}

- (void)testAddNilObject
{
    [self assertFalse:[set containsObject:nil]];
    [set addObject:nil];
    [self assertFalse:[set containsObject:nil]];
}

- (void)testRemoveNilObject
{
    [set addObject:nil];
    [self assertFalse:[set containsObject:nil]];
    [set removeObject:nil];
    [self assertFalse:[set containsObject:nil]];
}

- (void)testDescription
{
    [self assert:@"{()}" equals:[set description]];
    [set addObject:"horizon"];
    [set addObject:"surfer"];
    [set addObject:"7"];
    var desc = [set description];
    // Ordering may not be guaranteed.
    [self assertTrue:desc.match(new RegExp("{\(.*horizon.*\)}"))];
    [self assertTrue:desc.match(new RegExp("{\(.*surfer.*\)}"))];
    [self assertTrue:desc.match(new RegExp("{\(.*7.*\)}"))];
}

@end
