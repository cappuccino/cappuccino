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
    @outlet CPWindow            theWindow;
    @outlet CPTableView         tableView;
    @outlet CPTextField         totalCountField;
    @outlet CPTextField         selectedNameField;
    @outlet CPTextField         selectedPriceField;

    CPArray             itemsArray;
    @outlet CPArrayController   arrayController;
}

- (void)awakeFromCib
{
    var contentView = [theWindow contentView],
        notWrongItem = [Item new];

    [notWrongItem setRightOrWrong:"also right"];
    itemsArray = [[Item new], notWrongItem];

    [arrayController setEditable:YES];
    [arrayController setObjectClass:Item];
    [arrayController setAutomaticallyPreparesContent:YES];

    [arrayController setSelectsInsertedObjects:YES];
    [arrayController setAvoidsEmptySelection:YES];

    //create our UI elements

    //[tableView setCenter:[contentView center]];
    [tableView setBackgroundColor:[CPColor redColor]];
    [tableView setDelegate:self];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [column setEditable:YES];
    [[column headerView] setStringValue:@"Name"];
    [tableView addTableColumn:column];

    column = [[CPTableColumn alloc] initWithIdentifier:@"price"];
    [[column headerView] setStringValue:@"Price"];
    [tableView addTableColumn:column];

    column = [[CPTableColumn alloc] initWithIdentifier:@"all right"];
    [[column headerView] setStringValue:@"Righteousness"];
    [tableView addTableColumn:column];

    //[tableView setDataSource:self];

    //create our bindings

    [self createBindings];

    //order front window

    [theWindow setFullPlatformWindow:YES];
    [theWindow orderFront:self];
}
/*
- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return [itemsArray count];
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    return "foo";
}
*/

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{
    return YES;
}

- (void)createBindings
{
    // bind array controller to self's itemsArray

    [arrayController bind:@"contentArray" toObject:self withKeyPath:@"itemsArray" options:nil];

    // bind the total field -- no options on this one
    [totalCountField bind:CPValueBinding toObject:arrayController
              withKeyPath:@"selectedObjects.@sum.price" options:nil];

    var bindingOptions = @{};
    //[bindingOptions setObject:@"No Name" forKey:@"NSNullPlaceholder"];
    [selectedNameField bind:CPValueBinding toObject:arrayController
                withKeyPath:@"selection.name" options:bindingOptions];

    // binding for "name" column
    var tableColumn = [tableView tableColumnWithIdentifier:@"name"],
        bindingOptions = @{};

    [tableColumn bind:CPValueBinding toObject:arrayController
          withKeyPath:@"arrangedObjects.name" options:bindingOptions];


    // binding options for "price"
    // no need for placeholder as overridden by formatters
    bindingOptions = @{};
    //[bindingOptions removeObjectForKey:@"NSNullPlaceholder"];
    //[bindingOptions setObject:YES
    //                 forKey:CPValidatesImmediatelyBindingOption];
    [selectedPriceField bind:CPValueBinding toObject: arrayController
                 withKeyPath:@"selection.price" options:bindingOptions];

    // binding for "price" column
    tableColumn = [tableView tableColumnWithIdentifier:@"price"];
    bindingOptions = @{};
    [tableColumn bind:CPValueBinding toObject:arrayController
          withKeyPath:@"arrangedObjects.price" options:bindingOptions];

    tableColumn = [tableView tableColumnWithIdentifier:@"all right"];
    bindingOptions = [CPDictionary dictionaryWithObject:[WLWrongToRightTransformer new] forKey:CPValueTransformerBindingOption];
    [tableColumn bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.rightOrWrong" options:bindingOptions];
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

var ItemCounter = 0;

@implementation Item : CPObject
{
    float price @accessors;
    CPString name @accessors;
    CPString rightOrWrong @accessors;
}

- (id)init
{
    self = [super init];
    price = 7.0;
    name = "bob " + (ItemCounter++);
    rightOrWrong = "wrong";
    return self;
}

- (BOOL)validatePrice:(id)value error:(/*{*/CPError/*}*/)error
{
    if ([value intValue] >= 0)
        return YES;

    return NO;
}

@end

@implementation WLWrongToRightTransformer : CPValueTransformer
{
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+ (Class)transformedValueClass
{
    return [CPString class];
}

- (id)transformedValue:(id)aValue
{
    return aValue == "wrong" ? "right" : aValue;
}

@end
