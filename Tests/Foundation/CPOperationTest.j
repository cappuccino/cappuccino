@import <Foundation/CPOperation.j>

@implementation TestOperation2 : CPOperation
{
    CPString name @accessors;
    CPString value @accessors;
}

- (void)main
{
    [self setName:@"test"];
}

@end

@implementation TestObserver2 : CPObject
{
    CPArray changedKeyPaths @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        changedKeyPaths = [[CPArray alloc] init];
    }
    return self;
}

// KVO change notification
- (void)observeValueForKeyPath:(CPString)keyPath
                      ofObject:(id)object
                        change:(CPDictionary)change
                       context:(void)context
{
    [changedKeyPaths addObject:keyPath];
}

@end

@implementation CPOperationTest : OJTestCase

- (void)testAddDependency
{
    var co = [[CPOperation alloc] init],
        co_dep = [[CPOperation alloc] init];

    [co addDependency:co_dep];
    [self assert:1 equals:[[co dependencies] count]];
}

- (void)testRemoveDependency
{
    var co = [[CPOperation alloc] init],
        co_dep1 = [[CPOperation alloc] init],
        co_dep2 = [[CPOperation alloc] init];

    [co addDependency:co_dep1];
    [co addDependency:co_dep2];

    [self assert:2 equals:[[co dependencies] count]];

    [co removeDependency:co_dep2];
    [self assert:1 equals:[[co dependencies] count]];

    [co removeDependency:co_dep2];
    [self assert:1 equals:[[co dependencies] count]];

    [co removeDependency:co_dep1];
    [self assert:0 equals:[[co dependencies] count]];
}

- (void)testCorrectValuesOnInit
{
    var co = [[CPOperation alloc] init];

    [self assertTrue:[co isReady]];
    [self assertFalse:[co isCancelled]];
    [self assertFalse:[co isConcurrent]];
    [self assertFalse:[co isFinished]];
    [self assertFalse:[co isExecuting]];
    [self assert:CPOperationQueuePriorityNormal equals:[co queuePriority]];
}

- (void)testIsReadyWithDependencies
{
    var co = [[CPOperation alloc] init],
        co_dep1 = [[CPOperation alloc] init],
        co_dep2 = [[CPOperation alloc] init];

    [self assertTrue:[co isReady]];

    [co addDependency:co_dep1];
    [co addDependency:co_dep2];

    [self assertFalse:[co isReady]];

    [co_dep1 start];

    [self assertFalse:[co isReady]];

    [co_dep2 start];

    [self assertTrue:[co isReady]];
}

- (void)testCompletionFunction
{
    var to = [[TestOperation2 alloc] init];

    [to setCompletionFunction:function() {[to setValue:@"something"];}];
    [to start];

    [self assert:@"something" equals:[to value]];
}

// KVO Tests

- (void)testKVO
{
    var to = [[TestOperation2 alloc] init],
        to2 = [[TestOperation2 alloc] init],
        obs = [[TestObserver2 alloc] init];

    [to addObserver:obs
         forKeyPath:@"isCancelled"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"isExecuting"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"isFinished"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"isReady"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"dependencies"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"queuePriority"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addObserver:obs
         forKeyPath:@"completionFunction"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [to addDependency:to2];
    [self assert:@"dependencies" equals:[[obs changedKeyPaths] objectAtIndex:0]];
    [self assert:@"isReady" equals:[[obs changedKeyPaths] objectAtIndex:1]];
    [to2 start];
    [self assert:@"isReady" equals:[[obs changedKeyPaths] objectAtIndex:2]];
    [to removeDependency:to2];
    [self assert:@"dependencies" equals:[[obs changedKeyPaths] objectAtIndex:3]];
    [to setQueuePriority:CPOperationQueuePriorityHigh];
    [self assert:@"queuePriority" equals:[[obs changedKeyPaths] objectAtIndex:4]];
    [to setCompletionFunction:function() {}];
    [self assert:@"completionFunction" equals:[[obs changedKeyPaths] objectAtIndex:5]];

    // this should set executing = yes, executing = no, finished = yes.
    [to start];
    [self assert:@"isExecuting" equals:[[obs changedKeyPaths] objectAtIndex:6]];
    [self assert:@"isExecuting" equals:[[obs changedKeyPaths] objectAtIndex:7]];
    [self assert:@"isFinished" equals:[[obs changedKeyPaths] objectAtIndex:8]];

    [to cancel];

    [self assert:@"isCancelled" equals:[[obs changedKeyPaths] objectAtIndex:9]];
}

@end
