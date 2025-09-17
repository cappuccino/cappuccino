/*
 * AppController.j
 * TableBindings
 *
 * Created by You on January 16, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow; //this "outlet" is connected automatically by the Cib

    @outlet CPTextField locationField;
    @outlet CPTextField lengthField;
    @outlet CPPopUpButton KeyPathPopup;

    CPArray     rows @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    rows = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"rows.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [theWindow setFullPlatformWindow:YES];
}

- (void)awakeFromCib
{
    console.log(_cmd);
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        theRows = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

     [self setRows:theRows];
}

- (IBAction)updateOrReloadContent:(id)sender
{
    var range = CPMakeRange([locationField intValue], [lengthField intValue]),
        indexes = [CPIndexSet indexSetWithIndexesInRange:range],
        keyPath = [KeyPathPopup titleOfSelectedItem];

    var value = String.fromCharCode(97 + Math.round(Math.random() * 26));

    if ([sender tag] == 1000)
        [[rows objectsAtIndexes:indexes] setValue:value forKey:keyPath];
    else
    {
        var rowsCopy = [rows copy];
        [[rowsCopy objectsAtIndexes:indexes] setValue:value forKey:keyPath];
        [self setRows:rowsCopy];
    }
}

@end
