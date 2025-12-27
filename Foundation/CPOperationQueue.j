/*
 * CPOperationQueue.j
 *
 * Created by Johannes Fahrenkrug.
 * Copyright 2009, Springenwerk.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * Modernized with Promises, Async/Await support, and KVO-based triggering.
 */

@import "CPArray.j"
@import "CPFunctionOperation.j"
@import "CPInvocationOperation.j"
@import "CPObject.j"
@import "CPOperation.j"
@import "CPString.j"

// the global queue (mainQueue)
var cpOperationMainQueue = nil;

// --------------------------------------------------------------------------------
// _CPOperationAwaiter
// A private helper class to bridge KVO notifications to a JS Promise.
// Handles both single operation completion and queue draining.
// --------------------------------------------------------------------------------
@implementation _CPOperationAwaiter : CPObject
{
    JSObject    _resolve;
    JSObject    _reject;
}

- (id)initWithResolve:(JSObject)resolve reject:(JSObject)reject
{
    self = [super init];
    if (self)
    {
        _resolve = resolve;
        _reject = reject;
    }
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath 
                      ofObject:(id)object 
                        change:(CPDictionary)change 
                       context:(id)context
{
    // Case 1: Waiting for a specific Operation to finish
    if (keyPath === @"isFinished")
    {
        if ([object isFinished])
        {
            [object removeObserver:self forKeyPath:@"isFinished"];
            _resolve(object);
        }
        else if ([object isCancelled])
        {
            [object removeObserver:self forKeyPath:@"isFinished"];
            _reject("Operation Cancelled");
        }
    }
    // Case 2: Waiting for the Queue to empty
    else if (keyPath === @"operationCount")
    {
        if ([object operationCount] == 0)
        {
            [object removeObserver:self forKeyPath:@"operationCount"];
            _resolve(object);
        }
    }
}
@end


// --------------------------------------------------------------------------------
// CPOperationQueue
// --------------------------------------------------------------------------------

/*!
    @class CPOperationQueue
    @brief Represents an operation queue that can run CPOperations.
    @discussion This queue supports asynchronous operations via Promises/Async functions 
                and allows awaiting operation completion using standard JS async/await syntax.
*/
@implementation CPOperationQueue : CPObject
{
    CPArray     _operations;
    BOOL        _suspended;
    int         _maxConcurrentOperationCount;
    CPString    _name @accessors(property=name);
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _operations = [[CPArray alloc] init];
        _suspended = NO;
        // Default to serial execution (1 at a time). 
        // Increase this if you want multiple API calls running in parallel.
        _maxConcurrentOperationCount = 1; 
    }
    return self;
}

#pragma mark -
#pragma mark Execution Engine

/*!
    Logic to determine if we should start new operations.
    Triggered when an operation is added or when an operation finishes.
*/
- (void)_runNextOpsInQueue
{
    if (_suspended || [_operations count] == 0)
        return;

    // Use a timeout to break the call stack and let the UI update
    // if many operations finish/start rapidly.
    window.setTimeout(function() {
        
        // Check how many are currently running
        var runningCount = 0;
        var i = 0;
        var count = [_operations count];
        
        for (i = 0; i < count; i++)
        {
            if ([[_operations objectAtIndex:i] isExecuting])
                runningCount++;
        }

        // If we reached our max concurrency, stop starting new ones
        if (runningCount >= _maxConcurrentOperationCount)
            return;

        // Try to start pending operations
        for (i = 0; i < count; i++)
        {
            // Re-check concurrency limit inside the loop
            if (runningCount >= _maxConcurrentOperationCount)
                break;

            var op = [_operations objectAtIndex:i];
            
            if ([op isReady] && ![op isFinished] && ![op isExecuting])
            {
                [op start];
                runningCount++;
            }
        }
    }, 0);
}

/*!
    Internal KVO handler. When an operation finishes, we trigger the queue
    to look for the next operation.
*/
- (void)observeValueForKeyPath:(CPString)keyPath 
                      ofObject:(id)object 
                        change:(CPDictionary)change 
                       context:(id)context
{
    if (keyPath === @"isFinished" && [object isFinished])
    {
        // Stop observing the finished operation to prevent memory leaks
        [object removeObserver:self forKeyPath:@"isFinished"];
        
        // Trigger the queue to run the next item
        [self _runNextOpsInQueue];
    }
}

#pragma mark -
#pragma mark Adding Operations

/*!
    Adds the specified operation object to the receiver.
    @param anOperation the operation that should be scheduled for execution
*/
- (void)addOperation:(CPOperation)anOperation
{
    [self willChangeValueForKey:@"operations"];
    [self willChangeValueForKey:@"operationCount"];
    
    [_operations addObject:anOperation];
    [self _sortOpsByPriority:_operations];
    
    // IMPORTANT: Observe the operation so we know when to start the next one.
    // This replaces the old polling timer.
    [anOperation addObserver:self 
                  forKeyPath:@"isFinished" 
                     options:0 
                     context:nil];

    [self didChangeValueForKey:@"operations"];
    [self didChangeValueForKey:@"operationCount"];

    // Trigger execution
    [self _runNextOpsInQueue];
}

/*!
    Adds an operation and returns a Promise that resolves when the operation finishes.
    This allows you to 'await' the operation execution in the queue.
    
    Usage:
    try {
        var resultOp = await [queue addOperationAsync:myOp];
        console.log([resultOp result]);
    } catch (e) {
        console.log("Cancelled");
    }
*/
- (async JSObject)addOperationAsync:(CPOperation)anOperation
{
    return new Promise((resolve, reject) => {
        
        // Create our helper observer which holds the resolve/reject callbacks
        var awaiter = [[_CPOperationAwaiter alloc] initWithResolve:resolve reject:reject];
        
        // Add the observer for KVO
        [anOperation addObserver:awaiter
                      forKeyPath:@"isFinished" 
                         options:CPKeyValueObservingOptionNew 
                         context:nil];
                         
        // Add to queue to start execution
        [self addOperation:anOperation];
    });
}

/*!
    Adds the specified array of operations to the queue.
    @param ops The array of CPOperation objects that you want to add to the receiver.
    @param wait If YES, the method only returns once all of the specified operations finish executing. If NO, the operations are added to the queue and control returns immediately to the caller.
    @note When using modern asynchronous operations (Promises), you must use the `await` keyword when `wait` is YES to pause execution correctly.
*/
- (async JSObject)addOperations:(CPArray)ops waitUntilFinished:(BOOL)wait
{
    if (ops && [ops count] > 0)
    {
        if (wait)
        {
            // If waiting, we wrap every operation add in a Promise 
            // and return a Promise.all that waits for them all to finish.
            var promises = [];
            var i = 0;
            var count = [ops count];
            
            for (i = 0; i < count; i++)
            {
                // addOperationAsync adds it to the queue AND returns the promise
                promises.push([self addOperationAsync:[ops objectAtIndex:i]]);
            }
            
            return Promise.all(promises);
        }
        else
        {
            // If not waiting, just add them normally
            var i = 0;
            var count = [ops count];

            for (i = 0; i < count; i++)
            {
                [self addOperation:[ops objectAtIndex:i]];
            }
        }
    }
    
    // Return a resolved promise for void/wait=NO compatibility
    return Promise.resolve();
}

/*!
    Wraps the given js function in a CPOperation and adds it to the queue.
    @param aFunction the JS function to add. Can be a synchronous function or a function returning a Promise.
    @discussion This method automatically supports asynchronous functions/Promises because CPFunctionOperation is Promise-aware.
*/
- (void)addOperationWithFunction:(JSObject)aFunction
{
    [self addOperation:[CPFunctionOperation functionOperationWithFunction:aFunction]];
}

#pragma mark -
#pragma mark Queue Management

- (CPArray)operations
{
    return _operations;
}

- (int)operationCount
{
    return _operations ? [_operations count] : 0;
}

/*!
    Cancels all queued and executing operations.
*/
- (void)cancelAllOperations
{
    if (_operations)
    {
        var i = 0,
            count = [_operations count];

        for (; i < count; i++)
        {
            [[_operations objectAtIndex:i] cancel];
        }
    }
}

/*!
    Blocks until all of the receiver’s queued and executing operations finish executing.
    @warning This blocks the thread synchronously using a while loop. 
             It works for Sync operations but WILL FREEZE/DEADLOCK with Promises.
             Use 'await [queue waitUntilAllOperationsAreFinishedAsync]' instead.
*/
- (void)waitUntilAllOperationsAreFinished
{
    [self _runOpsSynchronously:_operations];
}

/*!
    Waits asynchronously until the queue is completely empty.
    Usage: await [queue waitUntilAllOperationsAreFinishedAsync];
*/
- (async JSObject)waitUntilAllOperationsAreFinishedAsync
{
    if ([self operationCount] == 0)
        return Promise.resolve();

    return new Promise((resolve, reject) => {
        
        var awaiter = [[_CPOperationAwaiter alloc] initWithResolve:resolve reject:reject];
        
        [self addObserver:awaiter
               forKeyPath:@"operationCount" 
                  options:CPKeyValueObservingOptionNew 
                  context:nil];
    });
}

- (int)maxConcurrentOperationCount
{
    return _maxConcurrentOperationCount;
}

- (void)setMaxConcurrentOperationCount:(int)count
{
    _maxConcurrentOperationCount = count;
}

- (void)setSuspended:(BOOL)suspend
{
    _suspended = suspend;
    if (!_suspended)
    {
        [self _runNextOpsInQueue];
    }
}

- (BOOL)isSuspended
{
    return _suspended;
}

#pragma mark -
#pragma mark Internal Helpers

- (void)_sortOpsByPriority:(CPArray)someOps
{
    if (someOps)
    {
        [someOps sortUsingFunction:function(lhs, rhs)
        {
            if ([lhs queuePriority] < [rhs queuePriority]) return 1;
            else if ([lhs queuePriority] > [rhs queuePriority]) return -1;
            else return 0;
        }
        context:nil];
    }
}

- (void)_runOpsSynchronously:(CPArray)ops
{
    if (ops)
    {
        var keepGoing = YES;
        while (keepGoing)
        {
            var i = 0,
                count = [ops count];

            keepGoing = NO;

            // start the ones that are ready
            for (; i < count; i++)
            {
                var op = [ops objectAtIndex:i];
                if ([op isReady] && ![op isFinished] && ![op isExecuting])
                {
                    [op start];
                }
            }

            // make sure they are all done
            for (i = 0; i < count; i++)
            {
                var op = [ops objectAtIndex:i];
                if (![op isFinished] && ![op isCancelled])
                {
                    keepGoing = YES;
                }
            }
        }
    }
}

/*!
    Convenience method for one system wide singleton queue. Returns the same queue as currentQueue.
*/
+ (CPOperationQueue)mainQueue
{
    if (!cpOperationMainQueue)
    {
        cpOperationMainQueue = [[CPOperationQueue alloc] init];
        [cpOperationMainQueue setName:@"main"];
    }
    return cpOperationMainQueue;
}

/*!
    Convenience method for one system wide singleton queue. Returns the same queue as mainQueue.
*/
+ (CPOperationQueue)currentQueue
{
    return [CPOperationQueue mainQueue];
}

@end
