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

    var themedButtonValues =
    [
        [@"text-color",                 [CPColor redColor]],
        [@"text-color",                 [CPColor yellowColor], CPThemeStateHighlighted],

        [@"bezel-color",                [CPColor blueColor]],
        [@"bezel-color",                [CPColor greenColor], CPThemeStateHighlighted],
    ];

    [self registerThemeValues:themedButtonValues forView:button];

    [button setTitle:@"Yikes!"];

    return button;
}

@end
