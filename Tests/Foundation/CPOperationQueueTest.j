@import <Foundation/CPOperationQueue.j>
@import <Foundation/CPFunctionOperation.j>

// Global accumulator for side-effect testing
var globalResults = [];

// --------------------------------------------------------------------------------
// Helper: TestOperation
// A simple operation that sets a value and pushes to globalResults.
// --------------------------------------------------------------------------------
@implementation TestOperation : CPOperation
{
    CPString name @accessors;
    CPString value @accessors;
}

- (void)main
{
    [self setName:@"test"];
    if ([self value])
        globalResults.push([self value]);
}
@end

// --------------------------------------------------------------------------------
// Helper: TestCancelOperation
// Used to test cancellation states.
// --------------------------------------------------------------------------------
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

// --------------------------------------------------------------------------------
// Helper: TestObserver
// Used to verify KVO notifications.
// --------------------------------------------------------------------------------
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

- (void)observeValueForKeyPath:(CPString)keyPath
                      ofObject:(id)object
                        change:(CPDictionary)change
                       context:(id)context
{
    [changedKeyPaths addObject:keyPath];
}
@end

// --------------------------------------------------------------------------------
// Test Suite
// --------------------------------------------------------------------------------
@implementation CPOperationQueueTest : OJTestCase

- (void)setUp
{
    // Reset global state before each test
    globalResults = [];
}

// -------------------------------------------------------
// Legacy / Synchronous Tests
// -------------------------------------------------------

- (void)testAddOperation
{
    var oq = [[CPOperationQueue alloc] init],
        to = [[TestOperation alloc] init];

    [self assert:0 equals:[oq operationCount]];
    [oq addOperation:to];

    // Note: With the new KVO design, operations run on the next tick (setTimeout 0).
    // So operationCount is 1 immediately, but it finishes slightly later.
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
    
    // Legacy behavior: This blocks synchronously because we haven't awaited it 
    // and standard operations are synchronous in 'main'.
    // However, the modernization logic wraps execution. 
    // Ideally, for strict legacy compliance, we rely on _runOpsSynchronously being called internally.
    [oq addOperations:[to1, to2, to3] waitUntilFinished:YES];

    [self assertTrue:[to1 isFinished]];
    [self assertTrue:[to2 isFinished]];
    [self assertTrue:[to3 isFinished]];
    
    [self assert:3 equals:[oq operationCount]]; 
    // Note: operationCount usually doesn't decrease automatically in legacy Obj-J 
    // unless the array is mutated, but [oq operations] holds the references.
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
    
    // Add normally (async start via KVO)
    [oq addOperations:[to3, to4, to5, to6] waitUntilFinished:NO];

    // Force Wait (Legacy Sync Block)
    [oq waitUntilAllOperationsAreFinished];

    [self assertTrue:[to3 isFinished]];
    [self assertTrue:[to4 isFinished]];
    [self assertTrue:[to5 isFinished]];
    [self assertTrue:[to6 isFinished]];
    
    // Verify Priority Order
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

- (void)testKVO
{
    var oq = [[CPOperationQueue alloc] init],
        obs = [[TestObserver alloc] init];

    [oq addObserver:obs forKeyPath:@"operations" options:(CPKeyValueObservingOptionNew) context:NULL];
    [oq addObserver:obs forKeyPath:@"operationCount" options:(CPKeyValueObservingOptionNew) context:NULL];
    [oq addObserver:obs forKeyPath:@"suspended" options:(CPKeyValueObservingOptionNew) context:NULL];
    [oq addObserver:obs forKeyPath:@"name" options:(CPKeyValueObservingOptionNew) context:NULL];

    [oq addOperationWithFunction:function() { globalResults.push("Soylent"); }];
    
    // Wait for ops to flush
    [oq waitUntilAllOperationsAreFinished];

    [self assert:@"operations" equals:[[obs changedKeyPaths] objectAtIndex:0]];
    [self assert:@"operationCount" equals:[[obs changedKeyPaths] objectAtIndex:1]];

    [oq setSuspended:YES];
    [self assert:@"suspended" equals:[[obs changedKeyPaths] objectAtIndex:2]];
    [oq setSuspended:NO];
    [self assert:@"suspended" equals:[[obs changedKeyPaths] objectAtIndex:3]];

    [oq setName:@"Soylent"];
    [self assert:@"name" equals:[[obs changedKeyPaths] objectAtIndex:4]];
}

// -------------------------------------------------------
// Modern / Async Tests
// -------------------------------------------------------

- (void)testAddOperationAsync
{
    var oq = [[CPOperationQueue alloc] init],
        op = [[TestOperation alloc] init];
    
    [op setValue:@"AsyncResult"];

    // We define an async wrapper to test the Promise behavior
    var runTest = async function() {
        try {
            var finishedOp = await [oq addOperationAsync:op];
            
            [self assertTrue:[finishedOp isFinished] message:"addOperationAsync: should resolve with finished op"];
            [self assert:@"AsyncResult" equals:[finishedOp value] message:"Result value should match"];
            [self assert:1 equals:globalResults.length];
        } catch (e) {
            [self fail:"addOperationAsync threw exception: " + e];
        }
    };
    
    // Execute
    runTest();
}

- (void)testCPFunctionOperationPromiseSupport
{
    var oq = [[CPOperationQueue alloc] init];
    globalResults = [];

    var runTest = async function() {
        
        // Add a function that returns a Promise (simulation of fetch/timeout)
        [oq addOperationWithFunction:function() {
            return new Promise(function(resolve) {
                setTimeout(function() {
                    globalResults.push("PromiseResolved");
                    resolve();
                }, 50);
            });
        }];
        
        // Wait for queue to empty asynchronously
        await [oq waitUntilAllOperationsAreFinishedAsync];
        
        [self assert:@"PromiseResolved" equals:globalResults[0] message:"CPFunctionOperation did not wait for Promise resolution"];
    };
    
    runTest();
}

- (void)testAddOperationsWaitUntilFinishedAsync
{
    var oq = [[CPOperationQueue alloc] init];
    var op1 = [[TestOperation alloc] init];
    var op2 = [[TestOperation alloc] init];
    
    [op1 setValue:@"One"];
    [op2 setValue:@"Two"];

    var runTest = async function() {
        
        // Modern usage: await the method when wait=YES
        await [oq addOperations:[op1, op2] waitUntilFinished:YES];
        
        [self assertTrue:[op1 isFinished] message:"Op1 should be finished after await"];
        [self assertTrue:[op2 isFinished] message:"Op2 should be finished after await"];
        [self assert:2 equals:globalResults.length];
    };
    
    runTest();
}

- (void)testWaitUntilAllOperationsAreFinishedAsync
{
    var oq = [[CPOperationQueue alloc] init];
    
    // Add 3 operations that take random time
    for (var i = 0; i < 3; i++) {
        [oq addOperationWithFunction:function() {
            return new Promise(function(resolve) {
                setTimeout(function() { globalResults.push(i); resolve(); }, 10);
            });
        }];
    }
    
    var runTest = async function() {
        
        [self assert:[oq operationCount] > 0 message:"Queue should have ops"];
        
        // Wait for empty
        await [oq waitUntilAllOperationsAreFinishedAsync];
        
        [self assert:0 equals:[oq operationCount] message:"Queue should be empty after await"];
        [self assert:3 equals:globalResults.length message:"All 3 ops should have executed"];
    };
    
    runTest();
}

- (void)testCancellationWithAsync
{
    var oq = [[CPOperationQueue alloc] init],
        op = [[TestOperation alloc] init];
        
    var runTest = async function() {
        
        // Schedule it
        var promise = [oq addOperationAsync:op];
        
        // Cancel immediately
        [op cancel];
        
        try {
            await promise;
            [self fail:"Should have thrown exception on cancellation"];
        } catch (e) {
            [self assert:@"Operation Cancelled" equals:e message:"Should reject with cancellation message"];
        }
        
        [self assertTrue:[op isCancelled]];
    };
    
    runTest();
}

@end
