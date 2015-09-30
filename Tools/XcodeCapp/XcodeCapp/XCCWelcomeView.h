//
//  XCCProjectsFolderDropView.h
//  XcodeCapp
//
//  Created by Antoine Mercadal on 6/4/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XCCMainController;


@interface XCCWelcomeView : NSBox <NSDraggingDestination>
{
    IBOutlet NSBox                  *boxImport;
    IBOutlet NSProgressIndicator    *loadingIndicator;
}

@property XCCMainController         *mainXcodeCappController;

- (void)showLoading:(BOOL)shouldShow;

@end
