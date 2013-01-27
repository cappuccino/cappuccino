/*
 * AppController.j
 * CPRuleEditorCibTest
 *
 * Created by cacaodev on September 3, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import "RuleDelegate.j"
@import "CPViewAnimationTransition.j"

var THEME_ATTRIBUTES = [@"slice-top-border-color", @"slice-bottom-border-color",@"slice-last-bottom-border-color", @"selected-color"];

@implementation AppController : CPObject
{
    CPWindow     theWindow; //this "outlet" is connected automatically by the Cib
    CPRuleEditor ruleEditor @accessors;
    CPTextField  predicateField;
    id           animation;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    var contentView = [theWindow contentView];
    [theWindow setFullPlatformWindow:YES];
    [contentView setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];

    var animationClass = (CPBrowserIsEngine(CPWebKitBrowserEngine)) ? [CPViewAnimationTransition class] : [CPViewAnimation class];
    animation = [[animationClass alloc] initWithDuration:0.4 animationCurve:CPAnimationEaseInOut];
    //[ruleEditor setAnimation:animation];
    for (var i = 0; i < 4; i++)
    {
        var view = [[theWindow contentView] viewWithTag:(1001 + i)];
        [view setColor:[ruleEditor valueForThemeAttribute:THEME_ATTRIBUTES[i]]];
    }

    var colors = [ruleEditor valueForThemeAttribute:@"alternating-row-colors"];
    [[contentView viewWithTag:1005] setColor:colors[0]];
    [[contentView viewWithTag:1006] setColor:colors[1]];
}

- (void)ruleEditorAction:(id)sender
{
    CPLogConsole(_cmd);
    [predicateField setStringValue:[[ruleEditor predicate] predicateFormat]];
}

- (void)setAnimate:(id)sender
{
    var anim = ([sender state]) ? animation : nil;
    [ruleEditor setAnimation:anim];
}

- (void)setEditable:(id)sender
{
    [ruleEditor setEditable:[sender state]];
}

- (void)setCanRemoveAllRows:(id)sender
{
    [ruleEditor setCanRemoveAllRows:[sender state]];
}

- (void)setAllowsEmptyCompoundRows:(id)sender
{
    [ruleEditor setAllowsEmptyCompoundRows:[sender state]];
}

- (void)setNestingMode:(id)sender
{
    [ruleEditor setNestingMode:[sender indexOfSelectedItem]];
}

- (void)setFormattingStringsFilename:(id)sender
{
    [ruleEditor setFormattingStringsFilename:[sender stringValue]];
}

- (void)setRowHeight:(id)sender
{
    [ruleEditor setRowHeight:[sender value]];
}

- (void)setAttributeValue:(id)sender
{
    var tag = [sender tag],
        value,
        attribute;

    if (tag == 1005 || tag == 1006)
    {
        var colorIndex = tag - 1005,
            attribute = @"alternating-row-colors",
            value = [ruleEditor valueForThemeAttribute:attribute];

        value[colorIndex] = [sender color];
    }
    else
    {
        value = [sender color];
        attribute = THEME_ATTRIBUTES[tag - 1001];
    }

    [ruleEditor setValue:value forThemeAttribute:attribute];
    [ruleEditor setNeedsDisplay:YES];
}

@end