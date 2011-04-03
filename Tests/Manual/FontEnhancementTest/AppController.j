/*
 * AppController.j
 * test
 *
 * Created by aparajita on March 9, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


var fontLabelField = nil,
    defaultFontLabelText = @"";


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPTextField label1;
    CPTextField fontLabel;
    CPTableView theTableView;
    CPRadio     radio1;
    CPRadio     radio2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:NO];

    fontLabelField = fontLabel;
    defaultFontLabelText = [fontLabelField stringValue];

    var font = [CPFont fontWithName:@"Palatino, Cambria" size:14];

    [radio1 setFont:font];
    [radio2 setFont:font];
}

- (int)numberOfRowsInTableView:(id)aTableView
{
    return 7;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return ["one", "two", "three"][parseInt([aColumn identifier], 10)];
}

@end


@implementation CPView (testApp)

- (void)doMouseEntered
{
    [fontLabelField setStringValue:@"View font: " + [[self font] cssString]];
}

- (void)doMouseExited
{
    [fontLabelField setStringValue:defaultFontLabelText];
}

@end


@implementation CPControl (testApp)

- (void)awakeFromCib
{
    [super awakeFromCib];

    var size = [self frameSize],
        lineHeight = [[self font] defaultLineHeightForFont],
        inset = [self hasThemeAttribute:@"content-inset"] ? [self currentValueForThemeAttribute:@"content-inset"] : nil,
        minSize = [self hasThemeAttribute:@"min-size"] ? [self currentValueForThemeAttribute:@"min-size"] : nil,
        height = lineHeight + (inset ? inset.top + inset.bottom : 0);

    if (minSize)
        height = MAX(height, minSize.height);

    [self setFrameSize:CGSizeMake(size.width, MAX(size.height, height))];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [self doMouseEntered];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [self doMouseExited];
}

@end


@implementation CPTabView (testApp)

- (void)mouseEntered:(CPEvent)anEvent
{
    [_tabs doMouseEntered];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [_tabs doMouseExited];
}

@end
