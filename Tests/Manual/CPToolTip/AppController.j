/*
 * AppController.j
 * tooltips
 *
 * Created by You on April 26, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    CPArray _toolbarItems;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var b = [CPButton buttonWithTitle:@"Small tooltip"];
    [b setFrameOrigin:CPPointMake(10.0, 30.0)];
    [b setToolTip:@"Lorem ipsum dolor sit amet."];
    [contentView addSubview:b];
    
    var b = [CPButton buttonWithTitle:@"Medium tooltip"];
    [b setFrameOrigin:CPPointMake(10.0, 80.0)];
    [b setToolTip:@"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi."];
    [contentView addSubview:b];
    
    var b = [CPButton buttonWithTitle:@"Big tooltip"];
    [b setFrameOrigin:CPPointMake(10.0, 130.0)];
    [b setToolTip:@"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi. Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. Duis arcu massa, scelerisque vitae, consequat in, pretium a, enim. Pellentesque congue. Ut in risus volutpat libero pharetra tempor. Cras vestibulum bibendum augue. Praesent egestas leo in pede. Praesent blandit odio eu enim. Pellentesque sed dui ut augue blandit sodales. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aliquam nibh. Mauris ac mauris sed pede pellentesque fermentum. Maecenas adipiscing ante non diam sodales hendrerit. Ut velit mauris, egestas sed, gravida nec, ornare ut, mi. Aenean ut orci vel massa suscipit pulvinar. Nulla sollicitudin. Fusce varius, ligula non tempus aliquam, nunc turpis ullamcorper nibh, in tempus sapien eros vitae ligula. Pellentesque rhoncus nunc et augue. Integer id felis. Curabitur aliquet pellentesque diam. Integer quis metus vitae elit lobortis egestas. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Morbi vel erat non mauris convallis vehicula. Nulla et sapien. Integer tortor tellus, aliquam faucibus, convallis id, congue eu, quam. Mauris ullamcorper felis vitae erat. Proin feugiat, augue non elementum posuere, metus purus iaculis lectus, et tristique ligula justo vitae magna. Aliquam convallis sollicitudin purus. Praesent aliquam, enim at fermentum mollis, ligula massa adipiscing nisl, ac euismod nibh nisl eu lectus. Fusce vulputate sem at sapien. Vivamus leo. Aliquam euismod libero eu enim. Nulla nec felis sed leo placerat imperdiet. Aenean suscipit nulla in justo. Suspendisse cursus rutrum augue. Nulla tincidunt tincidunt mi. Curabitur iaculis, lorem vel rhoncus faucibus, felis magna fermentum augue, et ultricies lacus lorem varius purus. Curabitur eu amet."];
    [contentView addSubview:b];
    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    [CPMenu setMenuBarVisible:YES];
    
    var tbItem1 = [[CPToolbarItem alloc] initWithItemIdentifier:@"1"];
    [tbItem1 setLabel:@"Mouse over me"];
    [tbItem1 setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"test.png"] size:CPSizeMake(35, 32)]];
    [tbItem1 setToolTip:@"Hey guys, I'm a toolbar tooltip! Isn't it cool?"];
    _toolbarItems = [tbItem1];
    
    var tb = [[CPToolbar alloc] init];
    [tb setDelegate:self];
    [theWindow setToolbar:tb];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return _toolbarItems;
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return _toolbarItems;
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return _toolbarItems[0];
}
@end
