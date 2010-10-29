@import "CPArray.j"
@import "CPNull.j"
@import "CPString.j"
@import "CPEnumerator.j"
@import "CPPredicate.j"
@import "CPExpression.j"

/*!
    A predicate to compare directly the left and right hand sides.
    @global
    @class CPComparisonPredicate
*/
CPDirectPredicateModifier = 0;
/*!
    A predicate to compare all entries in the destination of a to-many relationship.

    The left hand side must be a collection. The corresponding predicate compares each value in the left hand side with the right hand side, and returns NO when it finds the first mismatch—or YES if all match.
    @global
    @class CPComparisonPredicate
*/
CPAllPredicateModifier = 1;
/*!
    A predicate to match with any entry in the destination of a to-many relationship.

    The left hand side must be a collection. The corresponding predicate compares each value in the left hand side against the right hand side and returns YES when it finds the first match—or NO if no match is found.
    @global
    @class CPComparisonPredicate
*/
CPAnyPredicateModifier = 2;

/*!
    A case-insensitive predicate.
    @global
    @class CPComparisonPredicate
*/
CPCaseInsensitivePredicateOption = 1;
/*!
    A diacritic-insensitive predicate.
    @global
    @class CPComparisonPredicate
*/
CPDiacriticInsensitivePredicateOption = 2;
CPDiacriticInsensitiveSearch = 128;

/*!
    A less-than predicate.
    @global
    @class CPComparisonPredicate
*/
CPLessThanPredicateOperatorType = 0;
/*!
    A less-than-or-equal-to predicate.
    @global
    @class CPComparisonPredicate
*/
CPLessThanOrEqualToPredicateOperatorType = 1;
/*!
    A greater-than predicate.
    @global
    @class CPComparisonPredicate
*/
CPGreaterThanPredicateOperatorType = 2;
/*!
    A greater-than-or-equal-to predicate.
    @global
    @class CPComparisonPredicate
*/
CPGreaterThanOrEqualToPredicateOperatorType = 3;
/*!
    An equal-to predicate.
    @global
    @class CPComparisonPredicate
*/
CPEqualToPredicateOperatorType = 4;
/*!
    A not-equal-to predicate.
    @global
    @class CPComparisonPredicate
*/
CPNotEqualToPredicateOperatorType = 5;
/*!
    A full regular expression matching predicate.
    @global
    @class CPComparisonPredicate
*/
CPMatchesPredicateOperatorType = 6;
/*!
    A simple subset of the matches predicate, similar in behavior to SQL LIKE.
    @global
    @class CPComparisonPredicate
*/
CPLikePredicateOperatorType = 7;
/*!
    A begins-with predicate.
    @global
    @class CPComparisonPredicate
*/
CPBeginsWithPredicateOperatorType = 8;
/*!
    An ends-with predicate.
    @global
    @class CPComparisonPredicate
*/
CPEndsWithPredicateOperatorType = 9;
/*!
    A predicate to determine if the left hand side is in the right hand side.

    For strings, returns YES if the left hand side is a substring of the right hand side . For collections, returns YES if the left hand side is in the right hand side.
    @global
    @class CPComparisonPredicate
*/
CPInPredicateOperatorType = 10;
/*!
    Predicate that uses a custom selector that takes a single argument and returns a BOOL value.

    The selector is invoked on the left hand side with the right hand side.
    @global
    @class CPComparisonPredicate
*/
CPCustomSelectorPredicateOperatorType = 11;
/*!
    A predicate to determine if the left hand side contains the right hand side.

    Returns YES if [lhs contains rhs]; the left hand side must be a CPExpression object that evaluates to a collection
    @global
    @class CPComparisonPredicate
*/
CPContainsPredicateOperatorType = 99;
/*!
    A predicate to determine if the right hand side lies between bounds specified by the left hand side.

    Returns YES if [lhs between rhs]; the right hand side must be an array in which the first element sets the lower bound and the second element the upper, inclusive. Comparison is performed using compare: or the class-appropriate equivalent.
    @global
    @class CPComparisonPredicate
*/
CPBetweenPredicateOperatorType = 100;

var CPComparisonPredicateModifier,
    CPPredicateOperatorType;

/*!
    @ingroup foundation
    @class CPComparisonPredicate
    @brief CPComparisonPredicate is a subclass of CPPredicate used to compare expressions.

    Comparison predicates are predicates used to compare the results of two expressions. Comparison predicates take an operator, a left expression, and a right expression, and return as a BOOL the result of invoking the operator with the results of evaluating the expressions. Expressions are represented by instances of the CPExpression class.
*/
@implementation CPComparisonPredicate : CPPredicate
{
    CPExpression                     _left;
    CPExpression                     _right;

    CPComparisonPredicateModifier    _modifier;
    CPPredicateOperatorType          _type;
    unsigned int                     _options;
    SEL                              _customSelector;
}

// Constructors
/*!
    Returns a new predicate formed by combining the left and right expressions using a given selector.
    @param left The left hand side expression.
    @param right The right hand side expression.
    @param selector The selector to use for comparison. The method defined by the selector must take a single argument and return a BOOL value.
    @return A new predicate formed by combining the left and right expressions using selector.
*/
+ (CPPredicate)predicateWithLeftExpression:(CPExpression)left rightExpression:(CPExpression)right customSelector:(SEL)selector
{
    return [[self alloc] initWithLeftExpression:left rightExpression:right customSelector:selector];
}

/*!
    Creates and returns a predicate of a given type formed by combining given left and right expressions using a given modifier and options.
    @param left The left hand expression.
    @param right The right hand expression.
    @param modifier The modifier to apply.
    @param type The predicate operator type.
    @param options The options to apply (see CPComparisonPredicate Options).
    @return A new predicate of type type formed by combining the given left and right expressions using the modifier and options.
*/
+ (CPPredicate)predicateWithLeftExpression:(CPExpression)left rightExpression:(CPExpression)right modifier:(CPComparisonPredicateModifier)modifier type:(int)type options:(unsigned)options
{
    return [[self alloc] initWithLeftExpression:left rightExpression:right modifier:modifier type:type options:options];
}

/*!
    Initializes a predicate formed by combining given left and right expressions using a given selector.
    @param left The left hand side expression.
    @param right The right hand side expression.
    @param selector The selector to use for comparison. The method defined by the selector must take a single argument and return a BOOL value.
    @return The receiver, initialized by combining the left and right expressions using selector.
*/
- (id)initWithLeftExpression:(CPExpression)left rightExpression:(CPExpression)right customSelector:(SEL)selector
{
    _left = left;
    _right = right;
    _modifier = CPDirectPredicateModifier;
    _type = CPCustomSelectorPredicateOperatorType;
    _options = 0;
    _customSelector = selector;

    return self;
}

/*!
    Initializes a predicate to a given type formed by combining given left and right expressions using a given modifier and options.
    @param left The left hand expression.
    @param right The right hand expression.
    @param modifier The modifier to apply.
    @param type The predicate operator type.
    @param options The options to apply (see CPComparisonPredicate Options).
    @return The receiver, initialized to a predicate of type type formed by combining the left and right expressions using the modifier and options.
*/
- (id)initWithLeftExpression:(CPExpression)left rightExpression:(CPExpression)right modifier:(CPComparisonPredicateModifier)modifier type:(CPPredicateOperatorType)type options:(unsigned)options
{
    _left = left;
    _right = right;
    _modifier = modifier;
    _type = type;
    _options = (type != CPMatchesPredicateOperatorType &&
                type != CPLikePredicateOperatorType &&
                type != CPBeginsWithPredicateOperatorType &&
                type != CPEndsWithPredicateOperatorType &&
                type != CPInPredicateOperatorType &&
                type != CPContainsPredicateOperatorType) ? 0 : options;

    _customSelector = NULL;

    return self;
}

// Getting Information About a Comparison Predicate
/*!
    Returns the comparison predicate modifier for the receiver.
    @return The comparison predicate modifier for the receiver.
*/
- (CPComparisonPredicateModifier)comparisonPredicateModifier
{
    return _modifier;
}

/*!
    Returns the selector for the receiver.
    @return The selector for the receiver, or NULL if there is none.
*/
- (SEL)customSelector
{
    return _customSelector;
}

/*!
    Returns the left expression for the receiver.
    @return The left expression for the receiver, or nil if there is none.
*/
- (CPExpression)leftExpression
{
    return _left;
}

/*!
    Returns the options that are set for the receiver.
    @return The options that are set for the receiver.
*/
- (unsigned)options
{
    return _options;
}

/*!
    Returns the predicate type for the receiver.
    @return Returns the predicate type for the receiver.
*/
- (CPPredicateOperatorType)predicateOperatorType
{
    return _type;
}

/*!
    Returns the right expression for the receiver.
    @return The right expression for the receiver, or nil if there is none.
*/
- (CPExpression)rightExpression
{
    return _right;
}


- (CPString)predicateFormat
{
    var modifier;

    switch (_modifier)
    {
        case CPDirectPredicateModifier:
            modifier = "";
            break;
        case CPAllPredicateModifier:
            modifier = "ALL ";
            break;
        case CPAnyPredicateModifier:
            modifier = "ANY ";
            break;
        default:
            modifier = "";
            break;
    }

    var options;

    switch (_options)
    {
        case CPCaseInsensitivePredicateOption:
            options = "[c]";
            break;
        case CPDiacriticInsensitivePredicateOption:
            options = "[d]";
            break;
        case CPCaseInsensitivePredicateOption | CPDiacriticInsensitivePredicateOption:
            options = "[cd]";
            break;
        default:
            options = "";
            break;
    }

    var operator;

    switch (_type)
    {
        case CPLessThanPredicateOperatorType:
            operator = "<";
            break;
        case CPLessThanOrEqualToPredicateOperatorType:
            operator = "<=";
            break;
        case CPGreaterThanPredicateOperatorType:
            operator = ">";
            break;
        case CPGreaterThanOrEqualToPredicateOperatorType:
            operator = ">=";
            break;
        case CPEqualToPredicateOperatorType:
            operator = "==";
            break;
        case CPNotEqualToPredicateOperatorType:
            operator = "!=";
            break;
        case CPMatchesPredicateOperatorType:
            operator = "MATCHES";
            break;
        case CPLikePredicateOperatorType:
            operator = "LIKE";
            break;
        case CPBeginsWithPredicateOperatorType:
            operator = "BEGINSWITH";
            break;
        case CPEndsWithPredicateOperatorType:
            operator = "ENDSWITH";
            break;
        case CPInPredicateOperatorType:
            operator = "IN";
            break;
        case CPContainsPredicateOperatorType:
            operator = "CONTAINS";
            break;
        case CPCustomSelectorPredicateOperatorType:
            operator = CPStringFromSelector(_customSelector);
            break;
    }

    return [CPString stringWithFormat:@"%s%s %s%s %s",modifier,[_left description],operator,options,[_right description]];
}

- (CPPredicate)predicateWithSubstitutionVariables:(CPDictionary)variables
{
    var left = [_left _expressionWithSubstitutionVariables:variables],
        right = [_right _expressionWithSubstitutionVariables:variables];

    if (_type != CPCustomSelectorPredicateOperatorType)
        return [CPComparisonPredicate predicateWithLeftExpression:left rightExpression:right modifier:_modifier type:_type options:_options];
    else
        return [CPComparisonPredicate predicateWithLeftExpression:left rightExpression:right customSelector:_customSelector];
}

- (BOOL)_evaluateValue:lhs rightValue:rhs
{
    var leftIsNil = (lhs == nil || [lhs isEqual:[CPNull null]]),
        rightIsNil = (rhs == nil || [rhs isEqual:[CPNull null]]);

    if ((leftIsNil || rightIsNil) && _type != CPCustomSelectorPredicateOperatorType)
        return (leftIsNil == rightIsNil &&
               (_type == CPEqualToPredicateOperatorType ||
                _type == CPLessThanOrEqualToPredicateOperatorType ||
                _type == CPGreaterThanOrEqualToPredicateOperatorType));

    var string_compare_options = 0;

    // left and right should be casted first [CAST()] following 10.5 rules.
    switch (_type)
    {
        case CPLessThanPredicateOperatorType:
            return ([lhs compare:rhs] == CPOrderedAscending);
        case CPLessThanOrEqualToPredicateOperatorType:
            return ([lhs compare:rhs] != CPOrderedDescending);
        case CPGreaterThanPredicateOperatorType:
            return ([lhs compare:rhs] == CPOrderedDescending);
        case CPGreaterThanOrEqualToPredicateOperatorType:
            return ([lhs compare:rhs] != CPOrderedAscending);
        case CPEqualToPredicateOperatorType:
            return [lhs isEqual:rhs];
        case CPNotEqualToPredicateOperatorType:
            return (![lhs isEqual:rhs]);
        case CPMatchesPredicateOperatorType:
            var commut = (_options & CPCaseInsensitivePredicateOption) ? "gi":"g";
            if (_options & CPDiacriticInsensitivePredicateOption)
            {
                lhs = lhs.stripDiacritics();
                rhs = rhs.stripDiacritics();
            }

            return (new RegExp(rhs,commut)).test(lhs);
        case CPLikePredicateOperatorType:
            if (_options & CPDiacriticInsensitivePredicateOption)
            {
                lhs = lhs.stripDiacritics();
                rhs = rhs.stripDiacritics();
            }
            var commut = (_options & CPCaseInsensitivePredicateOption) ? "gi":"g",
                reg = new RegExp(rhs.escapeForRegExp(),commut);
            return reg.test(lhs);
        case CPBeginsWithPredicateOperatorType:
            var range = CPMakeRange(0,[rhs length]);
            if (_options & CPCaseInsensitivePredicateOption) string_compare_options |= CPCaseInsensitiveSearch;
            if (_options & CPDiacriticInsensitivePredicateOption) string_compare_options |= CPDiacriticInsensitiveSearch;

            return ([lhs compare:rhs options:string_compare_options range:range] == CPOrderedSame);
        case CPEndsWithPredicateOperatorType:
            var range = CPMakeRange([lhs length] - [rhs length],[rhs length]);
            if (_options & CPCaseInsensitivePredicateOption) string_compare_options |= CPCaseInsensitiveSearch;
            if (_options & CPDiacriticInsensitivePredicateOption) string_compare_options |= CPDiacriticInsensitiveSearch;

            return ([lhs compare:rhs options:string_compare_options range:range] == CPOrderedSame);
        case CPCustomSelectorPredicateOperatorType:
            return [lhs performSelector:_customSelector withObject:rhs];
        case CPInPredicateOperatorType:
            var a = lhs; // swap
            lhs = rhs;
            rhs = a;
        case CPContainsPredicateOperatorType:
            if (![lhs isKindOfClass:[CPString class]])
            {
                 if (![lhs respondsToSelector: @selector(objectEnumerator)])
                     [CPException raise:CPInvalidArgumentException reason:@"The left/right hand side for a CONTAINS/IN  operator must be a collection or a string"];

                 return [lhs containsObject:rhs];
            }

            if (_options & CPCaseInsensitivePredicateOption)
                string_compare_options |= CPCaseInsensitiveSearch;
            if (_options & CPDiacriticInsensitivePredicateOption)
                string_compare_options |= CPDiacriticInsensitiveSearch;

             return ([lhs rangeOfString:rhs options:string_compare_options].location != CPNotFound);
        case CPBetweenPredicateOperatorType:
            if ([rhs count] < 2)
                [CPException raise:CPInvalidArgumentException reason:@"The right hand side for a BETWEEN operator must contain 2 objects"];

            return ([lhs compare:rhs[0]] == CPOrderedDescending && [lhs compare:rhs[1]] == CPOrderedAscending);
        default:
            return NO;
    }
}

- (BOOL)evaluateWithObject:(id)object
{
    return [self evaluateWithObject:object substitutionVariables:nil];
}

- (BOOL)evaluateWithObject:(id)object substitutionVariables:(CPDictionary)variables
{
    var leftValue = [_left expressionValueWithObject:object context:variables],
        rightValue = [_right expressionValueWithObject:object context:variables];

    if (_modifier == CPDirectPredicateModifier)
        return [self _evaluateValue:leftValue rightValue:rightValue];
    else
    {
        if (![leftValue respondsToSelector:@selector(objectEnumerator)])
            [CPException raise:CPInvalidArgumentException reason:@"The left hand side for an ALL or ANY operator must be either a CPArray or a CPSet"];

        var e = [leftValue objectEnumerator],
            result = (_modifier == CPAllPredicateModifier),
            value;

        while (value = [e nextObject])
        {
            var eval = [self _evaluateValue:value rightValue:rightValue];
            if (eval != result)
                return eval;
        }

        return result;
    }
}

@end

@implementation CPComparisonPredicate (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    self = [super init];
    if (self != nil)
    {
        _left = [coder decodeObjectForKey:@"CPComparisonPredicateLeftExpression"];
        _right = [coder decodeObjectForKey:@"CPComparisonPredicateRightExpression"];
        _modifier = [coder decodeIntForKey:@"CPComparisonPredicateModifier"];
        _type = [coder decodeIntForKey:@"CPComparisonPredicateType"];
        _options = [coder decodeIntForKey:@"CPComparisonPredicateOptions"];
        _customSelector = [coder decodeObjectForKey:@"CPComparisonPredicateCustomSelector"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_left forKey:@"CPComparisonPredicateLeftExpression"];
    [coder encodeObject:_right forKey:@"CPComparisonPredicateRightExpression"];
    [coder encodeInt:_modifier forKey:@"CPComparisonPredicateModifier"];
    [coder encodeInt:_type forKey:@"CPComparisonPredicateType"];
    [coder encodeInt:_options forKey:@"CPComparisonPredicateOptions"];
    [coder encodeObject:_customSelector forKey:@"CPComparisonPredicateCustomSelector"];
}

@end

var source = ['*','?','(',')','{','}','.','+','|','/','$','^'],
    dest = ['.*','.?','\\(','\\)','\\{','\\}','\\.','\\+','\\|','\\/','\\$','\\^'];

String.prototype.escapeForRegExp = function()
{
    var foundChar = false;
    for (var i = 0; i < source.length; ++i)
    {
        if (this.indexOf(source[i]) !== -1)
        {
            foundChar = true;
            break;
        }
    }

    if (!foundChar)
        return this;

    var result = "",
        sourceIndex;
    for (var i = 0; i < this.length; ++i)
    {
        var sourceIndex = source.indexOf(this.charAt(i));
        if (sourceIndex !== -1)
            result += dest[sourceIndex];
        else
            result += this.charAt(i);
    }

    return result;
}
