import <Foundation/CPKeyValueCoding.j>
import <Foundation/CPKeyValueObserving.j>

@implementation CPKVOTest : OJTestCase

- (void)testAddObserver
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:[CPObject new] forKeyPath:@"name" options:nil context:nil];
        
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be 'set_bob', was: "+[bob valueForKey:@"name"]];
    [self assertTrue: bob.name == @"set_bob" message: "bob.name should be 'set_bob', was: "+bob.name];
}

- (void)testAddTwoObservers
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:[CPArray new] forKeyPath:@"name" options:nil context:nil];
    [bob addObserver:[CPString new] forKeyPath:@"name" options:nil context:nil];
        
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];
    [self assertTrue: bob.name == @"set_bob" message: "bob.name should be 'bob', was: "+bob.name];
}

- (void)testDirectIVarObservation
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:[CPObject new] forKeyPath:@"phoneNumber" options:nil context:nil];
    
    [bob setValue:@"555" forKey:@"phoneNumber"];
    
    [self assertTrue: [bob valueForKey:@"phoneNumber"] == @"555" message: "valueForKey:'phoneNumber' should be '555', was: "+[bob valueForKey:@"phoneNumber"]];
    [self assertTrue: bob.phoneNumber == @"555" message: "bob.phoneNumber should be '555', was: "+bob.phoneNumber];
}

- (void)testRemoveObserver
{
    var bob = [[PersonTester alloc] init],
        obj = [CPArray new];
        
    [bob addObserver:obj forKeyPath:@"name" options:nil context:nil];
    [bob addObserver:[CPString new] forKeyPath:@"name" options:nil context:nil];
    
    [bob removeObserver:obj forKeyPath:@"name"];
    
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];
}

- (void)testRemoveAllObservers
{
    var bob = [[PersonTester alloc] init],
        obj1 = [CPArray new],
        obj2 = [CPString new];
        
    [bob addObserver:obj1 forKeyPath:@"name" options:nil context:nil];
    [bob addObserver:obj2 forKeyPath:@"name" options:nil context:nil];
    
    [bob removeObserver:obj1 forKeyPath:@"name"];
    [bob removeObserver:obj2 forKeyPath:@"name"];
    [bob removeObserver:nil forKeyPath:nil];
    
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];

}

//test actual observing
//test each observing option

@end

@implementation PersonTester : CPObject
{
    CPString    name;
    CPString    phoneNumber;
}

- (void)setName:(CPString)aName
{
    name = "set_"+aName;
}

@end