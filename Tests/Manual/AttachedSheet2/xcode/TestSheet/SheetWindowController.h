//
//  SheetWindowController.h
//  
//
//  Created by Joe Semolian on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SheetWindowController : NSWindowController
{
    IBOutlet NSButton* _closeButton;
    IBOutlet NSButton* _altCloseButton;
    IBOutlet NSButton* _otherCloseButton;
    IBOutlet NSButton* _orderOutAfterCheckbox;
    IBOutlet NSMatrix* _windowTypeMatrix;
    
    IBOutlet NSButton* _titledMaskButton;
    IBOutlet NSButton* _closableMaskButton;
    IBOutlet NSButton* _miniaturizableMaskButton;
    IBOutlet NSButton* _resizableMaskButton;
    
    IBOutlet NSButton* _shadeWindowView;
    IBOutlet NSButton* _shadeContentView;
    IBOutlet NSButton* _shadeParentWindow;
    
    NSArray*  _childControllers;
    NSWindow* _parentWindow;
}

-(IBAction)newWindow:(id)sender;
-(IBAction)newModalWindow:(id)sender;
-(IBAction)newSheet:(id)sender;
-(IBAction)newModalSheet:(id)sender;
-(IBAction)newAlertSheet:(id)sender;
-(IBAction)newColorPanelSheet:(id)sender;
-(IBAction)newOpenPanelSheet:(id)sender;
-(IBAction)newSavePanelSheet:(id)sender;

- (void)windowWillBeginSheet:(NSNotification *)notification;
- (void)windowDidEndSheet:(NSNotification *)notification;
@end
