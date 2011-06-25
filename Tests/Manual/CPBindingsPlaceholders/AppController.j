/*
 * AppController.j
 * BindingsPlaceholders
 *
 * Created by You on June 9, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow            theWindow; //this "outlet" is connected automatically by the Cib
    CPTextField         placeholderIB;    
    CPTextField         placeholderCode;    
    CPTextField         placeholderClassDefault;
    CPArrayController   arrayController;
}

+ (void)initialize
{
    [CPTextField setDefaultPlaceholder:@"CLASS_DEFAULT_NO_SELECTION" forMarker:CPNoSelectionMarker withBinding:CPValueBinding];
    [CPTextField setDefaultPlaceholder:@"CLASS_DEFAULT_MULTIPLE_SELECTION" forMarker:CPMultipleValuesMarker withBinding:CPValueBinding];
    [CPTextField setDefaultPlaceholder:@"CLASS_DEFAULT_NULL" forMarker:CPNullMarker withBinding:CPValueBinding];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    var objone = [CPDictionary dictionaryWithObject:@"A" forKey:@"value"],
        objtwo = [CPDictionary dictionaryWithObject:@"B" forKey:@"value"],
        objthree = [CPDictionary dictionary];

    var array = [CPArray arrayWithObjects:objone, objtwo, objthree];
    [arrayController setContent:array];

    var options = [CPDictionary dictionary];
    [options setObject:@"CODE_NO_SELECTION" forKey:CPNoSelectionPlaceholderBindingOption]
    [options setObject:@"CODE_MULTIPLE_SELECTION" forKey:CPMultipleValuesPlaceholderBindingOption]
    [options setObject:@"CODE_NULL" forKey:CPNullPlaceholderBindingOption]

    [placeholderCode bind:CPValueBinding toObject:arrayController withKeyPath:@"selection.value" options:options];

    [self deselect:nil];

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (void)selectMultiple:(id)sender
{
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,2)]];
}

- (void)deselect:(id)sender
{
    [arrayController setSelectionIndexes:[CPIndexSet indexSet]];
}

- (void)selectNil:(id)sender
{
    [arrayController setSelectionIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(2,1)]];
}

@end
