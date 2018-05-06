/*
 * AppController.j
 * 44-Sorting-CPTableView
 *
 * Created by Argos Oz on May 1, 2018.
 * 2018, Army of Me
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "Person.j"

@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    @outlet CPTableView     _tableView;
            CPMutableArray  _people @accessors(property=people);
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    _people = [[CPMutableArray alloc] init];

    [_tableView setSortDescriptors:
            @[
                [CPSortDescriptor sortDescriptorWithKey:@"name"
                                ascending:YES 
                                selector:@selector(caseInsensitiveCompare:)
                ],
                [CPSortDescriptor sortDescriptorWithKey:@"age"
                                ascending:YES
                ]
            ]
    ];
    
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:NO];
}

@end
