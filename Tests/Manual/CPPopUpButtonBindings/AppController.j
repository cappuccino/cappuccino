/*
 * AppController.j
 * CPPopUpButtonBindings
 *
 * Created by You on December 2, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    @outlet CPPopUpButton tagPopUp;

    CPArray people @accessors;
}

- (void)awakeFromCib
{
    var array = [];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"John",@"name",@"Butcher",@"job",@"john@meat.com",@"email", 2, @"tag"]];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Alberto",@"name",@"Seller",@"job",@"alberto@gmail.com",@"email", 0, @"tag"]];
    [array addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Barack",@"name",@"President",@"job",@"barack@whitehouse.gov",@"email", 1, @"tag"]];

    [self setPeople:array];
    
// Setup tags for the second popup
    var items = [tagPopUp itemArray];
    [items enumerateObjectsUsingBlock:function(item, idx)
    {
        [item setTag:idx];
        [item setTitle:([item title] + "    Tag:" + idx)];
    }];
    
    [mainWindow setFullBridge:YES];

}

@end

