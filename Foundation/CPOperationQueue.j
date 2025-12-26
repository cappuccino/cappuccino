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
// CPPromiseOperation
// A helper class to wrap JS Promises/Async functions into a CPOperation
// --------------------------------------------------------------------------------
@implementation CPPromiseOperation : CPOperation
{
    BOOL        _executing;
    BOOL        _finished;
    JSObject    _promiseFactory;
}

/*!
    Creates an operation that executes a JS function returning a Promise.
    Example:
    [CPPromiseOperation operationWithPromiseFactory:function() {
        return fetch('/api/data').then(r => r.json());
    }];
*/
+ (CPPromiseOperation)operationWithPromiseFactory:(JSObject)aFactory
{
    return [[self alloc] initWithPromiseFactory:aFactory];
}

- (id)initWithPromiseFactory:(JSObject)aFactory
{
    self = [super init];
    if (self)
    {
        _promiseFactory = aFactory;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (void)start
{
    if ([self isCancelled])
    {
        [self _finish];
        return;
    }

    // Mark as executing
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    // Run the factory to get the promise
    var promise = _promiseFactory();

    // If the factory didn't return a promise (synchronous result), handle gracefully
    if (!promise || typeof promise.then !== 'function')
    {
        [self _finish];
        return;
    }

    // Handle Promise resolution
    promise.then(function() {
        [self _finish];
    }).catch(function(err) {
        CPLog.error("CPPromiseOperation Error: " + err);
        [self _finish];
    });
}

- (void)_finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _executing = NO;
    _finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting { return _executing; }
- (BOOL)isFinished  { return _finished; }
// Concurrent is YES so it runs alongside the runloop (doesn't block the UI)
- (BOOL)isConcurrent { return YES; }

@end


// --------------------------------------------------------------------------------
// CPOperationQueue
// --------------------------------------------------------------------------------
@implementation CPOperationQueue : CPObject
{
    CPArray _operations;
    BOOL    _suspended;
    int     _maxConcurrentOperationCount;
    CPString _name @accessors(property=name);
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
    Adds an operation and returns a JavaScript Promise that resolves
    when the operation finishes.
    
    Usage in Async function:
    await [queue addOperationAwaitable:myOp];
*/
- (JSObject)addOperationAwaitable:(CPOperation)anOperation
{
    return new Promise(function(resolve, reject) {
        
        var observer = [[CPObject alloc] init];
        
        // Create a temporary observer to bridge Obj-J KVO to JS Promise
        observer.observeValueForKeyPath_ofObject_change_context = function(keyPath, object, change, context)
        {
            if (keyPath === "isFinished" && [object isFinished])
            {
                [object removeObserver:observer forKeyPath:@"isFinished"];
                resolve(object);
            }
            else if ([object isCancelled])
            {
                [object removeObserver:observer forKeyPath:@"isFinished"];
                reject("Operation Cancelled");
            }
        };
        
        [anOperation addObserver:observer
                      forKeyPath:@"isFinished" 
                         options:CPKeyValueObservingOptionNew 
                         context:nil];
                         
        [self addOperation:anOperation];
    });
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

/*!
    Adds the specified array of operations to the queue.
*/
- (void)addOperations:(CPArray)ops waitUntilFinished:(BOOL)wait
{
    if (ops)
    {
        if (wait)
        {
            // Note: This blocks synchronously. It will NOT wait for 
            // CPPromiseOperations correctly as they return execution immediately.
            // Use addOperationAwaitable if you need to wait for async ops.
            [self _sortOpsByPriority:ops];
            [self _runOpsSynchronously:ops];
        }

        var i = 0;
        for (; i < [ops count]; i++)
        {
            [self addOperation:[ops objectAtIndex:i]];
        }
    }
}

/*!
    Wraps the given js function in a CPOperation and adds it to the queue
*/
- (void)addOperationWithFunction:(JSObject)aFunction
{
    [self addOperation:[CPFunctionOperation functionOperationWithFunction:aFunction]];
}

- (CPArray)operations
{
    return _operations;
}

- (int)operationCount
{
    return _operations ? [_operations count] : 0;
}

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
    Deprecated in favor of async/await patterns, but kept for compatibility.
    Be careful: this loops synchronously and can freeze the browser if ops take long.
*/
- (void)waitUntilAllOperationsAreFinished
{
    [self _runOpsSynchronously:_operations];
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
    Convenience method for one system wide singleton queue.
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

+ (CPOperationQueue)currentQueue
{
    return [CPOperationQueue mainQueue];
}

@end
