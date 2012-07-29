//
//  AppDelegate.h
//  TestSheet
//
//  Created by Joe Semolian on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SheetWindowController.h"

@interface AppController : NSObject <NSApplicationDelegate>
{
    SheetWindowController* _sheetController;
}
@end
