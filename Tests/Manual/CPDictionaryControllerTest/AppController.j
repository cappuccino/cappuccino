/*
 * AppController.j
 * CPDictionaryControllerTest
 *
 * Created by Blair Duncan on February 17, 2013.
 * Copyright 2013, SGL Studio, BBDO Toronto All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPDictionaryController.j>


@implementation AppController : CPObject
{
    CPDictionaryController  dictionaryController @accessors;
    CPTableView             tableView @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    var dictionary = [CPDictionary dictionaryWithObjectsAndKeys:
                        @"867-5309", @"Phone Number", // Phone Number is in the Excluded List in the Xib
                        @"Blair", @"First Name",
                        @"Duncan", @"Last Name", 
                        @"Toronto", @"City"];
    [dictionaryController setContentDictionary:dictionary];
    [tableView reloadData];
}

- (void)nextHighlightStyle:(id)sender
{
    switch ([tableView selectionHighlightStyle])
    {
        case CPTableViewSelectionHighlightStyleNone :
            [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
            [sender setTitle:"CPTableViewSelectionHighlightStyleSourceList"];
            break;
            
        case CPTableViewSelectionHighlightStyleSourceList :
            [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleRegular];
            [sender setTitle:"CPTableViewSelectionHighlightStyleRegular"];
            break;
            
        default:
            [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];
            [sender setTitle:"CPTableViewSelectionHighlightStyleNone"];
    }

    [tableView setNeedsDisplay:YES];
}

- (BOOL)tableView:(CPTableView)tableView isGroupRow:(int)row
{
    return (row > 2 && row < 5);
}


@end
