/*
 * Transformers.j
 * MultipleValueBindings
 *
 * Created by Aparajita Fishman on February 13, 2013.
 * Copyright 2013, Cappuccino Foundation. All rights reserved.
 */

@import <Foundation/CPNumber.j>
@import <Foundation/CPValueTransformer.j>


@implementation ReversePercentTransformer : CPValueTransformer

+ (void)initialize
{
    if (self !== [ReversePercentTransformer class])
        return;

    [CPValueTransformer setValueTransformer:[self new]
                                    forName:[self className]];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [CPNumber class];
}

- (id)transformedValue:(id)aValue
{
    return ABS(100 - (aValue === nil ? 0 : aValue));
}

@end


@implementation FiftyIsTrueTransformer : CPValueTransformer

+ (void)initialize
{
    if (self !== [FiftyIsTrueTransformer class])
        return;

    [CPValueTransformer setValueTransformer:[self new]
                                    forName:[self className]];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [CPNumber class];
}

- (id)transformedValue:(id)aValue
{
    return aValue == 50 ? YES : NO;
}

@end


@implementation CurrencyTransformer : CPValueTransformer
{
    CPNumberFormatter formatter;
}

+ (void)initialize
{
    if (self !== [CurrencyTransformer class])
        return;

    [CPValueTransformer setValueTransformer:[self new]
                                    forName:[self className]];
}

- (id)init
{
    if (self = [super init])
    {
        formatter = [CPNumberFormatter new];
        [formatter setNumberStyle:CPNumberFormatterCurrencyStyle];
        [formatter setMinimumFractionDigits:0];
        [formatter setMaximumFractionDigits:0];
    }

    return self;
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [CPString class];
}

- (id)transformedValue:(id)aValue
{
    return [formatter stringFromNumber:aValue === nil ? 0 : aValue];
}

@end
