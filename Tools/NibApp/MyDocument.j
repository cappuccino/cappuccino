//
// Document.j
// Editor
//
// Created by Francisco Tolmasky on May 21, 2008.
// Copyright 2005 - 2008, 280 North, Inc. All rights reserved.
//

import <AppKit/CPDocument.j>
import <AppKit/CPNib.j>


@implementation MyDocument : CPDocument
{
    CPTextField _textField;
}

- (void)windowControllerDidLoadNib:(CPWindowController)aWindowController
{
    [super windowControllerDidLoadNib:aWindowController];

    var nib = [[CPNib alloc] initWithContentsOfURL:@"MainMenu.cib"];

    var x = [nib instantiateNibWithExternalNameTable:nil];

    [x setBackgroundColor:[CPColor blueColor]];
    
    //alert([[x subviews] count]);

    [[[aWindowController window] contentView] addSubview:x];
}

@end
