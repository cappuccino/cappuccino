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

@import <Foundation/CPObject.j>
@import "CPOperation.j"


/*! 
    @class CPFunctionOperation
    @brief Represents an operation using a JavaScript function that can be run in an CPOperationQueue
*/
@implementation CPFunctionOperation : CPOperation 
{
    CPArray _functions;
}


- (void)main 
{
    if (_functions && [_functions count] > 0) 
    {
        var i = 0;
        for (i = 0; i < [_functions count]; i++) 
        {
            var func = [_functions objectAtIndex:i];
            func();
        }
    }
}

- (id)init 
{
    if (self = [super init]) 
    {
        _functions = [];
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
    Creates and returns an NSFunctionOperation object and adds the specified function to it.
*/
+ (id)functionOperationWithFunction:(JSObject)jsFunction 
{
    functionOp = [[CPFunctionOperation alloc] init];
    [functionOp addExecutionFunction:jsFunction];
    
    return functionOp;
}

@end