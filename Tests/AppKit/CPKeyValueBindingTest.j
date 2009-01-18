
@import "CPKeyValueBinding.j"
@import <AppKit/CPTextField.j>

@implementation CPKeyValueBindingTest : OJTestCase
{
    id FOO; 
}

- (void)testExposingBindings
{
    [BindingTester exposeBinding:@"foo"];
    [BindingTester exposeBinding:@"bar"];
    [CPObject exposeBinding:@"zoo"];
    
    [self assertTrue:[[[BindingTester new] exposedBindings] isEqual:["foo", "bar", "zoo"]]];
}

- (void)testBindTo
{
    var binder = [BindingTester new];
    binder.cheese = "orange";
    
    [CPKeyValueBindingTest exposeBinding:@"FOO"];
    
    [self bind:"FOO" toObject:binder withKeyPath:"cheese" options:nil];
    
    [binder setCheese:@"banana"];
    
    [self assertTrue:[self valueForKey:@"FOO"]==="banana" message:"Bound value should have been updated to banana, was "+FOO];
}

- (void)testControl
{
    FOO = "bingo";
    
    var binder = [BindingTester new];
    binder.cheese = "yellow";

    var control = [[CPTextField alloc] init];
    [control setStringValue:@"brown"];
    
    [CPControl exposeBinding:CPValueBinding];
    [[self class] exposeBinding:@"FOO"];

    //[control addObserver:self forKeyPath:CPValueBinding options:nil context:"testControl"];
    
    [control bind:CPValueBinding toObject:self withKeyPath:@"FOO" options:nil];
    [self bind:@"FOO" toObject:control withKeyPath:CPValueBinding options:nil];
    
    [control setStringValue:@"banana"];
    [control setStringValue:@"grapefruit"];
    
    [self setValue:@"BAR" forKey:@"FOO"];
    
    [self assertTrue: FOO == [control stringValue] message: "should be equal, were: "+FOO+"and: "+[control stringValue]];
        
    [control setStringValue:@"pina colada"];

    [self assertTrue: FOO == [control stringValue] message: "should be equal, were: "+FOO+"and: "+[control stringValue]];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    CPLog(@"here: "+aKeyPath+" value: "+[anObject valueForKey:aKeyPath]);
}

@end

@implementation BindingTester : CPObject
{
    id cheese;
}

- (void)setCheese:(id)aCheese
{
    cheese = aCheese;
}

- (id)cheese
{
    return cheese;
}

@end
