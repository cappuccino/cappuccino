/*
 * CPFunctionOperation.j
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
@import "CPOperation.j"

/*!
    @class CPFunctionOperation
    @brief Represents an operation using a JavaScript function (or Promise) that can be run in a CPOperationQueue.
    @discussion This operation supports both synchronous functions and functions that return a Promise. 
                If multiple functions are added, they are executed sequentially. If a function returns a Promise, 
                execution pauses until that Promise resolves.
*/
@implementation CPFunctionOperation : CPOperation
{
    CPArray     _functions;
    
    // Internal state for concurrent execution
    BOOL        _isExecuting;
    BOOL        _isFinished;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _functions = [];
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

/*!
    Adds the specified JS function to the receiver’s list of functions to perform.
*/
- (void)addExecutionFunction:(JSObject)jsFunction
{
    [_functions addObject:jsFunction];
}

/*!
    Returns an array containing the functions associated with the receiver.
*/
- (CPArray)executionFunctions
{
    return _functions;
}

/*!
    Creates and returns an CPFunctionOperation object and adds the specified function to it.
*/
+ (id)functionOperationWithFunction:(JSObject)jsFunction
{
    var functionOp = [[CPFunctionOperation alloc] init];
    [functionOp addExecutionFunction:jsFunction];
    return functionOp;
}

#pragma mark -
#pragma mark Concurrent Operation Overrides

// We must override start for async operations.
- (void)start
{
    if ([self isCancelled])
    {
        [self _finish];
        return;
    }

    // Move to executing state
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    // Begin execution chain
    [self _runNextFunction:0];
}

// Accessors for concurrent state (must use unique ivar names to avoid collision with CPOperation)
- (BOOL)isExecuting { return _isExecuting; }
- (BOOL)isFinished  { return _isFinished; }
- (BOOL)isConcurrent { return YES; }

#pragma mark -
#pragma mark Execution Logic

- (void)_runNextFunction:(int)index
{
    // 1. Check for cancellation or end of list
    if ([self isCancelled] || index >= [_functions count])
    {
        [self _finish];
        return;
    }

    // 2. Get the function
    var func = [_functions objectAtIndex:index];
    
    try {
        // 3. Execute the function
        var result = func();

        // 4. Check if it is a Promise (Duck typing)
        if (result && typeof result.then === 'function')
        {
            // It's async: Wait for it.
            result.then(function() {
                // Success: Run next
                [self _runNextFunction:index + 1];
            }).catch(function(err) {
                // Failure: Log and finish (or cancel)
                CPLog.error("CPFunctionOperation Async Error: " + err);
                [self _finish];
            });
        }
        else
        {
            // It's sync: Run next immediately
            // We use a specific pattern here to avoid deep recursion stack on many sync functions
            // but for simplicity in Obj-J, direct recursion or a setTimeout 0 is often safest.
            [self _runNextFunction:index + 1];
        }
    }
    catch (e)
    {
        CPLog.error("CPFunctionOperation Exception: " + e);
        [self _finish];
    }
}

- (void)_finish
{
    // Ensure we send KVO notifications so the Queue knows we are done
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
