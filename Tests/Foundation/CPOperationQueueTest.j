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

@implementation TestCancelOperation : CPOperation
{
    BOOL _started @accessors(getter=didStart);
    BOOL _mained @accessors(getter=didMain);
}

- (id)init
{
    self = [super init];
    _started = NO;
    _mained = NO;
    return self;
}

- (void)main
{
    _mained = YES;
}

- (void)start
{
    [super start];
    _started = YES;
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
    [to3 setValue:@"normal"];
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

- (void)testCancelledOperationDoesStart
{
    var op = [[TestCancelOperation alloc] init],
        queue = [[CPOperationQueue alloc] init];

    [self assertFalse:[op isCancelled]];
    [self assertFalse:[op isFinished]];
    [self assertFalse:[op didMain]];
    [self assertFalse:[op didStart]];

    [op cancel];

    [self assertTrue:[op isCancelled]];
    [self assertFalse:[op isFinished]];

    [queue addOperations:[op] waitUntilFinished:YES];

    [self assertFalse:[op didMain]];
    [self assertTrue:[op didStart]];
    [self assertTrue:[op isCancelled]];
    [self assertTrue:[op isFinished]];
}

// --------------------------------------------------------
// NEW: Promise and Async/Await Tests
// --------------------------------------------------------

- (void)testCPPromiseOperationBasics
{
    // Ensure the factory logic works and properties are set correctly
    var op = [CPPromiseOperation operationWithPromiseFactory:function() {
        return Promise.resolve(true);
    }];

    // Promise operations are concurrent (async)
    [self assertTrue:[op isConcurrent] message:"CPPromiseOperation should be concurrent"];
    
    // Should not be executing yet
    [self assertFalse:[op isExecuting]];
    [self assertFalse:[op isFinished]];
}

- (void)testAddOperationAwaitableReturnsPromise
{
    var oq = [[CPOperationQueue alloc] init],
        op = [[TestOperation alloc] init];

    // Call the new method
    var promise = [oq addOperationAwaitable:op];

    // Check that we actually got a JS Promise back
    [self assertTrue:(promise instanceof Promise) message:"addOperationAwaitable: should return a JS Promise"];
    
    // The operation should be in the queue
    [self assert:1 equals:[oq operationCount]];
}

- (void)testAsyncAwaitIntegration
{
    /*
        Because OJTestCase is typically synchronous, we cannot block the main thread 
        waiting for Promises. However, we can use an async function wrapper to 
        execute the assertions.
        
        NOTE: If your test runner kills the process immediately after the synchronous 
        methods finish, you might not see these assertions run.
    */

    var oq = [[CPOperationQueue alloc] init];
    globalResults = [];

    // Define an async function to use 'await' syntax
    var runAsyncTests = async function() {
        
        // 1. Test awaiting a standard operation (input/output sync)
        var op1 = [[TestOperation alloc] init];
        [op1 setValue:@"Async Standard"];
        
        // This should pause execution of this function until op1 finishes
        await [oq addOperationAwaitable:op1];
        
        [self assert:@"Async Standard" equals:[op1 value] message:"Standard Op value should be set"];
        [self assertTrue:[op1 isFinished] message:"Standard Op should be finished after await"];
        
        // 2. Test awaiting a Promise Operation (input/output async)
        var op2 = [CPPromiseOperation operationWithPromiseFactory:function() {
            return new Promise(function(resolve) {
                // Simulate network delay
                setTimeout(function() {
                    globalResults.push("Async Promise Result");
                    resolve();
                }, 20);
            });
        }];
        
        // This should pause execution until the inner timeout resolves
        await [oq addOperationAwaitable:op2];
        
        [self assert:@"Async Promise Result" equals:globalResults[0] message:"Global results should contain promise result"];
        [self assertTrue:[op2 isFinished] message:"Promise Op should be finished after await"];
        
        // 3. Test Rejection Handling
        var op3 = [CPPromiseOperation operationWithPromiseFactory:function() {
            return Promise.reject("Intentional Failure");
        }];
        
        await [oq addOperationAwaitable:op3];
        [self assertTrue:[op3 isFinished] message:"Rejected Op should still mark as finished"];
    };

    // Kick off the async test
    runAsyncTests();
}

@end
