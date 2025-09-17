/*
 * AppController.j
 * predicateWithFormat
 *
 * Created by aparajita on May 25, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>

var usesNewCode = NO;

@implementation AppController : CPObject
{
    CPWindow        theWindow;
    CPPopUpButton   dataMenu;
    CPPopUpButton   comparisonMenu;
    CPPopUpButton   nameMenu;
    CPTextField     resultsField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    useNewCode = usesNewCode;
}

- (void)awakeFromCib
{
}

- (BOOL)useNewCode
{
    return usesNewCode;
}

- (void)setUseNewCode:(BOOL)flag
{
    usesNewCode = flag;
}

- (void)search:(id)sender
{
    var results = @"";

    try
    {
        var format = [CPString stringWithFormat:@"SELF %@ %%@", [comparisonMenu titleOfSelectedItem]],
            predicate = [CPPredicate predicateWithFormat:format, [nameMenu titleOfSelectedItem]],
            data = [[dataMenu titleOfSelectedItem]],
            searchResults = [data filteredArrayUsingPredicate:predicate],

        results = searchResults.join("\n");
        [resultsField setTextColor:[CPColor blackColor]];
    }
    catch (ex)
    {
        results = [ex reason];
        [resultsField setTextColor:[CPColor redColor]];
    }

    [resultsField setStringValue:@"Result: " + results];
}

@end

var CPComparisonPredicateModifier,
    CPPredicateOperatorType;

@implementation CPComparisonPredicate (test)

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
        case CPLessThanPredicateOperatorType:               return ([lhs compare:rhs] == CPOrderedAscending);
        case CPLessThanOrEqualToPredicateOperatorType:      return ([lhs compare:rhs] != CPOrderedDescending);
        case CPGreaterThanPredicateOperatorType:            return ([lhs compare:rhs] == CPOrderedDescending);
        case CPGreaterThanOrEqualToPredicateOperatorType:   return ([lhs compare:rhs] != CPOrderedAscending);
        case CPEqualToPredicateOperatorType:                return [lhs isEqual:rhs];
        case CPNotEqualToPredicateOperatorType:             return (![lhs isEqual:rhs]);

        case CPMatchesPredicateOperatorType:                var commut = (_options & CPCaseInsensitivePredicateOption) ? "gi":"g";
                                                            if (_options & CPDiacriticInsensitivePredicateOption)
                                                            {
                                                                lhs = lhs.stripDiacritics();
                                                                rhs = rhs.stripDiacritics();
                                                            }
                                                            return (new RegExp(rhs,commut)).test(lhs);

        case CPLikePredicateOperatorType:                   if (_options & CPDiacriticInsensitivePredicateOption)
                                                            {
                                                                lhs = lhs.stripDiacritics();
                                                                rhs = rhs.stripDiacritics();
                                                            }
                                                            var commut = (_options & CPCaseInsensitivePredicateOption) ? "gi":"g",
                                                                reg = new RegExp(rhs.escapeForRegExp(),commut);
                                                            return reg.test(lhs);

        case CPBeginsWithPredicateOperatorType:             var range = usesNewCode ? CPMakeRange(0, MIN([lhs length], [rhs length])) : CPMakeRange(0,[rhs length]);
                                                            if (_options & CPCaseInsensitivePredicateOption) string_compare_options |= CPCaseInsensitiveSearch;
                                                            if (_options & CPDiacriticInsensitivePredicateOption) string_compare_options |= CPDiacriticInsensitiveSearch;
                                                            return ([lhs compare:rhs options:string_compare_options range:range] == CPOrderedSame);

        case CPEndsWithPredicateOperatorType:               var range = usesNewCode ? CPMakeRange(MAX([lhs length] - [rhs length], 0), MIN([lhs length], [rhs length])) : CPMakeRange([lhs length] - [rhs length],[rhs length]);
                                                            if (_options & CPCaseInsensitivePredicateOption) string_compare_options |= CPCaseInsensitiveSearch;
                                                            if (_options & CPDiacriticInsensitivePredicateOption) string_compare_options |= CPDiacriticInsensitiveSearch;
                                                            return ([lhs compare:rhs options:string_compare_options range:range] == CPOrderedSame);

        case CPCustomSelectorPredicateOperatorType:         return [lhs performSelector:_customSelector withObject:rhs];

        case CPInPredicateOperatorType:                     var a = lhs; // swap
                                                            lhs = rhs;
                                                            rhs = a;
        case CPContainsPredicateOperatorType:               if (![lhs isKindOfClass:[CPString class]])
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

        case CPBetweenPredicateOperatorType:                if ([rhs count] < 2)
                                                                [CPException raise:CPInvalidArgumentException reason:@"The right hand side for a BETWEEN operator must contain 2 objects"];

                                                            return ([lhs compare:rhs[0]] == CPOrderedDescending && [lhs compare:rhs[1]] == CPOrderedAscending);

        default:                                            return NO;
    }
}

@end
