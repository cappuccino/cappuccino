
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPKeyValueObserving.j>

var _getCheeseCounter;

@implementation CPKeyValueObservingTest : OJTestCase
{
    CPString        _lastKeyPath;
    id              _lastObject;
    CPDictionary    _lastChange;
    id              _lastContext;

    CPString        _secondLastKeyPath;
    id              _secondLastObject;
    CPDictionary    _secondLastChange;
    id              _secondLastContext;

}

- (Class)objectWithMethods:(CPString)aMethodName, ...
{
    var theClass = objj_allocateClassPair(CPObject, RAND() + "");

    objj_registerClassPair(theClass);

    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        class_addMethod(theClass, arguments[index], function() { });

    return [theClass new];
}

- (void)setUp
{
    _lastKeyPath = _lastObject = _lastChange = _lastContext = _secondLastKeyPath = _secondLastObject = _secondLastChange = _secondLastContext = nil;
    _getCheeseCounter = 0;
}

- (void)testInitialObserving
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionInitial context:nil];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];
}

- (void)testInitialObservingNoNew
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionInitial context:nil];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];
}

- (void)testSettingObservingPrior
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionPrior context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];

    [self assert:@"cheese" equals:_secondLastKeyPath];
    [self assert:tester equals:_secondLastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting, CPKeyValueChangeNotificationIsPriorKey: 1} equals:_secondLastChange];
    [self assert:nil equals:_secondLastContext];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];
    [self assert:0 equals:_getCheeseCounter message:@"Get method should never be called"];
}

- (void)testSettingObservingPriorPlusMoreObservers
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionPrior context:nil];

    var observerWithOld = [[AnotherObserver alloc] init];
    [tester addObserver:observerWithOld forKeyPath:@"cheese" options:CPKeyValueObservingOptionPrior | CPKeyValueObservingOptionOld context:nil];

    var observerWithNew = [[AnotherObserver alloc] init];
    [tester addObserver:observerWithNew forKeyPath:@"cheese" options:CPKeyValueObservingOptionPrior | CPKeyValueObservingOptionNew context:nil];

    var observerWithNewAndOld = [[AnotherObserver alloc] init];
    [tester addObserver:observerWithNewAndOld forKeyPath:@"cheese" options:CPKeyValueObservingOptionPrior | CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];

    [self assert:@"cheese" equals:_secondLastKeyPath];
    [self assert:tester equals:_secondLastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting, CPKeyValueChangeNotificationIsPriorKey: 1} equals:_secondLastChange];
    [self assert:nil equals:_secondLastContext];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];

    [self assert:@"cheese" equals:observerWithOld._secondLastKeyPath];
    [self assert:tester equals:observerWithOld._secondLastObject];
    [self assert:@{CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting, CPKeyValueChangeNotificationIsPriorKey: 1} equals:observerWithOld._secondLastChange];
    [self assert:nil equals:observerWithOld._secondLastContext];

    [self assert:@"cheese" equals:observerWithOld._lastKeyPath];
    [self assert:tester equals:observerWithOld._lastObject];
    [self assert:@{CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:observerWithOld._lastChange];
    [self assert:nil equals:observerWithOld._lastContext];

    [self assert:@"cheese" equals:observerWithNew._secondLastKeyPath];
    [self assert:tester equals:observerWithNew._secondLastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting, CPKeyValueChangeNotificationIsPriorKey: 1} equals:observerWithNew._secondLastChange];
    [self assert:nil equals:observerWithNew._secondLastContext];

    [self assert:@"cheese" equals:observerWithNew._lastKeyPath];
    [self assert:tester equals:observerWithNew._lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"NEW CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:observerWithNew._lastChange];
    [self assert:nil equals:observerWithNew._lastContext];

    [self assert:@"cheese" equals:observerWithNewAndOld._secondLastKeyPath];
    [self assert:tester equals:observerWithNewAndOld._secondLastObject];
    [self assert:@{CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting, CPKeyValueChangeNotificationIsPriorKey: 1} equals:observerWithNewAndOld._secondLastChange];
    [self assert:nil equals:observerWithNewAndOld._secondLastContext];

    [self assert:@"cheese" equals:observerWithNewAndOld._lastKeyPath];
    [self assert:tester equals:observerWithNewAndOld._lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"NEW CHEESE!", CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:observerWithNewAndOld._lastChange];
    [self assert:nil equals:observerWithNewAndOld._lastContext];

    [self assert:2 equals:_getCheeseCounter message:@"Get method should only be called twice, not " + _getCheeseCounter + " times"];
}

- (void)testSettingObserving
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:0 context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];
    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];
    [self assert:0 equals:_getCheeseCounter message:@"Get method should never be called"];
}

- (void)testSettingObservingNewPlusAnotherObserverWithNoNew
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionNew context:nil];

    var anotherObserver = [[AnotherObserver alloc] init];
    [tester addObserver:anotherObserver forKeyPath:@"cheese" options:0 context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"NEW CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];

    [self assert:@"cheese" equals:anotherObserver._lastKeyPath];
    [self assert:tester equals:anotherObserver._lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:anotherObserver._lastChange];
    [self assert:nil equals:anotherObserver._lastContext];

    [self assert:1 equals:_getCheeseCounter message:@"Get method should only be called once, not " + _getCheeseCounter + " times"];
}

- (void)testSettingObservingOldPlusAnotherObserverWithNoOld
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionOld context:nil];

    var anotherObserver = [[AnotherObserver alloc] init];
    [tester addObserver:anotherObserver forKeyPath:@"cheese" options:0 context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];

    [self assert:@"cheese" equals:anotherObserver._lastKeyPath];
    [self assert:tester equals:anotherObserver._lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:anotherObserver._lastChange];
    [self assert:nil equals:anotherObserver._lastContext];

    [self assert:1 equals:_getCheeseCounter message:@"Get method should only be called once, not " + _getCheeseCounter + " times"];
}

- (void)testSettingObservingNewAndOldPlusMoreObserversWithOnlyNewOrOld
{
    var tester = [ObservingTester testerWithCheese:@"CHEESE!"];
    [tester addObserver:self forKeyPath:@"cheese" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:nil];

    var anotherObserver = [[AnotherObserver alloc] init];
    [tester addObserver:anotherObserver forKeyPath:@"cheese" options:CPKeyValueObservingOptionOld context:nil];

    var yetAnotherObserver = [[AnotherObserver alloc] init];
    [tester addObserver:yetAnotherObserver forKeyPath:@"cheese" options:CPKeyValueObservingOptionNew context:nil];

    var noNewOrOldObserver = [[AnotherObserver alloc] init];
    [tester addObserver:noNewOrOldObserver forKeyPath:@"cheese" options:0 context:nil];

    [tester setValue:@"NEW CHEESE!" forKey:@"cheese"];

    [self assert:@"cheese" equals:_lastKeyPath];
    [self assert:tester equals:_lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"NEW CHEESE!", CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:_lastChange];
    [self assert:nil equals:_lastContext];

    [self assert:@"cheese" equals:anotherObserver._lastKeyPath];
    [self assert:tester equals:anotherObserver._lastObject];
    [self assert:@{CPKeyValueChangeOldKey: @"CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:anotherObserver._lastChange];
    [self assert:nil equals:anotherObserver._lastContext];

    [self assert:@"cheese" equals:yetAnotherObserver._lastKeyPath];
    [self assert:tester equals:yetAnotherObserver._lastObject];
    [self assert:@{CPKeyValueChangeNewKey: @"NEW CHEESE!", CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:yetAnotherObserver._lastChange];
    [self assert:nil equals:yetAnotherObserver._lastContext];

    [self assert:@"cheese" equals:noNewOrOldObserver._lastKeyPath];
    [self assert:tester equals:noNewOrOldObserver._lastObject];
    [self assert:@{CPKeyValueChangeKindKey: CPKeyValueChangeSetting} equals:noNewOrOldObserver._lastChange];
    [self assert:nil equals:noNewOrOldObserver._lastContext];

    [self assert:2 equals:_getCheeseCounter message:@"Get method should only be called twice even with many observers, not " + _getCheeseCounter + " times"];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
    _secondLastKeyPath = _lastKeyPath;
    _secondLastObject  = _lastObject;
    _secondLastChange  = _lastChange;
    _secondLastContext = _lastContext;

    _lastKeyPath = aKeyPath;
    _lastObject  = anObject;
    _lastChange  = [aChange copy];
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

- (void)testOnlyInsertObject_AtKeyIndex_Implemented
{
    var insertSelector = @selector(insertObject:inObjectsAtIndex:),
        object = [self objectWithMethods:insertSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, insertSelector)
            same:class_getInstanceMethod([object class], insertSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, insertSelector)
            same:class_getInstanceMethod([object class], insertSelector)];
}

- (void)testOnlyRemoveObjectFromKeyAtIndex_Implemented
{
    var removeSelector = @selector(removeObjectFromObjectsAtIndex:),
        object = [self objectWithMethods:removeSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];
}

- (void)testOnlyAddKey_Implemented
{
    var addSelector = @selector(addObjects:),
        object = [self objectWithMethods:addSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, addSelector)
            same:class_getInstanceMethod([object class], addSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, addSelector)
            same:class_getInstanceMethod([object class], addSelector)];
}

- (void)testOnlyRemoveKey_Implemented
{
    var removeSelector = @selector(removeObjects:),
        object = [self objectWithMethods:removeSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];
}

- (void)testOnlyOrderedMutationMethodsImplemented
{
    var insertSelector = @selector(insertObject:inObjectsAtIndex:),
        removeSelector = @selector(removeObjectFromObjectsAtIndex:),
        object = [self objectWithMethods:insertSelector, removeSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, insertSelector)
            same:class_getInstanceMethod([object class], insertSelector)];

    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    [self assert:class_getInstanceMethod(object.isa, insertSelector)
         notSame:class_getInstanceMethod([object class], insertSelector)];

    [self assert:class_getInstanceMethod(object.isa, removeSelector)
         notSame:class_getInstanceMethod([object class], removeSelector)];
}

- (void)testOnlyUnorderedMutationMethodsImplemented
{
    var addSelector = @selector(addObjects:),
        removeSelector = @selector(removeObjects:),
        object = [self objectWithMethods:addSelector, removeSelector];

    // Sanity check
    [self assert:class_getInstanceMethod(object.isa, addSelector)
            same:class_getInstanceMethod([object class], addSelector)];

    [self assert:class_getInstanceMethod(object.isa, removeSelector)
            same:class_getInstanceMethod([object class], removeSelector)];

    [object
        addObserver:self
         forKeyPath:@"objects"
            options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
            context:NULL];

    [self assert:class_getInstanceMethod(object.isa, addSelector)
         notSame:class_getInstanceMethod([object class], addSelector)];

    [self assert:class_getInstanceMethod(object.isa, removeSelector)
         notSame:class_getInstanceMethod([object class], removeSelector)];
}

- (void)testAutomaticallyNotifiesObserversOf
{
    var test = [ObservingTester new];

    [test addObserver:self forKeyPath:@"cheese" options:0 context:nil];
    [test addObserver:self forKeyPath:@"astronaut" options:0 context:nil];

    // Cheese shouldn't have been affected.
    [test setCheese:@"changed cheese"];
    [self assert:@"cheese" equals:_lastKeyPath]
    [self assert:test equals:_lastObject];

    // Cheese shouldn't have been affected.
    [test setAstronaut:@"Armstrong"];
    // Nothing should have been observed because we don't automatically notify
    // and we didn't call will/didChange.
    [self assert:@"cheese" equals:_lastKeyPath message:"no observation when automatically notifies is off"];
    [self assert:test equals:_lastObject];
}

@end

@implementation ObservingTester : CPObject
{
    id cheese;
    id astronaut @accessors;
}

+ (BOOL)automaticallyNotifiesObserversOfAstronaut
{
    return NO;
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
    _getCheeseCounter++;
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

@end

@implementation AnotherObserver : CPObject
{
    CPString        _lastKeyPath;
    id              _lastObject;
    CPDictionary    _lastChange;
    id              _lastContext;

    CPString        _secondLastKeyPath;
    id              _secondLastObject;
    CPDictionary    _secondLastChange;
    id              _secondLastContext;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
    _secondLastKeyPath = _lastKeyPath;
    _secondLastObject  = _lastObject;
    _secondLastChange  = _lastChange;
    _secondLastContext = _lastContext;

    _lastKeyPath = aKeyPath;
    _lastObject  = anObject;
    _lastChange  = [aChange copy];
    _lastContext = aContext;
}

@end
