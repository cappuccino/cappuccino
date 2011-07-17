/*
 * AppController.j
 * CPTableViewLionCibTest
 *
 * Created by You on March 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView;

    @outlet CPTextField textField;
    CPArray content @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)note
{
    content = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"Data.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [theWindow setFullBridge:YES];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        theRows = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

     [self setContent:theRows];
}

- (void)tableView:(CPTableView)aTableView dataViewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var value = [[content objectAtIndex:aRow] objectForKey:[aTableColumn identifier]],
        identifier = [value objectForKey:@"identifier"],
        view = [aTableView makeViewWithIdentifier:identifier owner:self];

    // this is equivalent of binding the valueURL binding of NSImageView in IB to view.objectValue.image
    if (identifier == @"person")
    {
        var filename = [value objectForKey:@"image"];
        if (filename == nil || filename == @"")
            filename = @"na.png";

        var path = [[CPBundle mainBundle] pathForResource:filename],
            image = [[CPImage alloc] initByReferencingFile:path size:CGSizeMake(100,133)];
        [[view imageView] setImage:image];
    }

    if (view == nil)
        view = [[CPTableCellView alloc] initWithFrame:CGRectMakeZero()];

    return view;
}

- (void)awakeFromCib
{
    // Called each time a cib is instatiated because we set the owner to self. Certainly a better idea to have a separate table view delegate if you need awakeFromCib to do some initialization in the AppController.
    CPLogConsole(_cmd + textField);
}

- (IBAction)_sliderAction:(id)sender
{
// Action sent from a cellView subview. You can access outlets (built-in or custom) defined in CPTableCellView or a subclass if you define the same outlets in the owner class.In this example, the owner is self.
    CPLogConsole(_cmd);
}

@end
