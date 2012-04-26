/*
 * ThemeDescriptors.j
 * __project.name__
 *
 * Created by __user.name__ on __project.date__
 * Copyright __project.year__, __organization.name__. All rights reserved.
 */

@import <BlendKit/BKThemeDescriptor.j>


@implementation __project.nameasidentifier__ThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"__project.name__";
}

+ (CPButton)themedButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];

    [button setValue:[CPColor blueColor] forThemeAttribute:@"bezel-color"];
    [button setValue:[CPColor greenColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted];

    [button setValue:[CPColor redColor] forThemeAttribute:@"text-color"];
    [button setValue:[CPColor yellowColor] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];

    [button setTitle:@"Yikes!"];

    return button;
}

@end
