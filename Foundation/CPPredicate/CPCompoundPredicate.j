@import "CPPredicate.j"
@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>

/*!
    A predicate to compare directly the left and right hand sides.
    @global
    @class CPCompoundPredicate
*/
CPNotPredicateType = 0;
/*!
    A predicate to compare directly the left and right hand sides.
    @global
    @class CPCompoundPredicate
*/
CPAndPredicateType = 1;
/*!
    A predicate to compare directly the left and right hand sides.
    @global
    @class CPCompoundPredicate
*/
CPOrPredicateType  = 2;

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
    _type = type;
    _predicates = predicates;

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
        count = [subp count];
        i;

    for (i = 0; i < count; i++)
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
        i;

    if (count == 0)
        return @"TRUPREDICATE";

    for (i = 0; i < count; i++)
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
        case CPNotPredicateType:
            result += "NOT %s" + [args objectAtIndex:0];
            break;
        case CPAndPredicateType:
            result += [args objectAtIndex:0];
            var count = [args count];
            for (var j = 1; j < count; j++)
                result += " AND " + [args objectAtIndex:j];
            break;
        case CPOrPredicateType:
            result += [args objectAtIndex:0];
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
        i;

    if (count == 0)
        return YES;

    for (i = 0; i < count; i++)
    {
        var predicate = [_predicates objectAtIndex:i];

        switch (_type)
        {
            case CPNotPredicateType:
                return ![predicate evaluateWithObject:object substitutionVariables:variables];
            case CPAndPredicateType:
                if (i == 0)
                    result = [predicate evaluateWithObject:object substitutionVariables:variables];
                else
                    result = result && [predicate evaluateWithObject:object substitutionVariables:variables];
                if (!result)
                    return NO;
                break;
            case CPOrPredicateType:
                if ([predicate evaluateWithObject:object substitutionVariables:variables])
                    return YES;
                break;
        }
    }

    return result;
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
