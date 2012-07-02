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
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPArrayController arrayController;
    CPTextField from;
    CPTextField to;
    
    CPArray     rows @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    rows = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"rows.plist"],
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

     [self setRows:theRows];
}

- (void)test:(id)sender
{
    var range = CPMakeRange([from intValue], [to intValue]);
    var indexes = [CPIndexSet indexSetWithIndexesInRange:range];
    
    [[rows objectsAtIndexes:indexes] setValue:@"b" forKey:@"colTwo"];
}
@end
