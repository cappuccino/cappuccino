/*
 * AppController.j
 * ScrollPerformanceTest
 *
 * Created by You on August 27, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    [tableView setAllowsMultipleSelection:YES];
    [tableView setAllowsColumnSelection:YES];
    [tableView setUsesAlternatingRowBackgroundColors:YES];

    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [tableView setDelegate:self];
    [tableView setDataSource:self];

    
    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16,16,0,0)];
    [iconView setImageScaling:CPScaleNone];
    var iconColumn = [[CPTableColumn alloc] initWithIdentifier:"icons"];
    [iconColumn setWidth:32.0];
    [iconColumn setMinWidth:32.0];
    [iconColumn setDataView:iconView];
    //[tableView addTableColumn:iconColumn];

    iconImage = [[CPImage alloc] initWithContentsOfFile:"http://cappuccino.org/images/favicon.png" size:CGSizeMake(16,16)];


    for (var i = 1; i <= 5; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];

        [[column headerView] setStringValue:"Number " + i];

        [column setMaxWidth:500.0];
        [column setWidth:200.0];
        
        [tableView addTableColumn:column];
    }

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([contentView bounds]), CGRectGetHeight([contentView bounds]))];
   
    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    [contentView addSubview:scrollView];

    [theWindow orderFront:self];

}

- (int)numberOfRowsInTableView:(CPTableView)atableView
{
    return 500;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if ([aColumn identifier] === "icons")
        return iconImage;
    
    return aRow;
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(int)aRow
{
    console.log("called: "+aRow);
    var groups = [];

    for(var i = 0; i < 100; i+=5)
        groups.push(i);

    return [groups containsObject:aRow];
}

@end

@implementation CPTableView (foo)
- (void)_drawGroupRowsForRects:(CPArray)rects
{
    if (_selectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList || !rects.length)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        i = rects.length;

    CGContextBeginPath(context);

    var gradientCache = [self selectionGradientColors],
        topLineColor = [CPColor colorWithHexString:"d3d3d3"],
        bottomLineColor = [CPColor colorWithHexString:"bebebd"],
        gradientColor = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [220.0 / 255.0, 220.0 / 255.0, 220.0 / 255.0,1.0, 
                                                                                            199.0 / 255.0, 199.0 / 255.0, 199.0 / 255.0,1.0], [0,1], 2),
        drawGradient = YES;

        while (i--)
        {
            var rowRect = rects[i];

            CGContextAddRect(context, rowRect);

            if (drawGradient)
            {
                var minX = CGRectGetMinX(rowRect),
                    minY = CGRectGetMinY(rowRect),
                    maxX = CGRectGetMaxX(rowRect),
                    maxY = CGRectGetMaxY(rowRect);

                CGContextDrawLinearGradient(context, gradientColor, rowRect.origin, CGPointMake(minX, maxY), 0);
                CGContextClosePath(context);

                CGContextBeginPath(context);
                CGContextMoveToPoint(context, minX, minY);
                CGContextAddLineToPoint(context, maxX, minY);
                CGContextClosePath(context);
                CGContextSetStrokeColor(context, topLineColor);
                CGContextStrokePath(context);

                CGContextBeginPath(context);
                CGContextMoveToPoint(context, minX, maxY);
                CGContextAddLineToPoint(context, maxX, maxY - 1);
                CGContextClosePath(context);
                CGContextSetStrokeColor(context, bottomLineColor);
                CGContextStrokePath(context);
            }
        }

    CGContextClosePath(context);
}
@end