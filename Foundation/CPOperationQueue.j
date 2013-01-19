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
 */

@import "CPArray.j"
@import "CPFunctionOperation.j"
@import "CPInvocationOperation.j"
@import "CPObject.j"
@import "CPOperation.j"
@import "CPString.j"
@import "CPTimer.j"

// the global queue (mainQueue)
var cpOperationMainQueue = nil;

/*!
    @class CPOperationQueue
    @brief Represents an operation queue that can run CPOperations
*/
@implementation CPOperationQueue : CPObject
{
    CPArray _operations;
    BOOL _suspended;
    CPString _name @accessors(property=name);
    CPTimer _timer;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _operations = [[CPArray alloc] init];
        _suspended = NO;
//        _currentlyModifyingOps = NO;
        _timer = [CPTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(_runNextOpsInQueue)
                                                userInfo:nil
                                                 repeats:YES];
    }
    return self;
}

- (void)_runNextOpsInQueue
{
    if (!_suspended && [self operationCount] > 0)
    {
        var i = 0,
            count = [_operations count];

        for (; i < count; i++)
        {
            var op = [_operations objectAtIndex:i];
            if ([op isReady] && ![op isCancelled] && ![op isFinished] && ![op isExecuting])
            {
                [op start];
            }
        }
    }
}

- (void)_enableTimer:(BOOL)enable
{
    if (!enable)
    {
        if (_timer)
        {
            [_timer invalidate];
            _timer = nil;
        }
    }
    else
    {
        if (!_timer)
        {
            _timer = [CPTimer scheduledTimerWithTimeInterval:0.01
                                                      target:self
                                                    selector:@selector(_runNextOpsInQueue)
                                                    userInfo:nil
                                                     repeats:YES];
        }
    }
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
    [self didChangeValueForKey:@"operations"];
    [self didChangeValueForKey:@"operationCount"];
}

/*!
    Adds the specified array of operations to the queue.
    @param ops The array of CPOperation objects that you want to add to the receiver.
    @param wait If YES, the method only returns once all of the specified operations finish executing. If NO, the operations are added to the queue and control returns immediately to the caller.
*/
- (void)addOperations:(CPArray)ops waitUntilFinished:(BOOL)wait
{
    if (ops)
    {
        if (wait)
        {
            [self _sortOpsByPriority:ops];
            [self _runOpsSynchronously:ops];
        }

        [_operations addObjectsFromArray:ops];
        [self _sortOpsByPriority:_operations];
    }
}

/*!
    Wraps the given js function in a CPOperation and adds it to the queue
    @param aFunction the JS function to add
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
    if (_operations)
    {
        return [_operations count];
    }

    return 0;
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
*/
- (void)waitUntilAllOperationsAreFinished
{
    // lets first stop the timer so it won't interfere
    [self _enableTimer:NO];
    [self _runOpsSynchronously:_operations];
    if (!_suspended)
    {
        [self _enableTimer:YES];
    }
}


/*!
    Returns the maximum number of concurrent operations that the receiver can execute.
    Always returns 1 because JS doesn't have threads
*/
- (int)maxConcurrentOperationCount
{
    return 1;
}

/*!
    Modifies the execution of pending operations
    @param suspend if YES, queue execution is suspended. If NO, it is resumed
*/
- (void)setSuspended:(BOOL)suspend
{
    _suspended = suspend;
    [self _enableTimer:!suspend];
}

/*!
    Returns a Boolean value indicating whether the receiver is scheduling queued operations for execution.
*/
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
            if ([lhs queuePriority] < [rhs queuePriority])
            {
                return 1;
            }
            else
            {
                if ([lhs queuePriority] > [rhs queuePriority])
                {
                    return -1;
                }
                else
                {
                    return 0;
                }
            }
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
                if ([op isReady] && ![op isCancelled] && ![op isFinished] && ![op isExecuting])
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
