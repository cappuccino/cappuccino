/*
 * AppController.j
 * LoadTimeTest
 *
 * Created by You on February 23, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var endLaunch = new Date();
    
    var data;
    if (window.location.search.length > 1)
        data = JSON.parse(decodeURIComponent(window.location.search.slice(1)))
    else
        data = [];
    
    data.push([endLoad - startLoad, endLaunch - endLoad]);
    
    if (data.length < 10)
    {
        // reload with data in the query string
        window.location.href = [window.location.protocol, "//", window.location.host, window.location.pathname, "?", encodeURIComponent(JSON.stringify(data))].join("");
    }
    else
    {
        var loadAvg = 0, loadStdev = 0, launchAvg = 0, launchStdev = 0;
        for (var i = 0; i < data.length; i++) {
            loadAvg += data[i][0];
            launchAvg += data[i][1];
        }
        
        loadAvg /= data.length;
        launchAvg /= data.length;
        
        for (var i = 0; i < data.length; i++) {
            loadStdev += POW(data[i][0] - loadAvg, 2);
            launchStdev += POW(data[i][1] - launchAvg, 2);
        }
        
        loadStdev = SQRT(loadStdev / data.length);
        launchStdev = SQRT(launchStdev / data.length);

        if (window.parent.BCOMM) {
            window.parent.BCOMM.finishTest({
                loadAvg : loadAvg,
                launchAvg : launchAvg,
                loadStdev : loadStdev,
                launchStdev : launchStdev
            });
        }

        var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
            contentView = [theWindow contentView];

        var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [label setStringValue:"load avg="+ROUND(loadAvg)+" (stdev="+ROUND(loadStdev)+"); launch avg="+ROUND(launchAvg)+" (stdev="+ROUND(launchStdev)+")"];
        [label setFont:[CPFont boldSystemFontOfSize:24.0]];

        [label sizeToFit];

        [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [label setCenter:[contentView center]];

        [contentView addSubview:label];

        [theWindow orderFront:self];

        // Uncomment the following line to turn on the standard menu bar.
        //[CPMenu setMenuBarVisible:YES];
    }
}

@end
