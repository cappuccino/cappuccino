@import <Foundation/CPKeyValueObserving.j>

@implementation CPKeyValueObservingTest : OJTestCase
{
    CPString      _lastKeyPath;
    id            _lastObject;
    CPDictionary  _lastChange;
    id            _lastContext;
}

- (void)setup
{
  _lastKeyPath = _lastObject = _lastChange = _lastContext = nil;
}

- (void)testInitialObserving
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionInitial context:nil];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:[CPDictionary dictionaryWithObject:@"CHEESE!" forKey:CPKeyValueChangeNewKey] equals:_lastChange];
    [self assert:nil equals:_lastContext];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
  _lastKeyPath = aKeyPath;
  _lastObject  = anObject;
  _lastChange  = aChange;
  _lastContext = aContext;
}

@end

@implementation ObservingTester : CPObject
{
    id cheese;
}

+ (id)testerWithCheese:(id)aCheese
{
    var tester = [[self alloc] init];
    [tester setCheese:aCheese];
    return tester;
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