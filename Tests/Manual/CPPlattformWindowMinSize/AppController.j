/*
 * AppController.j
 * MinSize PlattformWindow
 *
 * Created by Daniel Boehringer on March 25, 2018.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPTextField textFieldWidth;
    CPTextField textFieldHeight;
    CPWindow    theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero()
                                            styleMask:CPBorderlessBridgeWindowMask];

    var contentView = [theWindow contentView];

    textFieldWidth = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 29.0)];
    textFieldHeight = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 29.0)];

    [textFieldWidth setEditable:YES];
    [textFieldWidth setBezeled:YES];
    [textFieldWidth setCenter:CGPointMake([contentView center].x, [contentView center].y + 40.0)];
    [textFieldWidth setPlaceholderString:"enter min width"];
    [contentView addSubview:textFieldWidth];

    [textFieldHeight setEditable:YES];
    [textFieldHeight setBezeled:YES];
    [textFieldHeight setCenter:CGPointMake([contentView center].x, [contentView center].y + 65.0)];
    [textFieldHeight setPlaceholderString:"enter min height"];
    [contentView addSubview:textFieldHeight];

    var button = [CPButton buttonWithTitle:@"SetMinSize"],
        frame = [textFieldWidth frame];

    [button setCenter:CGPointMake([contentView center].x, 0)];
    [button setFrameOrigin:CGPointMake(CGRectGetMinX([textFieldHeight frame]), CGRectGetMaxY([textFieldHeight frame]) + 20)];
    [button setTarget:self];
    [button setAction:@selector(setMinSize:)];
    [contentView addSubview:button];

    [theWindow orderFront:self];
}

- (void)setMinSize:(id)sender
{
    [theWindow setMinSize:CGSizeMake([textFieldWidth intValue], [textFieldHeight intValue])];
}

@end
