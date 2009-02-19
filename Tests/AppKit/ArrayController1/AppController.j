/*
 * AppController.j
 * ArrayController
 *
 * Created by __Me__ on __Date__.
 * Copyright 2008 __MyCompanyName__. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPArrayController.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPArray             itemsArray;
    
    //CPTableView         tableView;
    //CPTextField         selectedNameField;
    //CPTextField         selectedPriceField;
    CPTextField         totalCountField;
    
    CPArrayController   arrayController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    //create our non ui objects
    
    itemsArray = [[Item new]];

    arrayController = [[CPArrayController alloc] init];

    [arrayController setEditable:YES];
    [arrayController setObjectClass:Item];
    [arrayController setAutomaticallyPreparesContent:YES];
    
    [arrayController setSelectsInsertedObjects:YES];
    [arrayController setAvoidsEmptySelection:YES];

    //create our UI elements
    
    //tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 200)];
    //[tableView setCenter:[contentView center]];
    
    totalCountField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 300, 20)];
    [totalCountField setCenter:[contentView center]];
    
    [totalCountField setStringValue:@"HELLO WORLD"];
    
    [contentView addSubview:totalCountField];
    
    var frame = [totalCountField frame],
        button = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(frame)+100, CGRectGetMaxY(frame)+10, 100, 18)];

    [button setTitle:"ADD"];
    [button setTarget:arrayController];
    [button setAction:@selector(add:)];
    
    [contentView addSubview:button];
    
    button = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(frame)+100, CGRectGetMaxY(frame)+38, 100, 18)];

    [button setTitle:"REMOVE"];
    [button setTarget:arrayController];
    [button setAction:@selector(remove:)];
    
    [contentView addSubview:button];

    //create our bindings
    
    [self createBindings];
    
    //order front window
    
    [theWindow orderFront:self];
}

- (void)createBindings
{
 	// bind array controller to self's itemsArray
    [arrayController bind:@"contentArray" toObject: self
			  withKeyPath:@"itemsArray" options:nil];

   // bind the total field -- no options on this one
	[totalCountField bind:CPValueBinding toObject:arrayController
			  withKeyPath:@"arrangedObjects.@sum.price" options:nil];
	
	
	//var bindingOptions = [CPDictionary dictionary];
	
	// binding options for "name"
	//[bindingOptions setObject:@"No Name" forKey:@"NSNullPlaceholder"];
	
	// binding for selected "name" field
    //[selectedNameField bind: @"value" toObject: arrayController
	//			withKeyPath:@"selection.name" options:bindingOptions];
	
	// binding for "name" column
    //var tableColumn = [tableView tableColumnWithIdentifier:@"name"];
	
	//[tableColumn bind:@"value" toObject: arrayController
	//	  withKeyPath:@"arrangedObjects.name" options:bindingOptions];
    
	
    // binding options for "price"
	// no need for placeholder as overridden by formatters
	//[bindingOptions removeObjectForKey:@"NSNullPlaceholder"];
	
	//[bindingOptions setObject:YES
	//				   forKey:CPValidatesImmediatelyBindingOption];
	
	// binding for selected "price" field
	//[selectedPriceField bind: @"value" toObject: arrayController
	//			 withKeyPath:@"selection.price" options:bindingOptions];
	
	
	// binding for "price" column
    //tableColumn = [tableView tableColumnWithIdentifier:@"price"];
	
    //[tableColumn bind:@"value" toObject: arrayController
	//	  withKeyPath:@"arrangedObjects.price" options:bindingOptions];
	
	
}

- (unsigned int)countOfItemsArray 
{
    return [itemsArray count];
}

- (id)objectInItemsArrayAtIndex:(unsigned int)index 
{
    return [itemsArray objectAtIndex:index];
}

- (void)insertObject:(id)anObject inItemsArrayAtIndex:(unsigned int)index 
{
    [itemsArray insertObject:anObject atIndex:index];
}

- (void)removeObjectFromItemsArrayAtIndex:(unsigned int)index 
{
    [itemsArray removeObjectAtIndex:index];
}

- (void)replaceObjectInItemsArrayAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [itemsArray replaceObjectAtIndex:index withObject:anObject];
}

@end

@implementation Item : CPObject
{
    float price @accessors;
}

- (id)init
{
    self = [super init];
    price = 1.0;
    return self;
}

- (BOOL)validatePrice:(id)value error:({CPError})error
{
    if ([value intValue] >= 0)
        return YES;

    return NO;
}

@end
