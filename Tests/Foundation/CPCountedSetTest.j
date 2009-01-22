
@import <Foundation/CPCountedSet.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>

@implementation CPCountedSetTest : OJTestCase

- (void)testCountForObject
{
    var set = [CPCountedSet setWithArray:[1, 2, 3]];
    
    [self assertTrue:[set countForObject:[CPNull null]] === 0 message:"Expected count of 0, got: "+[set countForObject:[CPNull null]]];
    [self assertTrue:[set countForObject:3] === 1 message:"Expected count of 1, got: "+[set countForObject:0]];
    
    [set addObject:1];
    
    [self assertTrue:[set countForObject:1] === 2 message:"Expected count of 2, got: "+[set countForObject:1]];
    
    [set addObject:2];
    [set addObject:2];
    
    [self assertTrue:[set countForObject:2] === 3 message:"Expected count of 3, got: "+[set countForObject:2]];
}

- (void)testAddObject
{
    var set = [CPCountedSet new];
    
    [self assertTrue:[set countForObject:"foo"] === 0 message:"Expected count of 0, got: "+[set countForObject:"foo"]];    
    
    [set addObject:"foo"];
    
    [self assertTrue:[set countForObject:"foo"] === 1 message:"Expected count of 1, got: "+[set countForObject:"foo"]];

    [set addObject:"foo"];
    [set addObject:"foo"];
    [set addObject:"foo"];
    
    [self assertTrue:[set countForObject:"foo"] === 4 message:"Expected count of 4, got: "+[set countForObject:"foo"]];    
}

- (void)testRemoveObject
{
    var set = [CPCountedSet new];
    
    [self assertTrue:[set countForObject:"foo"] === 0 message:"Expected count of 0, got: "+[set countForObject:"foo"]];    
    
    [set addObject:"foo"];
    [set addObject:"foo"];
    [set addObject:"foo"];
    [set addObject:"foo"];
    
    [self assertTrue:[set countForObject:"foo"] === 4 message:"Expected count of 4, got: "+[set countForObject:"foo"]];
    
    [set removeObject:"foo"];
    
    [self assertTrue:[set countForObject:"foo"] === 3 message:"Expected count of 3, got: "+[set countForObject:"foo"]];

    [set removeObject:"foo"];
    [set removeObject:"foo"];

    [self assertTrue:[set countForObject:"foo"] === 1 message:"Expected count of 1, got: "+[set countForObject:"foo"]];

    [set removeObject:"foo"];

    [self assertTrue:[set countForObject:"foo"] === 0 message:"Expected count of 0, got: "+[set countForObject:"foo"]];

    [set removeObject:"foo"];
    [set removeObject:"foo"];

    [self assertTrue:[set countForObject:"foo"] === 0 message:"Expected count of 0, got: "+[set countForObject:"foo"]];
}

// FIXME: add an archiving test
// FIXME: add union/intersection/minus tests?

@end
