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

- (void)testSendNotificationsForDependantKeyPaths
{
    var observingTester = [ObservingTester testerWithCheese:@"cheese"],
        dependantKeyPathTester = [DependantKeyPathsTester testerWithObservingTester:observingTester];

    [dependantKeyPathTester addObserver:self forKeyPath:@"observedCheese" options:CPKeyValueObservingOptionNew context:nil];
    [observingTester setCheese:@"changed cheese"];

    [self assert:@"observedCheese" equals:_lastKeyPath]
    [self assert:dependantKeyPathTester equals:_lastObject];
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

@implementation DependantKeyPathsTester: CPObject
{
    ObservingTester                 _observingTester @accessors(property=observingTester);
}

+ (CPSet)keyPathsForValuesAffectingObservedCheese
{
    return [CPSet setWithObjects:@"observingTester.cheese"];
}

+ (id)testerWithObservingTester:(ObservingTester)theObservingTester
{
    return [[self alloc] initWithObservingTester:theObservingTester];
}

- (id)initWithObservingTester:(ObservingTester)theObservingTester
{
    if (self = [super init])
    {
        _observingTester = theObservingTester;
    }

    return self;
}

- (CPString)observedCheese
{
    return [[self observingTester] cheese];
}