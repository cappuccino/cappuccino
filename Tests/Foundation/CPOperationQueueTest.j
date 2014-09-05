@import <Foundation/CPOperationQueue.j>

globalResults = [];

@implementation TestOperation : CPOperation
{
    CPString name @accessors;
    CPString value @accessors;
}

- (void)main
{
    [self setName:@"test"];
    globalResults.push([self value]);
}

@end

@implementation TestObserver : CPObject
{
    CPArray changedKeyPaths @accessors;
}

- (id)init
{
    if (self = [super init])
        changedKeyPaths = [[CPArray alloc] init];

    return self;
}

// KVO change notification
- (void)observeValueForKeyPath:(CPString)keyPath
                      ofObject:(id)object
                        change:(CPDictionary)change
                       context:(id)context
{
    [changedKeyPaths addObject:keyPath];
}

@end

@implementation CPOperationQueueTest : OJTestCase

- (void)testAddOperation
{
    var oq = [[CPOperationQueue alloc] init],
        to = [[TestOperation alloc] init];

    [self assert:0 equals:[oq operationCount]];
    [oq addOperation:to];

    [self assert:1 equals:[oq operationCount]];
}

- (void)testAddOperationsWithWaitUntilFinished
{
    var oq = [[CPOperationQueue alloc] init],
        to1 = [[TestOperation alloc] init],
        to2 = [[TestOperation alloc] init],
        to3 = [[TestOperation alloc] init];

    [to3 addDependency:to1];
    [to3 addDependency:to2];

    [self assert:0 equals:[oq operationCount]];
    [oq addOperations:[to1, to2, to3] waitUntilFinished:YES];

    //make sure they all ran and are finished...
    [self assertTrue:[to1 isFinished]];
    [self assertTrue:[to2 isFinished]];
    [self assertTrue:[to3 isFinished]];
    [self assert:@"test" equals:[to1 name]];
    [self assert:@"test" equals:[to2 name]];
    [self assert:@"test" equals:[to3 name]];

    [self assert:3 equals:[oq operationCount]];
}

- (void)testRunOperationsInCorrectOrder
{
    var oq = [[CPOperationQueue alloc] init],
        to1 = [[TestOperation alloc] init];
    [to1 setQueuePriority:CPOperationQueuePriorityVeryLow];
    [to1 setValue:@"very low"];
    var to2 = [[TestOperation alloc] init];
    [to2 setQueuePriority:CPOperationQueuePriorityVeryHigh];
    [to2 setValue:@"very high"];
    var to3 = [[TestOperation alloc] init];
    [to3 setValue:@"normal"]
    var to4 = [[TestOperation alloc] init];
    [to4 setQueuePriority:CPOperationQueuePriorityLow];
    [to4 setValue:@"low"];
    var to5 = [[TestOperation alloc] init];
    [to5 setQueuePriority:CPOperationQueuePriorityHigh];
    [to5 setValue:@"high"];
    var to6 = [[TestOperation alloc] init];
    [to6 setValue:@"also normal"];

    globalResults = [];
    [oq addOperations:[to3, to4, to5, to6] waitUntilFinished:NO];

    [oq waitUntilAllOperationsAreFinished];

    [self assertTrue:[to3 isFinished]];
    [self assertTrue:[to4 isFinished]];
    [self assertTrue:[to5 isFinished]];
    [self assertTrue:[to6 isFinished]];
    [self assert:@"high" equals:globalResults[0]];
    [self assert:@"normal" equals:globalResults[1]];
    [self assert:@"also normal" equals:globalResults[2]];
    [self assert:@"low" equals:globalResults[3]];

    globalResults = [];
    [oq addOperation:to1];
    [oq addOperation:to2];
    [oq waitUntilAllOperationsAreFinished];
    [self assert:@"very high" equals:globalResults[0]];
    [self assert:@"very low" equals:globalResults[1]];
}

- (void)testAddOperationWithFunction
{
    var oq = [[CPOperationQueue alloc] init];
    globalResults = [];

    [oq addOperationWithFunction:function() {globalResults.push("Soylent");}];
    [oq waitUntilAllOperationsAreFinished];
    [self assert:@"Soylent" equals:globalResults[0]];
}

- (void)testKVO
{
    var oq = [[CPOperationQueue alloc] init],
        obs = [[TestObserver alloc] init];

    [oq addObserver:obs
         forKeyPath:@"operations"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [oq addObserver:obs
         forKeyPath:@"operationCount"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [oq addObserver:obs
         forKeyPath:@"suspended"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [oq addObserver:obs
         forKeyPath:@"name"
            options:(CPKeyValueObservingOptionNew)
            context:NULL];

    [oq addOperationWithFunction:function() {globalResults.push("Soylent");}];
    [self assert:@"operations" equals:[[obs changedKeyPaths] objectAtIndex:0]];
    [self assert:@"operationCount" equals:[[obs changedKeyPaths] objectAtIndex:1]];

    [oq setSuspended:YES];
    [self assert:@"suspended" equals:[[obs changedKeyPaths] objectAtIndex:2]];
    [oq setSuspended:NO];
    [self assert:@"suspended" equals:[[obs changedKeyPaths] objectAtIndex:3]];

    [oq setName:@"Soylent"];
    [self assert:@"name" equals:[[obs changedKeyPaths] objectAtIndex:4]];
}

@end