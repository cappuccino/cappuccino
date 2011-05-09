/*
 * AppController.j
 * CPTextFieldContentInset
 *
 * Created by aparajita on May 9, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var description = [CPTextField labelWithTitle:@"Notice how the new inset vertically centers the text better, and when editing there is a visible gap between the selection and the bottom of the bezel."],
        label = [CPTextField labelWithTitle:@"Old inset:"],
        field = [CPTextField textFieldWithStringValue:@"Gnarly" placeholder:@"" width:100],
        labelFrame = [label frame];

    [description setFrame:CGRectMake(100, 40, 300, 70)];
    [description setLineBreakMode:CPLineBreakByCharWrapping];

    [label setFrame:CGRectMake(100, 120, 100, CGRectGetHeight(labelFrame))];
    [label setAlignment:CPRightTextAlignment];

    labelFrame = [label frame];

    [field setFrameOrigin:CGPointMake(CGRectGetMaxX(labelFrame) + 10, CGRectGetMinY(labelFrame))];
    [field setValue:CGInsetMake(8.0, 7.0, 5.0, 8.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled];
    [field setValue:CGInsetMake(7.0, 7.0, 5.0, 8.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPThemeStateEditing];
    [field sizeToFit];
    [IOUtils alignTextBaselineOf:field withBaselineOf:label];

    var fieldFrame = [field frame];

    [contentView addSubview:description];
    [contentView addSubview:label];
    [contentView addSubview:field];

    label = [CPTextField labelWithTitle:@"New inset:"];
    labelFrame = [label frame];
    field = [CPTextField textFieldWithStringValue:@"Gnarly" placeholder:@"" width:100];

    [label setFrame:CGRectMake(100, CGRectGetMaxY(fieldFrame) + 10, 100, CGRectGetHeight(labelFrame))];
    [label setAlignment:CPRightTextAlignment];
    labelFrame = [label frame];

    [field setFrameOrigin:CGPointMake(CGRectGetMaxX(labelFrame) + 10, CGRectGetMinY(labelFrame))];
    [field sizeToFit];
    [IOUtils alignTextBaselineOf:field withBaselineOf:label];

    [contentView addSubview:label];
    [contentView addSubview:field];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

@end

@implementation IOUtils : CPObject

/*!
    Aligns the text baseline of one CPTextField (editable or not)
    with the baseline of another CPTextField.
*/
+ (void)alignTextBaselineOf:(CPTextField)field1 withBaselineOf:(CPTextField)field2
{
    var myContentRect = [field1 contentRectForBounds:[field1 frame]],
        otherContentRect = [field2 contentRectForBounds:[field2 frame]],
        topDiff = CGRectGetMinY(otherContentRect) - CGRectGetMinY(myContentRect),
        ascenderDiff = [[field2 font] ascender] - [[field1 font] ascender],
        origin = [field1 frameOrigin];

    origin.y += topDiff + ascenderDiff;

    [field1 setFrameOrigin:origin];
}

@end
