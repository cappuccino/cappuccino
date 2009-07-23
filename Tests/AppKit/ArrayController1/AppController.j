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
//    CPArray             itemsArray;
    CPSet               itemsSet;
    CPWindow            theWindow;

    //CPTableView         tableView;
    //CPTextField         selectedNameField;
    //CPTextField         selectedPriceField;
    CPTextField         totalCountField;
    
    CPArrayController   arrayController;
}

- (void)awakeFromCib
{
    var contentView = [theWindow contentView];

    //create our non ui objects

    /*var objectController = [[CPObjectController alloc] init];
    self.managed = 5;
    [objectController bind:@"contentObject" toObject:self withKeyPath:@"managed" options:nil];
    console.log([objectController content]);
    console.log("f!: " + [self.managed description]);
    [objectController addObject:[CPDictionary dictionary]];
    console.log("f!: " + [self.managed description]);
    */

    itemsArray = [[Item new]];
    itemsSet = [[Item new]];

    arrayController = [[CPArrayController alloc] init];

    [arrayController setEditable:YES];
    [arrayController setObjectClass:Item];
    [arrayController setAutomaticallyPreparesContent:YES];
    
    [arrayController setSelectsInsertedObjects:YES];
    [arrayController setAvoidsEmptySelection:YES];

    //create our UI elements

    //tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 200)];
    //[tableView setCenter:[contentView center]];

    //create our bindings

    [self createBindings];

    //order front window

    [theWindow setFullBridge:YES];
    [theWindow orderFront:self];
}

- (void)add:(id)aSender
{
    [arrayController add:self];
}

- (void)remove:(id)aSender
{
    [arrayController remove:self];
}

- (void)createBindings
{
 	// bind array controller to self's itemsArray
    [arrayController bind:@"contentSet" toObject:self
			  withKeyPath:@"itemsSet" options:nil];

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
/*
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
*/
@end

@implementation Item : CPObject
{
    float price @accessors;
}

- (id)init
{
    self = [super init];
    price = 7.0;
    return self;
}

- (BOOL)validatePrice:(id)value error:({CPError})error
{
    if ([value intValue] >= 0)
        return YES;

    return NO;
}

@end
