//
//  PredicateTransformer.m
//  PredicateEditor
//
//  Created by x on 22/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@implementation PredicateTransformer : CPValueTransformer
{
}

+ (Class)transformedValueClass
{
    return [CPString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (CPString)transformedValue:(CPPredicate)predicate
{
    if (predicate == nil || [predicate isEqual:[CPNull null]])
        return @"";

    return [predicate predicateFormat];
}

- (CPPredicate)reverseTransformedValue:(CPString)aValue
{
    if (aValue == nil || [aValue isEqualToString:@""])
        return nil;

    var predicate;

    try
    {
        predicate = [CPPredicate predicateWithFormat:aValue];
    }
    catch (e)
    {
        CPLogConsole(e);
        predicate = nil;
    }
    finally
    {
        return predicate;
    }
}

@end