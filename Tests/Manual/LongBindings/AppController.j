/*
 * AppController.j
 * bindings-bug
 *
 * Created by You on November 2, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow                        _mainWindow @accessors(property=mainWindow, readonly);

    @outlet CPTableView                     _ordersTableView @accessors(property=ordersTableView, readonly);
    CPArrayController                       _ordersArrayController @accessors(property=ordersArrayController, readonly);

    @outlet CPTextField                     _nameLabel @accessors(property=nameLabel, readonly);
    @outlet CPTextField                     _emailLabel @accessors(property=emailLabel, readonly);
    @outlet CPTextField                     _jobLabel @accessors(property=jobLabel, readonly);
}

- (void)awakeFromCib
{
    [[self mainWindow] setFullPlatformWindow:YES];

    orders = [];
    [orders addObject:[Order orderWithCustomer:[Customer customerWithName:@"Klaas Pieter" email:@"klaaspieter@madebysofa.com" job:@"Programmer"]]];
    [orders addObject:[Order orderWithCustomer:[Customer customerWithName:@"Koen" email:@"koen@madebysofa.com" job:@"Programmer"]]];
    [orders addObject:[Order orderWithCustomer:[Customer customerWithName:@"Jorn" email:@"jorn@madebysofa.com" job:@"Designer"]]];
    _ordersArrayController = [[CPArrayController alloc] initWithContent:orders];

    // [[self ordersTableView] setDataSource:self];
    // [[self ordersTableView] bind:@"selectionIndexes" toObject:[self ordersArrayController] withKeyPath:@"selectionIndexes" options:nil];

    [[self ordersTableView] bind:@"content" toObject:[self ordersArrayController] withKeyPath:@"arrangedObjects" options:nil];

    var nameColumn = [[self ordersTableView] tableColumnWithIdentifier:@"name"];
    [nameColumn bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"arrangedObjects.customer.name" options:nil];
    var emailColumn = [[self ordersTableView] tableColumnWithIdentifier:@"email"];
    [emailColumn bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"arrangedObjects.customer.email" options:nil];
    var jobColumn = [[self ordersTableView] tableColumnWithIdentifier:@"job"];
    [jobColumn bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"arrangedObjects.customer.job" options:nil];

    [[self nameLabel] bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"selection.customer.name" options:nil];
    [[self emailLabel] bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"selection.customer.email" options:nil];
    [[self jobLabel] bind:@"value" toObject:[self ordersArrayController] withKeyPath:@"selection.customer.job" options:nil];

    [[self ordersTableView] reloadData];
}

// - (int)numberOfRowsInTableView:(CPTableView)theTableView
// {
//     return [[[self ordersArrayController] arrangedObjects] count];
// }
//
// - (id)tableView:(CPTableView)theTableView objectValueForTableColumn:(CPTableColumn)theColumn row:(int)theRow
// {
//     var order = [[[self ordersArrayController] arrangedObjects] objectAtIndex:theRow];
//     return [[order customer] valueForKey:[theColumn identifier]];
// }

@end


@implementation Order : CPObject
{
    Customer                    _customer @accessors(property=customer);
}

+ (id)orderWithCustomer:(Customer)theCustomer
{
    return [[self alloc] initWithCustomer:theCustomer];
}

- (id)init
{
    return [self initWithCustomer:nil];
}

- (id)initWithCustomer:(Customer)theCustomer
{
    if (self = [super init])
    {
        _customer = theCustomer;
    }

    return self;
}

@end

@implementation Customer : CPObject
{
    CPString                        _name @accessors(property=name);
    CPString                        _email @accessors(property=email);
    CPString                        _job @accessors(property=job);
}

+ (id)customerWithName:(CPString)theName email:(CPString)theEmail job:(CPString)theJob
{
    return [[self alloc] initWithName:theName email:theEmail job:theJob]
}

- (id)initWithName:(CPString)theName email:(CPString)theEmail job:(CPString)theJob
{
    if (self = [super init])
    {
        _name = theName;
        _email = theEmail;
        _job = theJob;
    }

    return self;
}

@end

