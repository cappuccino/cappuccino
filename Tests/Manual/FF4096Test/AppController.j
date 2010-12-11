/* 
 * AppController.j
 * FFTest
 *
 * Created by C. Blair Duncan on September 22, 2010.

This test will verify that the framework is or is not returning truncated data in Firefox.
See issue: http://githubissues.heroku.com/#280north/cappuccino/842
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];


    //due to FireFox x-site and not allowing local file bs, we just read a file from the resourse folder...
	var aURL = [CPURL URLWithString:[[CPBundle mainBundle] pathForResource:@"sampleXML.data"]];

    // note, normally you should not be using a synchronous request for your work 
    var data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:aURL] returningResponse:NULL];

    var dict = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    var theData = [dict valueForKey:@"LongString"];
    alert("Read " + theData.length + " bytes, \(should be 8122\)");


    var label = [[CPTextField alloc] initWithFrame:[contentView bounds]];
    [label setLineBreakMode:CPLineBreakByWordWrapping]; 
    [label setStringValue:theData];
    [label setFont:[CPFont systemFontOfSize:14.0]];
    [label setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:label];
    [theWindow orderFront:self];
}


@end
