
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPKeyValueObserving.j>


@implementation CPKeyValueObservingTest : OJTestCase
{
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

@end
