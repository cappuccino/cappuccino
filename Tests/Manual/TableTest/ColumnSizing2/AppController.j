/*
 * AppController.j
 * ColumnSizing2
 *
 * Created by Alexander Ljungberg on October 20, 2011.
 * Copyright 2011, WireLoad All rights reserved.
 */

@import <Foundation/CPObject.j>

WIDTH = 800;
HEIGHT = 600;

@implementation AppController : CPObject
{
    CPView fixedSizeView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        colors = [
            [CPColor colorWithCSSString:"rgb(255, 0, 0)"],
            [CPColor colorWithCSSString:"rgb(0, 255, 0)"],
            [CPColor colorWithCSSString:"rgb(0, 0, 255)"],
            [CPColor colorWithCSSString:"rgb(255, 255, 0)"],
            [CPColor colorWithCSSString:"rgb(0, 255, 255)"],
            [CPColor colorWithCSSString:"rgb(255, 0, 255)"]
        ],
        colorIndex = 0;

    fixedSizeView = [[CPView alloc] initWithFrame:CGRectMake(10, 10, WIDTH, HEIGHT)],
    [fixedSizeView setAutoresizingMask:CPViewMaxXMargin | CPViewMaxYMargin];
    [contentView addSubview:fixedSizeView];

    for (var x = 0; x < 2; x++)
    {
        for (var y = 0; y < 3; y++)
        {
            var aView = [[CPScrollView alloc] initWithFrame:CGRectMake(x * WIDTH / 2 + (y + x), y * HEIGHT / 3, WIDTH / 2 - 5 - (y + x), HEIGHT / 3 - 5)],
                aTable = [[CPTableView alloc] initWithFrame:CGRectMakeCopy([aView bounds])];

            [aView setBorderType:CPLineBorder];
            [aView setBackgroundColor:colors[colorIndex]];
            colorIndex = (colorIndex + 1) % [colors count];

            aTable._meta = { 'x': x, 'y': y };
            [aTable setDataSource:self];
            [aTable setDelegate:self];
            [aTable setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
            [aTable setUsesAlternatingRowBackgroundColors:YES];

            [aTable setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
            [aTable setAllowsMultipleSelection:YES];

            for (var c = 0; c < 4; c++)
            {
                var column = [[CPTableColumn alloc] initWithIdentifier:c];
                [aTable addTableColumn:column];
                [[column headerView] setStringValue:"Column " + c];
                [column setWidth:WIDTH / 2 / 5];
            }

            [aView setDocumentView:aTable];

            [fixedSizeView addSubview:aView];

            [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        }
    }

    var offsetLabel = [CPTextField labelWithTitle:@"Squeeziness: "];
    [offsetLabel sizeToFit];
    [offsetLabel setFrameOrigin:CGPointMake(WIDTH + 20, 13)];
    [contentView addSubview:offsetLabel];

    var offsetField = [CPTextField textFieldWithStringValue:"0" placeholder:"squeeziness" width:100];
    [offsetField setFrame:CGRectMake(CGRectGetMaxX([offsetLabel frame]) + 10, CGRectGetMinY([offsetLabel frame]) - 3, 100, 25)];
    [offsetField setTarget:self];
    [offsetField setAction:@selector(squeeze:)];
    [contentView addSubview:offsetField];

    var instructionLabel = [CPTextField labelWithTitle:@"As you enter increasing numbers into squeeziness and hit enter, the tables will shrink. The columns should resize appropriately and the header dividing lines should not disappear at any squeeziness level. When this test was created, entering a value of 50 caused lines to disappear."];
    [instructionLabel setFrame:CGRectMake(CGRectGetMinX([offsetLabel frame]), CGRectGetMaxY([offsetLabel frame]) + 10, 250, 150)];
    [instructionLabel setLineBreakMode:CPLineBreakByWordWrapping];
    [contentView addSubview:instructionLabel];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (int)numberOfRowsInTableView:(id)tableView
{
    return tableView._meta['x'] + tableView._meta['y'] * 2;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    return "Column " + [aColumn identifier] + " Row " + aRow;
}

- (void)squeeze:(id)sender
{
    [fixedSizeView setFrameSize:CGSizeMake(WIDTH - [sender intValue], HEIGHT)];
}

@end
