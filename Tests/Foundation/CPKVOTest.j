import <Foundation/CPKeyValueCoding.j>
import <Foundation/CPKeyValueObserving.j>

@implementation CPKVOTest : OJTestCase
{
    BOOL    _sawInitialObservation;
    BOOL    _sawPriorObservation;
}

- (void)testAddObserver
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:self forKeyPath:@"name" options:nil context:"testAddObserver"];
        
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be 'set_bob', was: "+[bob valueForKey:@"name"]];
    [self assertTrue: bob.name == @"set_bob" message: "bob.name should be 'set_bob', was: "+bob.name];
}

- (void)testAddTwoObservers
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:self forKeyPath:@"name" options:nil context:"testAddTwoObservers"];
    [bob addObserver:[CPObject new] forKeyPath:@"name" options:nil context:"testAddTwoObservers"];
        
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];
    [self assertTrue: bob.name == @"set_bob" message: "bob.name should be 'bob', was: "+bob.name];
}

- (void)testDirectIVarObservation
{
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:self forKeyPath:@"phoneNumber" options:nil context:"testDirectIVarObservation"];
    
    [bob setValue:@"555" forKey:@"phoneNumber"];
    
    [self assertTrue: [bob valueForKey:@"phoneNumber"] == @"555" message: "valueForKey:'phoneNumber' should be '555', was: "+[bob valueForKey:@"phoneNumber"]];
    [self assertTrue: bob.phoneNumber == @"555" message: "bob.phoneNumber should be '555', was: "+bob.phoneNumber];
}

- (void)testRemoveObserver
{
    var bob = [[PersonTester alloc] init];
        
    [bob addObserver:self forKeyPath:@"name" options:nil context:"testRemoveObserver"];
    [bob addObserver:[CPString new] forKeyPath:@"name" options:nil context:"testRemoveObserver"];
    
    [bob removeObserver:self forKeyPath:@"name"];
    
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];
}

- (void)testRemoveOtherObserver
{
    var bob = [[PersonTester alloc] init],
        obj = [CPString new];
        
    [bob addObserver:self forKeyPath:@"name" options:nil context:"testRemoveOtherObserver"];
    [bob addObserver:obj forKeyPath:@"name" options:nil context:"testRemoveOtherObserver"];
    
    [bob removeObserver:obj forKeyPath:@"name"];
    
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];
}

- (void)testRemoveAllObservers
{
    var bob = [[PersonTester alloc] init],
        obj1 = [CPArray new],
        obj2 = [CPString new];
        
    [bob addObserver:obj1 forKeyPath:@"name" options:nil context:"testRemoveAllObservers"];
    [bob addObserver:obj2 forKeyPath:@"name" options:nil context:"testRemoveAllObservers"];
    
    [bob removeObserver:obj1 forKeyPath:@"name"];
    [bob removeObserver:obj2 forKeyPath:@"name"];
    [bob removeObserver:nil forKeyPath:nil];
    
    [bob setValue:@"bob" forKey:@"name"];
    
    [self assertTrue: [bob valueForKey:@"name"] == @"set_bob" message: "valueForKey:'name' should be bob, was: "+[bob valueForKey:@"name"]];

}

- (void)testPriorObservationOption
{
    _sawPriorObservation = NO;
    
    var bob = [[PersonTester alloc] init];
    
    [bob addObserver:self forKeyPath:@"name" options:CPKeyValueObservingOptionPrior context:"testPriorObservationOption"];

    [bob setValue:@"bob" forKey:@"name"];

    [self assertTrue: _sawPriorObservation message: "asked for CPKeyValueObservingOptionPrior but did not recieve corresponding notification"];
}

- (void)testInitialObservationOption
{
    _sawInitialObservation = NO;

    var bob = [[PersonTester alloc] init];
    
    bob.name = "paul";    

    [bob addObserver:self forKeyPath:@"name" options:CPKeyValueObservingOptionInitial context:"testInitialObservationOption"];
    [bob removeObserver:self forKeyPath:@"name"];

    [bob setValue:@"bob" forKey:@"name"];

    [self assertTrue: _sawInitialObservation message: "asked for CPKeyValueObservingOptionInitial but did not recieve corresponding notification"];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    var oldValue = [changes objectForKey:CPKeyValueChangeOldKey],
        newValue = [changes objectForKey:CPKeyValueChangeNewKey];

    switch (aContext)
    {
        case "testAddObserver": 
            [self assertTrue: newValue == "set_bob" message: "newValue should be: set_bob was: "+newValue];
            [self assertTrue: oldValue == [CPNull null] message: "oldValue should be CPNull was: "+oldValue];
            break;
            
        case "testAddTwoObservers":             
            [self assertTrue: newValue == "set_bob" message: "newValue should be: set_bob was: "+newValue];
            [self assertTrue: oldValue == [CPNull null] message: "oldValue should be CPNull was: "+oldValue];
            break;
            
        case "testDirectIVarObservation":
            [self assertTrue: newValue == "555" message: "newValue should be: 555 was: "+newValue];
            [self assertTrue: oldValue == [CPNull null] message: "oldValue should be CPNull was: "+oldValue];
            break;

        case "testRemoveObserver":
            [self assertTrue: NO message: "observer was removed, but notification was still received"];
            break;

        case "testRemoveOtherObserver":
            [self assertTrue: newValue == "set_bob" message: "newValue should be: set_bob was: "+newValue];
            [self assertTrue: oldValue == [CPNull null] message: "oldValue should be CPNull was: "+oldValue];
            break;

        case "testRemoveAllObservers":
            [self assertTrue: NO message: "all observers were removed, but notification was still received"];
            break;
            
        case "testPriorObservationOption":
            var prior = [changes objectForKey:CPKeyValueChangeNotificationIsPriorKey];
            
            if (!_sawPriorObservation)
            {
                [self assertTrue:prior message:"Have not been sent the prior notification, but it should have been sent"];
                [self assertTrue:oldValue == [CPNull null] message: "Shoudl be no initial value"];
                [self assertFalse:newValue message: "Should be no object for the new value key on the prior notification"];
                _sawPriorObservation = YES;
            }
            else
            {
                [self assertFalse: prior message: "there should be no value for the notification is prior key, that notification was already sent"];
                [self assertTrue: newValue == "set_bob" message: "newValue should be: set_bob was: "+newValue];
            }
            break;
            
        case "testInitialObservationOption":
            if (!_sawInitialObservation)
            {
                [self assertTrue: newValue == "paul" message:"Expected old value to be: paul was: "+oldValue];
                [self assertFalse: oldValue message:"Should be no value for new change key on initial observation"];
                _sawInitialObservation = YES;
            }
            else
                [self assertFalse:YES message:"Should never have received this notification"];

            break;
    }
}

@end

@implementation CPObject (KVO)

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{

}

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