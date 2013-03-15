/*
 * AppController.j
 * CPTextField
 *
 * Created by Alexander Ljungberg on August 2, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    aWindow;
    CPTextField bezelToggleField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var textField = [CPTextField textFieldWithStringValue:"" placeholder:"Edit me!" width:200],
        label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 400, 24)];

    [label setStringValue:"Edit and hit enter: editing should end."];
    [contentView addSubview:label];

    [textField setFrameOrigin:CGPointMake(15, 35)];

    [textField setEditable:YES];
    [textField setPlaceholderString:"Edit me!"];

    [textField setTarget:self];
    [textField setAction:@selector(textAction:)];

    [contentView addSubview:textField];

    var shadowLabel = [CPTextField labelWithTitle:@"This text should have a shadow."],
        championOfLightLabel = [CPTextField labelWithTitle:@"This text should have no shadow."];

    [shadowLabel setTextColor:[CPColor blackColor]];
    [shadowLabel setTextShadowOffset:CGSizeMake(0, 1)];
    [shadowLabel setTextShadowColor:[CPColor colorWithCSSString:@"rgba(0, 0, 0, 0.5)"]];

    [championOfLightLabel setTextColor:[CPColor blackColor]];
    [championOfLightLabel setTextShadowOffset:CGSizeMake(0, 1)];
    [championOfLightLabel setTextShadowColor:[CPColor clearColor]];

    [shadowLabel setFrame:CGRectMake(15, CGRectGetMaxY([textField frame]) + 10, 300, 18)];
    [championOfLightLabel setFrame:CGRectMake(15, CGRectGetMaxY([shadowLabel frame]) + 2, 300, 18)];

    [contentView addSubview:shadowLabel];
    [contentView addSubview:championOfLightLabel];

    var jumpLabel = [CPTextField labelWithTitle:@"The text of these text fields should not move ('jump') when a field becomes the first responder. Labels on the right should replicate the input."];

    [jumpLabel sizeToFit];
    [jumpLabel setFrameOrigin:CGPointMake(15, 150)];
    [contentView addSubview:jumpLabel];

    var y = CGRectGetMaxY([jumpLabel frame]) + 10;

    for (var i = 0; i < 5; i++)
    {
        var size = 10 + 3 * i,
            textField = [CPTextField textFieldWithStringValue:@"Size " + size placeholder:@"Size " + size width:200],
            echoField = [CPTextField labelWithTitle:""];

        [textField setFont:[CPFont systemFontOfSize:size]];
        [textField sizeToFit];
        [textField setFrameOrigin:CGPointMake(15, y)];
        textField.echoField = echoField;
        [contentView addSubview:textField];

        [echoField setFont:[CPFont systemFontOfSize:size]];
        [echoField setStringValue:[textField stringValue]];
        [echoField sizeToFit];
        [echoField setFrameOrigin:CGPointMake(CGRectGetMaxX([textField frame]) + 15, CGRectGetMidY([textField frame]) - CGRectGetHeight([echoField frame]) / 2.0)];
        [contentView addSubview:echoField];

        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:CPControlTextDidChangeNotification object:textField];

        y = CGRectGetMaxY([textField frame]) + 6;
    }

    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 420, 600, 30)];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:"This text field has been configured to show its text at a fixed location both with and without bezel."];
    [contentView addSubview:label];

    bezelToggleField = [CPTextField textFieldWithStringValue:"" placeholder:"Placeholder" width:200],

    [bezelToggleField setEditable:YES];
    [bezelToggleField setFrameOrigin:CGPointMake(15, 445)];
    console.log("" + bezelToggleField._themeAttributes['content-inset']._themeDefaultAttribute._values);
    console.log("" + bezelToggleField._themeAttributes['content-inset']._values);
    [bezelToggleField setValue:[bezelToggleField valueForThemeAttribute:@"content-inset" inState:CPThemeStateBezeled] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    console.log("" + bezelToggleField._themeAttributes['content-inset']._themeDefaultAttribute._values);
    console.log("" + bezelToggleField._themeAttributes['content-inset']._values);

    [contentView addSubview:bezelToggleField];

    var bezelToggleButton = [CPButton buttonWithTitle:"Show Bezel"];

    [bezelToggleButton setButtonType:CPPushOnPushOffButton];
    [bezelToggleButton setAction:@selector(toggleBezel:)];
    [bezelToggleButton setTarget:self];
    [bezelToggleButton setState:CPOnState];
    [bezelToggleButton sizeToFit];
    [bezelToggleButton setFrameOrigin:CGPointMake(CGRectGetMaxX([bezelToggleField frame]) + 15, 448)];
    [contentView addSubview:bezelToggleButton];

    [theWindow orderFront:self];

    aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(150, 300, 400, 150) styleMask:CPTitledWindowMask | CPClosableWindowMask | CPDocModalWindowMask];
    [aWindow setTitle:@"Text Field in a Window"]

    contentView = [aWindow contentView];

    textField = [CPTextField textFieldWithStringValue:"Select me!" placeholder:"" width:0];
    label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 360, 30)];
    [label setLineBreakMode:CPLineBreakByWordWrapping];

    [label setStringValue:"Select the field and double click it to select text. The text should become selected. Then hit enter to continue."];
    [contentView addSubview:label];

    [textField setFrame:CGRectMake(15, CGRectGetMaxY([label frame]) + 10, 300, 30)];
    [textField setEditable:YES];
    [textField setTarget:self];
    [textField setAction:@selector(modalAction:)];

    [contentView addSubview:textField];

    [CPApp beginSheet:aWindow modalForWindow:theWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (@action)toggleBezel:(id)sender
{
    [bezelToggleField setBezeled:([sender state] == CPOnState)];
}

- (void)modalAction:(id)sender
{
    [CPApp endSheet:aWindow returnCode:0];
    [aWindow orderOut:sender];
}

- (void)textAction:(id)sender
{
    [sender setEditable:NO];
}

- (void)textDidChange:(CPNotification)aNotification
{
    var changedField = [aNotification object];

    [changedField.echoField setStringValue:[changedField stringValue]];
    [changedField.echoField sizeToFit];
}

@end
