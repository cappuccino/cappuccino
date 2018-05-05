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

@implementation CPSearchField(XXX)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPPredicateBinding)
        return [_CPSearchFieldPredicateBinder class];

    return [super _binderClassForBinding:aBinding];
}

@end

@implementation _CPSearchFieldPredicateBinder : CPBinder
{
    CPArrayController  _controller;
    CPString           _predicteFormat;

}
- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (aBinding === CPPredicateBinding)
    {
        var options = [_info objectForKey:CPOptionsKey];

        _controller = [_info objectForKey:CPObservedObjectKey];
        _predicteFormat = [options objectForKey:"CPPredicateFormat"];
        [_source bind:CPValueBinding toObject:self withKeyPath:"searchFieldValue" options:nil];
    }
}
- (void)setSearchFieldValue:(CPString)aValue
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath     = [_info objectForKey:CPObservedKeyPathKey];

    var formatString = _predicteFormat.replace(/\$value/g, "%@");
    [self suppressSpecificNotificationFromObject:destination keyPath:keyPath];

    if (aValue)
        [_controller setFilterPredicate:[CPPredicate predicateWithFormat:formatString, aValue]];
    else
        [_controller setFilterPredicate:nil];

    [self unsuppressSpecificNotificationFromObject:destination keyPath:keyPath];
}
- (CPString)searchFieldValue
{
    return [_source stringValue];
}

@end


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
