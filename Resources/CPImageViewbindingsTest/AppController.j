/*
 * AppController.j
 * CPImageViewbindingsTest
 *
 * Created by You on March 13, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPArray     content @accessors;
}

- (void)awakeFromCib
{
    content = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"images.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [theWindow setFullPlatformWindow:YES];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        theRows = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    // Add a CPImage to the model to test CPValueBinding.
    var path = [[CPBundle mainBundle] pathForResource:@"value.jpg"],
        image = [[CPImage alloc] initWithContentsOfFile:path],
        dict = [CPDictionary dictionaryWithObject:image forKey:@"image"];

    [theRows insertObject:dict atIndex:1];
    [self setContent:theRows];
}

@end
