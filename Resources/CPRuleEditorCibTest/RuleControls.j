/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2008 Pear, Inc. All rights reserved.
 */

@implementation RuleTextField : CPTextField
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 500, 24)];

    if (self != nil)
    {
        [self setBezeled:YES];
        [self setBezelStyle:CPTextFieldSquareBezel];
        [self setBordered:YES];
        [self setEditable:YES];
        [self setFont:[CPFont systemFontOfSize:11]];
    }

    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object class] == [RuleTextField class] &&
        [[object objectValue] isEqual:[self objectValue]])
            return YES;

    return YES;
}

- (id)copy
{
    var copy = [[RuleTextField alloc] initWithFrame:CGRectMakeZero()];
    [copy setObjectValue:[self objectValue]];

    return copy;
}

@end

@implementation RuleSlider : CPSlider
{
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(0, 0, 500, 18)];

    if (self != nil)
    {
        [self setMinValue:0];
        [self setMaxValue:60];
        [self setContinuous:YES];
    }

    return self;
}

- (id)objectValue
{
    return ROUND([self doubleValue]);
}

- (id)copy
{
    var copy = [[RuleSlider alloc] initWithFrame:CGRectMakeZero()];
    [copy setObjectValue:[self objectValue]];

    return copy;
}

@end
