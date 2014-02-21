/*
 * CPPredicate.j
 *
 * CPPredicate parsing based on NSPredicate.m in GNUStep Base Library (http://www.gnustep.org/)
 * Copyright (c) 2005 Free Software Foundation.
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

@import "CPArray.j"
@import "CPException.j"
@import "CPNull.j"
@import "CPObject.j"
@import "CPScanner.j"
@import "CPSet.j"
@import "CPValue.j"
@import "CPCharacterSet.j"
@import "CPComparisonPredicate_Constants.j"
@import "CPCompoundPredicate_Constants.j"
@import "_CPExpression.j"

@class CPCompoundPredicate
@class CPComparisonPredicate
@class _CPKeyPathExpression
@class _CPSubqueryExpression


/*!
    @ingroup foundation
    @class CPPredicate
    @brief The CPPredicate class is used to define logical conditions used to constrain a search either for a fetch or for in-memory filtering.

    You use predicates to represent logical conditions, used for describing objects in persistent stores
    and in-memory filtering of objects. Although it is common to create predicates directly from instances
    of CPComparisonPredicate, CPCompoundPredicate, and CPExpression, you often create predicates from a
    format string which is parsed by the class methods on CPPredicate. Examples of predicate format strings include:

    - Simple comparisons, such as <code>grade == "7"</code> or <code>firstName like "Shaffiq"</code>
    - Case/diacritic insensitive lookups, such as <code>name contains[cd] "itroen"</code>
    - Logical operations, such as <code>(firstName like "Mark") OR (lastName like "Adderley")</code>
    - “Between” predicates such as <code>date between {$YESTERDAY, $TOMORROW}</code>.

    You can create predicates for relationships, such as:

    - <code>group.name like "work*"</code>
    - <code>ALL children.age > 12</code>
    - <code>ANY children.age > 12</code>

    You can create predicates for operations, such as <code>\@sum.items.price < 1000</code>.

    You can also create predicates that include variables, so that the predicate can be pre-defined before
    substituting concrete values at runtime with the \c evaluateWithObject:substitutionVariables: method.
*/

@implementation CPPredicate : CPObject
{
}

/*!
    Creates and returns a new predicate formed by creating a new string with a given format and parsing the result.
    @param format The format string for the new predicate.
    @param … A comma-separated list of arguments to substitute into format.
    @return A new predicate formed by creating a new string with format and parsing the result.
*/
+ (CPPredicate)predicateWithFormat:(CPString)format, ...
{
    if (!format)
        [CPException raise:CPInvalidArgumentException reason:_cmd + " the format can't be 'nil'"];

    var args = Array.prototype.slice.call(arguments, 3);
    return [self predicateWithFormat:arguments[2] argumentArray:args];
}

/*!
    Creates and returns a new predicate by substituting the values in a given array into a format string and parsing the result.
    @param format The format string for the new predicate.
    @param arguments The arguments to substitute into predicateFormat. Values are substituted into predicateFormat in the order they appear in the array.
    @return A new predicate by substituting the values in arguments into predicateFormat, and parsing the result.
*/
+ (CPPredicate)predicateWithFormat:(CPString)format argumentArray:(CPArray)args
{
    if (!format)
        [CPException raise:CPInvalidArgumentException reason:_cmd + " the format can't be 'nil'"];

    var s = [[CPPredicateScanner alloc] initWithString:format args:args],
        p = [s parse];

    return p;
}

/*!
    Creates and returns a new predicate by substituting the values in an argument list into a format string and parsing the result.
    @param format The format string for the new predicate.
    @param argList The arguments to substitute into predicateFormat. Values are substituted into predicateFormat in the order they appear in the argument list.
    @return A new predicate by substituting the values in argList into predicateFormat and parsing the result.
*/
+ (CPPredicate)predicateWithFormat:(CPString)format arguments:(va_list)argList
{
    // UNIMPLEMENTED
    return nil;
}

/*!
    Returns a copy of the receiver with the receiver’s variables substituted by values specified in a given substitution variables dictionary.
    @param variables The substitution variables dictionary. The dictionary must contain key-value pairs for all variables in the receiver.
    @return A copy of the receiver with the receiver’s variables substituted by values specified in variables.
*/
- (CPPredicate)predicateWithSubstitutionVariables:(CPDictionary)variables
{
    // IMPLEMENTED BY SUBCLASSES
}

/*!
    Creates and returns a predicate that always evaluates to a given value.
    @param value The value to which the new predicate should evaluate.
    @return A predicate that always evaluates to value.
*/
+ (CPPredicate)predicateWithValue:(BOOL)value
{
    return [[CPPredicate_BOOL alloc] initWithBool:value];
}

// Evaluating a Predicate
/*!
    Returns a Boolean value that indicates whether a given object matches the conditions specified by the receiver.
    @param object The object against which to evaluate the receiver.
    @return YES if object matches the conditions specified by the receiver, otherwise NO.
*/
- (BOOL)evaluateWithObject:(id)object
{
    // IMPLEMENTED BY SUBCLASSES
}

/*!
    Returns a Boolean value that indicates whether a given object matches the conditions specified by the receiver after substituting in the values in a given variables dictionary.
    @param object The object against which to evaluate the receiver.
    @param variables The substitution variables dictionary. The dictionary must contain key-value pairs for all variables in the receiver.
    @return YES if object matches the conditions specified by the receiver after substituting in the values in variables for any replacement tokens, otherwise NO.
*/
- (BOOL)evaluateWithObject:(id)object substitutionVariables:(CPDictionary)variables
{
    // IMPLEMENTED BY SUBCLASSES
}

// Getting Format Information
/*!
    Returns the receiver’s format string.
    @return The receiver’s format string.
*/
- (CPString)predicateFormat
{
    // IMPLEMENTED BY SUBCLASSES
}

- (CPString)description
{
    return [self predicateFormat];
}

@end

@implementation CPPredicate_BOOL : CPPredicate
{
    BOOL _value;
}

- (id)initWithBool:(BOOL)value
{
    _value = value;
    return self;
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (anObject === nil || self.isa !== anObject.isa || _value !== [anObject evaluateWithObject:nil])
        return NO;

    return YES;
}

- (BOOL)evaluateWithObject:(id)object
{
    return _value;
}

- (BOOL)evaluateWithObject:(id)object substitutionVariables:(CPDictionary)variables
{
    return _value;
}

- (CPString)predicateFormat
{
    return (_value) ? @"TRUEPREDICATE" : @"FALSEPREDICATE";
}

@end


@implementation CPArray (CPPredicate)

- (CPArray)filteredArrayUsingPredicate:(CPPredicate)predicate
{
    var count = [self count],
        result = [CPArray array],
        i = 0;

    for (; i < count; i++)
    {
        var object = [self objectAtIndex:i];
        if ([predicate evaluateWithObject:object])
            result.push(object);
    }

    return result;
}

- (void)filterUsingPredicate:(CPPredicate)predicate
{
    var count = [self count];

    while (count--)
    {
        if (![predicate evaluateWithObject:[self objectAtIndex:count]])
            self.splice(count, 1);
    }
}

@end

@implementation CPSet (CPPredicate)

- (CPSet)filteredSetUsingPredicate:(CPPredicate)predicate
{
    var count = [self count],
        result = [CPSet set],
        i = 0;

    for (; i < count; i++)
    {
        var object = [self objectAtIndex:i];

        if ([predicate evaluateWithObject:object])
            [result addObject:object];
    }

    return result;
}

- (void)filterUsingPredicate:(CPPredicate)predicate
{
    var count = [self count];

    while (--count >= 0)
    {
        var object = [self objectAtIndex:count];

        if (![predicate evaluateWithObject:object])
            [self removeObjectAtIndex:count];
    }
}

@end

@implementation CPPredicateScanner : CPScanner
{
    CPEnumerator    _args;
    unsigned        _retrieved;
}

- (id)initWithString:(CPString)format args:(CPArray)args
{
    self = [super initWithString:format]

    if (self)
    {
        _args = [args objectEnumerator];
    }
    return self;
}

- (id)nextArg
{
    return [_args nextObject];
}

- (BOOL)scanPredicateKeyword:(CPString)key
{
    var loc = [self scanLocation];

    [self setCaseSensitive:NO];
    if (![self scanString:key intoString:NULL])
        return NO;

    if ([self isAtEnd])
        return YES;

    var c = [[self string] characterAtIndex:[self scanLocation]];
    if (![[CPCharacterSet alphanumericCharacterSet] characterIsMember:c])
        return YES;

    [self setScanLocation:loc];

    return NO;
}

- (CPPredicate)parse
{
    var r = nil;

    try
    {
        [self setCharactersToBeSkipped:[CPCharacterSet whitespaceCharacterSet]];
        r = [self parsePredicate];
    }
    catch(error)
    {
        CPLogConsole(@"Unable to parse predicate '" + [self string] + "' with " + error);
    }
    finally
    {
        if (![self isAtEnd])
        {
            var pstr = [self string],
                loc = [self scanLocation];
            CPLogConsole(@"Format string contains extra characters: '" + [pstr substringToIndex:loc] + "**" + [pstr substringFromIndex:loc] + "**'");
        }
    }

    return r;
}

- (CPPredicate)parsePredicate
{
    return [self parseAnd];
}

- (CPPredicate)parseAnd
{
    var l = [self parseOr];

    while ([self scanPredicateKeyword:@"AND"] || [self scanPredicateKeyword:@"&&"])
    {
        var r = [self parseOr];

        if ([r isKindOfClass:[CPCompoundPredicate class]] && [r compoundPredicateType] == CPAndPredicateType)
        {
            if ([l isKindOfClass:[CPCompoundPredicate class]] && [l compoundPredicateType] == CPAndPredicateType)
            {
                [[l subpredicates] addObjectsFromArray:[r subpredicates]];
            }
            else
            {
                [[r subpredicates] insertObject:l atIndex:0];
                l = r;
            }
        }
        else if ([l isKindOfClass:[CPCompoundPredicate class]] && [l compoundPredicateType] == CPAndPredicateType)
        {
            [[l subpredicates] addObject:r];
        }
        else
        {
            l = [CPCompoundPredicate andPredicateWithSubpredicates:[CPArray arrayWithObjects:l, r]];
        }
    }
    return l;
}

- (CPPredicate)parseNot
{
    if ([self scanString:@"(" intoString:NULL])
    {
        var r = [self parsePredicate];

        if (![self scanString:@")" intoString:NULL])
            CPRaiseParseError(self, @"predicate");

        return r;
    }

    if ([self scanPredicateKeyword:@"NOT"] || [self scanPredicateKeyword:@"!"])
    {
        return [CPCompoundPredicate notPredicateWithSubpredicate:[self parseNot]];
    }
    if ([self scanPredicateKeyword:@"TRUEPREDICATE"])
    {
        return [CPPredicate predicateWithValue:YES];
    }
    if ([self scanPredicateKeyword:@"FALSEPREDICATE"])
    {
        return [CPPredicate predicateWithValue:NO];
    }

    return [self parseComparison];
}

- (CPPredicate)parseOr
{
    var l = [self parseNot];
    while ([self scanPredicateKeyword:@"OR"] || [self scanPredicateKeyword:@"||"])
    {
        var r = [self parseNot];

        if ([r isKindOfClass:[CPCompoundPredicate class]] && [r compoundPredicateType] == CPOrPredicateType)
        {
            if ([l isKindOfClass:[CPCompoundPredicate class]] && [l compoundPredicateType] == CPOrPredicateType)
            {
                [[l subpredicates] addObjectsFromArray:[r subpredicates]];
            }
            else
            {
                [[r subpredicates] insertObject:l atIndex:0];
                l = r;
            }
        }
        else if ([l isKindOfClass:[CPCompoundPredicate class]] && [l compoundPredicateType] == CPOrPredicateType)
        {
            [[l subpredicates] addObject:r];
        }
        else
        {
            l = [CPCompoundPredicate orPredicateWithSubpredicates:[CPArray arrayWithObjects:l, r]];
        }
    }
    return l;
}

- (CPPredicate)parseComparison
{
    var modifier = CPDirectPredicateModifier,
        type = 0,
        opts = 0,
        left,
        right,
        p,
        negate = NO;

    if ([self scanPredicateKeyword:@"ANY"])
    {
        modifier = CPAnyPredicateModifier;
    }
    else if ([self scanPredicateKeyword:@"ALL"])
    {
        modifier = CPAllPredicateModifier;
    }
    else if ([self scanPredicateKeyword:@"NONE"])
    {
        modifier = CPAnyPredicateModifier;
        negate = YES;
    }
    else if ([self scanPredicateKeyword:@"SOME"])
    {
        modifier = CPAllPredicateModifier;
        negate = YES;
    }

    left = [self parseExpression];
    if ([self scanString:@"!=" intoString:NULL] || [self scanString:@"<>" intoString:NULL])
    {
        type = CPNotEqualToPredicateOperatorType;
    }
    else if ([self scanString:@"<=" intoString:NULL] || [self scanString:@"=<" intoString:NULL])
    {
        type = CPLessThanOrEqualToPredicateOperatorType;
    }
    else if ([self scanString:@">=" intoString:NULL] || [self scanString:@"=>" intoString:NULL])
    {
        type = CPGreaterThanOrEqualToPredicateOperatorType;
    }
    else if ([self scanString:@"<" intoString:NULL])
    {
        type = CPLessThanPredicateOperatorType;
    }
    else if ([self scanString:@">" intoString:NULL])
    {
        type = CPGreaterThanPredicateOperatorType;
    }
    else if ([self scanString:@"==" intoString:NULL] || [self scanString:@"=" intoString:NULL])
    {
        type = CPEqualToPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"MATCHES"])
    {
        type = CPMatchesPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"LIKE"])
    {
        type = CPLikePredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"BEGINSWITH"])
    {
        type = CPBeginsWithPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"ENDSWITH"])
    {
        type = CPEndsWithPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"IN"])
    {
        type = CPInPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"CONTAINS"])
    {
        type = CPContainsPredicateOperatorType;
    }
    else if ([self scanPredicateKeyword:@"BETWEEN"])
    {
        type = CPBetweenPredicateOperatorType;
    }
    else
        CPRaiseParseError(self, @"comparison predicate");

    if ([self scanString:@"[cd]" intoString:NULL])
    {
        opts = CPCaseInsensitivePredicateOption | CPDiacriticInsensitivePredicateOption;
    }
    else if ([self scanString:@"[c]" intoString:NULL])
    {
        opts = CPCaseInsensitivePredicateOption;
    }
    else if ([self scanString:@"[d]" intoString:NULL])
    {
        opts = CPDiacriticInsensitivePredicateOption;
    }

    right = [self parseExpression];

    p = [CPComparisonPredicate predicateWithLeftExpression:left
         rightExpression:right
         modifier:modifier
         type:type
         options:opts];

    return negate ? [CPCompoundPredicate notPredicateWithSubpredicate:p]:p;
}

- (CPExpression)parseExpression
{
    return [self parseBinaryExpression];
}

- (CPExpression)parseSimpleExpression
{
    var identifier,
        location,
        ident,
        dbl;

    if ([self scanDouble:@ref(dbl)])
        return [CPExpression expressionForConstantValue:dbl];

    // FIXME: handle integer, hex constants, 0x 0o 0b
    if ([self scanString:@"-" intoString:NULL])
        return [CPExpression expressionForFunction:@"chs:" arguments:[CPArray arrayWithObject:[self parseExpression]]];

    if ([self scanString:@"(" intoString:NULL])
    {
        var arg = [self parseExpression];

        if (![self scanString:@")" intoString:NULL])
            CPRaiseParseError(self, @"expression");

        return arg;
    }

    if ([self scanString:@"{" intoString:NULL])
    {
        var a = [];

        if ([self scanString:@"}" intoString:NULL])
            return [CPExpression expressionForConstantValue:a];

        [a addObject:[self parseExpression]];

        while ([self scanString:@"," intoString:NULL])
            [a addObject:[self parseExpression]];

        if (![self scanString:@"}" intoString:NULL])
            CPRaiseParseError(self, @"expression");

        return [CPExpression expressionForAggregate:a];
    }

    if ([self scanPredicateKeyword:@"NULL"] || [self scanPredicateKeyword:@"NIL"])
    {
        return [CPExpression expressionForConstantValue:[CPNull null]];
    }
    if ([self scanPredicateKeyword:@"TRUE"] || [self scanPredicateKeyword:@"YES"])
    {
        return [CPExpression expressionForConstantValue:[CPNumber numberWithBool:YES]];
    }
    if ([self scanPredicateKeyword:@"FALSE"] || [self scanPredicateKeyword:@"NO"])
    {
        return [CPExpression expressionForConstantValue:[CPNumber numberWithBool:NO]];
    }
    if ([self scanPredicateKeyword:@"SELF"])
    {
        return [CPExpression expressionForEvaluatedObject];
    }

    if ([self scanString:@"$" intoString:NULL])
    {
        var variable = [self parseSimpleExpression];

        if (![variable keyPath])
            CPRaiseParseError(self, @"expression");

        return [CPExpression expressionForVariable:variable];
    }

    location = [self scanLocation];

    if ([self scanString:@"%" intoString:NULL])
    {
        if ([self isAtEnd] == NO)
        {
            var c = [[self string] characterAtIndex:[self scanLocation]];

            switch (c)
            {
                case '%':// '%%' is treated as '%'
                    location = [self scanLocation];
                    break;
                case 'K':
                    [self setScanLocation:[self scanLocation] + 1];
                    return [CPExpression expressionForKeyPath:[self nextArg]];
                case '@':
                case 'c':
                case 'C':
                case 'd':
                case 'D':
                case 'i':
                case 'o':
                case 'O':
                case 'u':
                case 'U':
                case 'x':
                case 'X':
                case 'e':
                case 'E':
                case 'f':
                case 'g':
                case 'G':
                    [self setScanLocation:[self scanLocation] + 1];
                    return [CPExpression expressionForConstantValue:[self nextArg]];
                case 'h':
                    [self scanString:@"h" intoString:NULL];
                    if ([self isAtEnd] == NO)
                    {
                        c = [[self string] characterAtIndex:[self scanLocation]];
                        if (c == 'i' || c == 'u')
                        {
                            [self setScanLocation:[self scanLocation] + 1];
                            return [CPExpression expressionForConstantValue:[self nextArg]];
                        }
                    }
                    break;
                case 'q':
                    [self scanString:@"q" intoString:NULL];
                    if ([self isAtEnd] == NO)
                    {
                        c = [[self string] characterAtIndex:[self scanLocation]];
                        if (c == 'i' || c == 'u' || c == 'x' || c == 'X')
                        {
                            [self setScanLocation:[self scanLocation] + 1];
                            return [CPExpression expressionForConstantValue:[self nextArg]];
                        }
                    }
                    break;
            }
        }

        [self setScanLocation:location];
    }

    if ([self scanString:@"\"" intoString:NULL])
    {
        var skip = [self charactersToBeSkipped],
            str = @"";

        [self setCharactersToBeSkipped:nil];
        [self scanUpToString:@"\"" intoString:@ref(str)];

        if ([self scanString:@"\"" intoString:NULL] == NO)
            CPRaiseParseError(self, @"expression");

        [self setCharactersToBeSkipped:skip];

        return [CPExpression expressionForConstantValue:str];
    }

    if ([self scanString:@"'" intoString:NULL])
    {
        var skip = [self charactersToBeSkipped],
            str = @"";

        [self setCharactersToBeSkipped:nil];
        [self scanUpToString:@"'" intoString:@ref(str)];

        if ([self scanString:@"'" intoString:NULL] == NO)
            CPRaiseParseError(self, @"expression");

        [self setCharactersToBeSkipped:skip];

        return [CPExpression expressionForConstantValue:str];
    }

    if ([self scanString:@"@" intoString:NULL])
    {
        var e = [self parseExpression];

        if (![e keyPath])
            CPRaiseParseError(self, @"expression");

        return [CPExpression expressionForKeyPath:[e keyPath] + "@"];
    }

    if ([self scanString:@"SUBQUERY" intoString:NULL])
    {
        if (![self scanString:@"(" intoString:NULL])
            CPRaiseParseError(self, @"expression");

        var collection = [self parseExpression],
            variableExpression,
            subpredicate;

        if (![self scanString:@"," intoString:NULL])
            CPRaiseParseError(self, @"expression");
        variableExpression = [self parseExpression];

        if (![self scanString:@"," intoString:NULL])
            CPRaiseParseError(self, @"expression");
        subpredicate = [self parsePredicate];

        if (![self scanString:@")" intoString:NULL])
            CPRaiseParseError(self, @"expression");

        return [[_CPSubqueryExpression alloc] initWithExpression:collection usingIteratorExpression:variableExpression predicate:subpredicate];
    }

    if ([self scanString:@"FUNCTION" intoString:NULL])
    {
        if (![self scanString:@"(" intoString:NULL])
            CPRaiseParseError(self, @"expression");

        var args = [CPArray arrayWithObject:[self parseExpression]];
        while ([self scanString:@"," intoString:NULL])
            [args addObject:[self parseExpression]];

        if (![self scanString:@")" intoString:NULL] || [args count] < 2 || [args[1] expressionType] != CPConstantValueExpressionType)
            CPRaiseParseError(self, @"expression");

         return [CPExpression expressionForFunction:args[0] selectorName:[args[1] constantValue] arguments:args.slice(2)];
    }

    [self scanString:@"#" intoString:NULL];
    if (!identifier)
        identifier = [CPCharacterSet characterSetWithCharactersInString:@"_$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];

    if (![self scanCharactersFromSet:identifier intoString:@ref(ident)])
        CPRaiseParseError(self, @"expression");

    return [CPExpression expressionForKeyPath:ident];
}

- (CPExpression)parseFunctionalExpression
{
    var left = [self parseSimpleExpression];

    while (YES)
    {
        if ([self scanString:@"." intoString:NULL])
        {
            var right = [self parseSimpleExpression],
                expressionType = [right expressionType];

            if (expressionType == CPKeyPathExpressionType)
                left = [[_CPKeyPathExpression alloc] initWithOperand:left andKeyPath:[right keyPath]];
            else if (expressionType == CPVariableExpressionType)
                left = [CPExpression expressionForFunction:left selectorName:@"valueForKey:" arguments:[right]];
            else
                CPRaiseParseError(self, @"expression");
        }
        else if ([self scanString:@"[" intoString:NULL])
        {
            // index expression
            if ([self scanPredicateKeyword:@"FIRST"])
            {
                left = [CPExpression expressionForFunction:@"first:" arguments:[CPArray arrayWithObject:left]];
            }
            else if ([self scanPredicateKeyword:@"LAST"])
            {
                left = [CPExpression expressionForFunction:@"last:" arguments:[CPArray arrayWithObject:left]];
            }
            else if ([self scanPredicateKeyword:@"SIZE"])
            {
                left = [CPExpression expressionForFunction:@"count:" arguments:[CPArray arrayWithObject:left]];
            }
            else
            {
                var index = [self parseExpression];
                left = [CPExpression expressionForFunction:@"fromObject:index:" arguments:[CPArray arrayWithObjects:left, index]];
            }

            if (![self scanString:@"]" intoString:NULL])
                CPRaiseParseError(self, @"expression");
        }
        else if ([self scanString:@":" intoString:NULL])
        {
            // function - this parser allows for (max)(a, b, c) to be properly
            // recognized and even (%K)(a, b, c) if %K evaluates to "max"

            if (![left keyPath])
                CPRaiseParseError(self, @"expression");

            var selector = [left keyPath] + @":",
                args = [];

            if (![self scanString:@"(" intoString:NULL])
            {
                var str;
                [self scanCharactersFromSet:[CPCharacterSet lowercaseLetterCharacterSet] intoString:@ref(str)];

                if (![self scanString:@":(" intoString:NULL])
                    CPRaiseParseError(self, @"expression");

                selector += str + @":";
            }

            if (![self scanString:@")" intoString:NULL])
            {
                [args addObject:[self parseExpression]];
                while ([self scanString:@"," intoString:NULL])
                    [args addObject:[self parseExpression]];

                if (![self scanString:@")" intoString:NULL])
                    CPRaiseParseError(self, @"expression");
            }

            left = [CPExpression expressionForFunction:selector arguments:args];
        }
        else if ([self scanString:@"UNION" intoString:NULL])
        {
            left = [CPExpression expressionForUnionSet:left with:[self parseExpression]];
        }
        else if ([self scanString:@"INTERSECT" intoString:NULL])
        {
            left = [CPExpression expressionForIntersectSet:left with:[self parseExpression]];
        }
        else if ([self scanString:@"MINUS" intoString:NULL])
        {
            left = [CPExpression expressionForMinusSet:left with:[self parseExpression]];
        }
        else
        {
            // done with suffixes
            return left;
        }
    }
}

- (CPExpression)parsePowerExpression
{
    var left = [self parseFunctionalExpression];

    while (YES)
    {
        var right;

        if ([self scanString:@"**" intoString:NULL])
        {
            right = [self parseFunctionalExpression];
            left = [CPExpression expressionForFunction:@"raise:to:" arguments:[CPArray arrayWithObjects:left, right]];
        }
        else
        {
            return left;
        }
    }
}

- (CPExpression)parseMultiplicationExpression
{
    var left = [self parsePowerExpression];

    while (YES)
    {
        var right;

        if ([self scanString:@"*" intoString:NULL])
        {
            right = [self parsePowerExpression];
            left = [CPExpression expressionForFunction:@"multiply:by:" arguments:[CPArray arrayWithObjects:left, right]];
        }
        else if ([self scanString:@"/" intoString:NULL])
        {
            right = [self parsePowerExpression];
            left = [CPExpression expressionForFunction:@"divide:by:" arguments:[CPArray arrayWithObjects:left, right]];
        }
        else
        {
            return left;
        }
    }
}

- (CPExpression)parseAdditionExpression
{
    var left = [self parseMultiplicationExpression];

    while (YES)
    {
        var right;

        if ([self scanString:@"+" intoString:NULL])
        {
            right = [self parseMultiplicationExpression];
            left = [CPExpression expressionForFunction:@"add:to:" arguments:[CPArray arrayWithObjects:left, right]];
        }
        else if ([self scanString:@"-" intoString:NULL])
        {
            right = [self parseMultiplicationExpression];
            left = [CPExpression expressionForFunction:@"from:substract:" arguments:[CPArray arrayWithObjects:left, right]];
        }
        else
        {
            return left;
        }
    }
}

- (CPExpression)parseBinaryExpression
{
    var left = [self parseAdditionExpression];

    while (YES)
    {
        var right;

        if ([self scanString:@":=" intoString:NULL])    // assignment
        {
            // check left to be a variable?
            right = [self parseAdditionExpression];
            // FIXME
        }
        else
        {
            return left;
        }
    }
}

@end

var CPRaiseParseError = function(aScanner, target)
{
    [CPException raise:CPInvalidArgumentException reason:@"unable to parse " + target + " at index " + [aScanner scanLocation]];
};
