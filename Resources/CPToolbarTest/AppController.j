/*
 * AppController.j
 * CPToolbarTest
 *
 * Created by Alexander Ljungberg on June 12, 2012.
 * Copyright 2012, SlevenBits Ltd. All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // We want to test all combinations of:
    // Label/Icon/Label and Icon/Small/Normal/Has oversized item.

    var NO_LABEL        = 1 << 0,
        NO_ICON         = 1 << 1,
        HAS_TALL_ITEM   = 1 << 2,
        IS_SMALL        = 1 << 3,
        windows = [],
        x = 10,
        y = 30;

    for (var i = 0; i < (NO_LABEL | NO_ICON | IS_SMALL | HAS_TALL_ITEM); i++)
    {
        var hasLabel = !(i & NO_LABEL),
            hasIcon = !(i & NO_ICON),
            isSmall = !!(i & IS_SMALL),
            hasTallItem = !!(i & HAS_TALL_ITEM);

        if (!hasLabel && !hasIcon)
            continue;

        // A tall item where the view isn't visible is just a label so don't bother showing that.
        if (!hasIcon && hasTallItem)
            continue;

        var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(x, y, 400, 20) styleMask:CPTitledWindowMask | CPResizableWindowMask],
            contentView = [theWindow contentView];

        [theWindow setTitle:"Toolbar (LBL: " + hasLabel + " ICN: " + hasIcon + " SMALL: " + isSmall + " TALLITEM: " + hasTallItem + ")"];

        var toolbarDelegate = [ToolbarDelegate new],
            items = [@"new"];
        if (!isSmall)
            [items addObject:@"colour"];
        if (hasTallItem)
            [items addObject:@"tallitem"];
        [toolbarDelegate setItems:items];

        var toolbar = [CPToolbar new];
        [toolbar setSizeMode:isSmall ? CPToolbarSizeModeSmall : CPToolbarSizeModeRegular];
        if (hasLabel && hasIcon)
            [toolbar setDisplayMode:CPToolbarDisplayModeIconAndLabel];
        else if (hasLabel)
            [toolbar setDisplayMode:CPToolbarDisplayModeLabelOnly];
        else
            [toolbar setDisplayMode:CPToolbarDisplayModeIconOnly];

        [toolbar setDelegate:toolbarDelegate];
        [theWindow setToolbar:toolbar];

        windows[i] = theWindow;

        [theWindow orderFront:nil];

        y += [theWindow frame].size.height + 10;
        if (y + 80 > [[theWindow platformWindow] visibleFrame].size.height)
        {
            y = 30;
            x += 430;
        }
    }
}


@end

@implementation ToolbarDelegate : CPObject
{
    CPArray items @accessors;
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return items;
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return items;
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if (itemIdentifier == "colour")
    {
        [toolbarItem setLabel:@"Colour"];
        [toolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"CPImageNameColorPanel.png"] size:CGSizeMake(26, 29)]];
        return toolbarItem;
    }
    else if (itemIdentifier == "new")
    {
        [toolbarItem setLabel:@"Small New"];
        [toolbarItem setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"New.png"] size:CGSizeMake(16, 16)]];
        return toolbarItem;
    }
    else if (itemIdentifier == "tallitem")
    {
        [toolbarItem setLabel:@"Tall Item"];
        [toolbarItem setMinSize:CGSizeMake(60, 70)];
        [toolbarItem setMaxSize:CGSizeMake(60, 70)];

        var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 60, 70)];

        for (var i = 0; i < 3; i++)
        {
            var slider = [[CPSlider alloc] initWithFrame: CGRectMake(0, i * 25, 60, 20)];
            [view addSubview:slider];
        }

       [toolbarItem setView:view];
       return toolbarItem;
    }
}

@end
