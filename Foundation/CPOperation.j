/*
 * CPOperation.j
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
@import "CPObject.j"

@global CPKeyValueObservingOptionNew

/*!
    Operations receive very low priority for execution.
    @global
    @group CPOperationQueuePriority
*/
CPOperationQueuePriorityVeryLow     = -8;

/*!
    Operations receive low priority for execution.
    @global
    @group CPOperationQueuePriority
*/
CPOperationQueuePriorityLow         = -4;

/*!
    Operations receive normal priority for execution.
    @global
    @group CPOperationQueuePriority
*/
CPOperationQueuePriorityNormal      = 0;

/*!
    Operations receive high priority for execution.
    @global
    @group CPOperationQueuePriority
*/
CPOperationQueuePriorityHigh        = 4;

/*!
    Operations receive very high priority for execution.
    @global
    @group CPOperationQueuePriority
*/
CPOperationQueuePriorityVeryHigh    = 8;


/*!
    @class CPOperation
    @brief Represents an operation that can be run in an CPOperationQueue

    It should be subclassed an the subclass should implement its own main method to do the actual work.
*/
@implementation CPOperation : CPObject
{
    CPArray operations;
    BOOL _cancelled;
    BOOL _executing;
    BOOL _finished;
    BOOL _ready;
    int _queuePriority;
    JSObject _completionFunction;
    CPArray _dependencies;
}

- (void)main
{
    // should be overridden in child class
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _cancelled = NO;
        _executing = NO;
        _finished = NO;
        _ready = YES;
        _dependencies = [[CPArray alloc] init];
        _queuePriority = CPOperationQueuePriorityNormal;
    }
    return self;
}

/*!
    Starts the operation (runs the main method), sets all the status flags and runs the completion function if it's set
*/
- (void)start
{
    if (!_cancelled)
    {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self main];
        if (_completionFunction)
        {
            _completionFunction();
        }
        [self willChangeValueForKey:@"isExecuting"];
        _executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}

/*!
    Indicates if this operation has been cancelled
    @return if this operation has been cancelled
*/
- (BOOL)isCancelled
{
    return _cancelled;
}

/*!
    Indicates if this operation is currently executing
    @return if this operation is currently executing
*/
- (BOOL)isExecuting
{
    return _executing;
}

/*!
    Indicates if this operation has finished running
    @return if this operation has finished running
*/
- (BOOL)isFinished
{
    return _finished;
}

/*!
    Just added for Cocoa compatibility
    @return always false
*/
- (BOOL)isConcurrent
{
    return NO;
}

/*!
    Indicates if this operation is ready to be executed. Takes the "isFinished" state of dependent operations into account
    @return if this operation is ready to run
*/
- (BOOL)isReady
{
    return _ready;
}

/*!
    The JS function that should be run after the main method
    @return JS function
*/
- (JSObject)completionFunction
{
    return _completionFunction;
}

/*!
    Sets the JS function that should be run after the main method
*/
- (void)setCompletionFunction:(JSObject)aJavaScriptFunction
{
    _completionFunction = aJavaScriptFunction;
}

/*!
    Makes the receiver dependent on the completion of the specified operation.
    @param anOperation the operation that the receiver should depend on
*/
- (void)addDependency:(CPOperation)anOperation
{
    [self willChangeValueForKey:@"dependencies"];
    [anOperation addObserver:self
                  forKeyPath:@"isFinished"
                     options:(CPKeyValueObservingOptionNew)
                     context:NULL];
    [_dependencies addObject:anOperation];
    [self didChangeValueForKey:@"dependencies"];
    [self _updateIsReadyState];
}

/*!
    Removes the receiver’s dependence on the specified operation.
    @param anOperation the operation that the receiver should no longer depend on
*/
- (void)removeDependency:(CPOperation)anOperation
{
    [self willChangeValueForKey:@"dependencies"];
    [_dependencies removeObject:anOperation];
    [anOperation removeObserver:self
                     forKeyPath:@"isFinished"];
    [self didChangeValueForKey:@"dependencies"];
    [self _updateIsReadyState];
}

/*!
    The operations that the receiver depends on
    @return array of operations
*/
- (CPArray)dependencies
{
    return _dependencies;
}

/*!
    Just added for Cocoa compatibility, doesn't do anything
*/
- (void)waitUntilFinished
{
}

/*!
    Advises the operation object that it should stop executing its task.
*/
- (void)cancel
{
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = YES;
    [self didChangeValueForKey:@"isCancelled"];
}

/*!
    Sets the priority of the operation when used in an operation queue.
    @param priority the priority
*/
- (void)setQueuePriority:(int)priority
{
    _queuePriority = priority;
}

/*!
    The priority of the operation when used in an operation queue.
    @return the priority
*/
- (int)queuePriority
{
    return _queuePriority;
}

// We need to observe the "isFinished" key of our dependent operations so we can update our own "isReady" state
- (void)observeValueForKeyPath:(CPString)keyPath
                      ofObject:(id)object
                        change:(CPDictionary)change
                       context:(void)context
{
    if (keyPath == @"isFinished")
    {
        [self _updateIsReadyState];
    }
}

- (void)_updateIsReadyState
{
    var newReady = YES;
    if (_dependencies && [_dependencies count] > 0)
    {
        var i = 0;
        for (i = 0; i < [_dependencies count]; i++)
        {
            if (![[_dependencies objectAtIndex:i] isFinished])
            {
                newReady = NO;
            }
        }
    }

    if (newReady != _ready)
    {
        [self willChangeValueForKey:@"isReady"];
        _ready = newReady;
        [self didChangeValueForKey:@"isReady"];
    }
}

@end
