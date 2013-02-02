/*
 * CPCompoundPredicate.j
 *
 * Portions based on NSCompoundPredicate.m in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by cacaodev.
 * Copyright 2010.
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

@import "CPCompoundPredicate_Constants.j"
@import "CPArray.j"
@import "_CPPredicate.j"

var CPCompoundPredicateType;

/*!
    @class CPCompoundPredicate
    @ingroup foundation
    @brief CPCompoundPredicate is a subclass of CPPredicate used to represent logical “gate” operations (AND/OR/NOT) and comparison operations.

    Comparison operations are based on two expressions, as represented by instances of the CPExpression class. Expressions are created for constant values, key paths, and so on.

    A compound predicate with 0 elements evaluates to TRUE, and a compound predicate with a single sub-predicate evaluates to the truth of its sole subpredicate.
*/
@implementation CPCompoundPredicate : CPPredicate
{
    CPCompoundPredicateType _type;
    CPArray                 _predicates;
}

// Constructors
/*!
    Returns the receiver initialized to a given type using predicates from a given array.
    @param type The type of the new predicate.
    @return The receiver initialized with its type set to type and subpredicates array to subpredicates.
*/
- (id)initWithType:(CPCompoundPredicateType)type subpredicates:(CPArray)predicates
{
    self = [super init];

    if (self)
    {
        _type = type;
        _predicates = predicates;
    }

    return self;
}

/*!
    Returns a new predicate formed by NOT-ing the predicates in a given array.
    @param subpredicates An array of CPPredicate objects.
    @return A new predicate formed by NOT-ing the predicates specified by subpredicates.
*/
+ (CPPredicate)notPredicateWithSubpredicate:(CPPredicate)predicate
{
    return [[self alloc] initWithType:CPNotPredicateType subpredicates:[CPArray arrayWithObject:predicate]];
}

/*!
    Returns a new predicate formed by AND-ing the predicates in a given array.
    @param subpredicates An array of CPPredicate objects.
    @return A new predicate formed by AND-ing the predicates specified by subpredicates.
*/
+ (CPPredicate)andPredicateWithSubpredicates:(CPArray)subpredicates
{
    return [[self alloc] initWithType:CPAndPredicateType subpredicates:subpredicates];
}

/*!
    Returns a new predicate formed by OR-ing the predicates in a given array.
    @param subpredicates An array of CPPredicate objects.
    @return A new predicate formed by OR-ing the predicates specified by subpredicates.
*/
+ (CPPredicate)orPredicateWithSubpredicates:(CPArray)predicates
{
    return [[self alloc] initWithType:CPOrPredicateType subpredicates:predicates];
}

// Getting Information About a Compound Predicate
/*!
    Returns the predicate type for the receiver.
    @return The predicate type for the receiver.
*/
- (CPCompoundPredicateType)compoundPredicateType
{
    return _type;
}

/*!
    Returns the array of the receiver’s subpredicates.
    @return The array of the receiver’s subpredicates.
*/
- (CPArray)subpredicates
{
    return _predicates;
}

- (CPPredicate)predicateWithSubstitutionVariables:(CPDictionary)variables
{
    var subp = [CPArray array],
        count = [subp count],
        i = 0;

    for (; i < count; i++)
    {
        var p = [subp objectAtIndex:i],
            sp = [p predicateWithSubstitutionVariables:variables];

        [subp addObject:sp];
    }

    return [[CPCompoundPredicate alloc] initWithType:_type subpredicates:subp];
}

- (CPString)predicateFormat
{
    var result = "",
        args = [CPArray array],
        count = [_predicates count],
        i = 0;

    if (count == 0)
        return @"TRUEPREDICATE";

    for (; i < count; i++)
    {
        var subpredicate = [_predicates objectAtIndex:i],
            precedence = [subpredicate predicateFormat];

        if ([subpredicate isKindOfClass:[CPCompoundPredicate class]] && [[subpredicate subpredicates] count]> 1 && [subpredicate compoundPredicateType] != _type)
            precedence = [CPString stringWithFormat:@"(%s)",precedence];

        if (precedence != nil)
            [args addObject:precedence];
    }

    switch (_type)
    {
        case CPNotPredicateType:    result += "NOT " + [args objectAtIndex:0];
                                    break;

        case CPAndPredicateType:    result += [args objectAtIndex:0];
                                    var count = [args count];
                                    for (var j = 1; j < count; j++)
                                        result += " AND " + [args objectAtIndex:j];
                                    break;

        case CPOrPredicateType:     result += [args objectAtIndex:0];
                                    var count = [args count];
                                    for (var j = 1; j < count; j++)
                                        result += " OR " + [args objectAtIndex:j];
                                    break;
    }

    return result;
}

- (BOOL)evaluateWithObject:(id)object
{
    return [self evaluateWithObject:object substitutionVariables:nil];
}

- (BOOL)evaluateWithObject:(id)object substitutionVariables:(CPDictionary)variables
{
    var result = NO,
        count = [_predicates count],
        i = 0;

    if (count == 0)
        return YES;

    for (; i < count; i++)
    {
        var predicate = [_predicates objectAtIndex:i];

        switch (_type)
        {
            case CPNotPredicateType:    return ![predicate evaluateWithObject:object substitutionVariables:variables];

            case CPAndPredicateType:    if (i == 0)
                                            result = [predicate evaluateWithObject:object substitutionVariables:variables];
                                        else
                                            result = result && [predicate evaluateWithObject:object substitutionVariables:variables];
                                        if (!result)
                                            return NO;
                                        break;

            case CPOrPredicateType:     if ([predicate evaluateWithObject:object substitutionVariables:variables])
                                            return YES;
                                        break;
        }
    }

    return result;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (anObject.isa !== self.isa || _type !== [anObject compoundPredicateType] || ![_predicates isEqualToArray:[anObject subpredicates]])
        return NO;

    return YES;
}

@end

@implementation CPCompoundPredicate (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    self = [super init];
    if (self != nil)
    {
        _predicates = [coder decodeObjectForKey:@"CPCompoundPredicateSubpredicates"];
        _type = [coder decodeIntForKey:@"CPCompoundPredicateType"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_predicates forKey:@"CPCompoundPredicateSubpredicates"];
    [coder encodeInt:_type forKey:@"CPCompoundPredicateType"];
}

@end
