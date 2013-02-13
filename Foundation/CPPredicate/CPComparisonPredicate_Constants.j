/*
 * CPComparisonPredicate_Constants.j
 *
 * Portions based on NSComparisonPredicate.m in Cocotron (http://www.cocotron.org/)
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

/*!
    A predicate to directly compare the left and right hand sides.
    @global
    @class CPComparisonPredicate
*/
CPDirectPredicateModifier               = 0;
/*!
    A predicate to compare all entries in the destination of a to-many relationship.

    The left hand side must be a collection. The corresponding predicate compares each value in the left hand side with the right hand side, and returns NO when it finds the first mismatch—or YES if all match.
    @global
    @class CPComparisonPredicate
*/
CPAllPredicateModifier                  = 1;
/*!
    A predicate to match with any entry in the destination of a to-many relationship.

    The left hand side must be a collection. The corresponding predicate compares each value in the left hand side against the right hand side and returns YES when it finds the first match—or NO if no match is found.
    @global
    @class CPComparisonPredicate
*/
CPAnyPredicateModifier                  = 2;

/*!
    A case-insensitive predicate.
    @global
    @class CPComparisonPredicate
*/
CPCaseInsensitivePredicateOption        = 1;
/*!
    A diacritic-insensitive predicate.
    @global
    @class CPComparisonPredicate
*/
CPDiacriticInsensitivePredicateOption   = 2;
CPDiacriticInsensitiveSearch            = 128;

/*!
    A less-than predicate.
    @global
    @class CPComparisonPredicate
*/
CPLessThanPredicateOperatorType         = 0;
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
CPGreaterThanPredicateOperatorType      = 2;
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
CPEqualToPredicateOperatorType          = 4;
/*!
    A not-equal-to predicate.
    @global
    @class CPComparisonPredicate
*/
CPNotEqualToPredicateOperatorType       = 5;
/*!
    A full regular expression matching predicate.
    @global
    @class CPComparisonPredicate
*/
CPMatchesPredicateOperatorType          = 6;
/*!
    A simple subset of the matches predicate, similar in behavior to SQL LIKE.
    @global
    @class CPComparisonPredicate
*/
CPLikePredicateOperatorType             = 7;
/*!
    A begins-with predicate.
    @global
    @class CPComparisonPredicate
*/
CPBeginsWithPredicateOperatorType       = 8;
/*!
    An ends-with predicate.
    @global
    @class CPComparisonPredicate
*/
CPEndsWithPredicateOperatorType         = 9;
/*!
    A predicate to determine if the left hand side is in the right hand side.

    For strings, returns YES if the left hand side is a substring of the right hand side. For collections, returns YES if the left hand side is in the right hand side.
    @global
    @class CPComparisonPredicate
*/
CPInPredicateOperatorType               = 10;
/*!
    Predicate that uses a custom selector that takes a single argument and returns a BOOL value.

    The selector is invoked on the left hand side with the right hand side.
    @global
    @class CPComparisonPredicate
*/
CPCustomSelectorPredicateOperatorType   = 11;
/*!
    A predicate to determine if the left hand side contains the right hand side.

    Returns YES if [lhs contains rhs]; the left hand side must be a CPExpression object that evaluates to a collection
    @global
    @class CPComparisonPredicate
*/
CPContainsPredicateOperatorType         = 99;
/*!
    A predicate to determine if the right hand side lies between bounds specified by the left hand side.

    Returns YES if [lhs between rhs]; the right hand side must be an array in which the first element sets the lower bound and the second element the upper, inclusive. Comparison is performed using compare: or the class-appropriate equivalent.
    @global
    @class CPComparisonPredicate
*/
CPBetweenPredicateOperatorType          = 100;
