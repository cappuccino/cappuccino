
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
