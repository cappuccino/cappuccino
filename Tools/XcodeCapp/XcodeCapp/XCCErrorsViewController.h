//
//  XCCErrorsViewController.h
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XCCCappuccinoProjectController;


@interface XCCErrorsViewController : NSViewController  <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    IBOutlet NSOutlineView                  *errorOutlineView;
    IBOutlet NSBox                          *maskingView;
}

@property XCCCappuccinoProjectController *cappuccinoProjectController;

- (void)selectItem:(id)anItem;
- (void)reload;

- (IBAction)openErroredFileInEditor:(id)sender;
- (IBAction)cleanProjectErrors:(id)aSender;

@end
