//
//  SheetWindowController.m
//  
//
//  Created by Joe Semolian on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SheetWindowController.h"

@interface SheetWindowController ()

@end

@implementation SheetWindowController

- (id)initWithWindow:(NSWindow *)window
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
    self = [super initWithWindow:window];
    if (self)
    {
        _closeButton = nil;
        _childControllers = [NSArray array];
    }
     
    return self;
}

- (void)windowDidLoad
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));

    [super windowDidLoad];
    
    if (!_closeButton)
        NSLog(@"[%@ %s]: _closeButton is not connected!", [self className], sel_getName(_cmd));
}

-(void)positionWindow
{
	NSWindow* keyWindow = [NSApp keyWindow];
	CGPoint origin = ([keyWindow frame]).origin;
	origin = CGPointMake(origin.x + 20, origin.y + 20);
	[[self window] setFrameOrigin:origin];
}

//
// Normal window
//
-(void)newDocument:(id)sender
{
    [self newWindow:sender];
}

-(SheetWindowController*)initWithStyleMask:(int)styleMask
{

    if (styleMask==0)
        return [self initWithWindowNibName:@"Window"];
    
    NSWindow* window = [ [NSWindow alloc] 
                    initWithContentRect:CGRectMake(0,0,400,300)
                                styleMask:styleMask
                                backing:NSBackingStoreBuffered
                                defer:YES];

    if (self = [super initWithWindow:window])
    {
        _closeButton = [ [NSButton alloc] initWithFrame:CGRectMake(0,0,32,100)];
        [_closeButton setTitle:@"Close"];
        [_closeButton setButtonType:NSMomentaryPushInButton];
        [_closeButton setBezelStyle:NSBezelBorder];
        [_closeButton sizeToFit];
        [[window contentView] addSubview:_closeButton];
    }
    
    return self;
}

-(SheetWindowController*)allocController
{
	long type = 1;
    if (_windowTypeMatrix)
        type = [ [_windowTypeMatrix selectedCell] tag];

    int styleMask = 0;
    if ([_titledMaskButton state])
        styleMask |= NSTitledWindowMask;
    
    if ([_closableMaskButton state])
        styleMask |= NSClosableWindowMask;
    
    if ([_miniaturizableMaskButton state])
        styleMask |= NSMiniaturizableWindowMask;
    
    switch (type)
    {
        case 2:
            styleMask |= NSTexturedBackgroundWindowMask;
            break;
        case 3:
            styleMask = NSBorderlessWindowMask;
            break;
        case 4:
            break;
        case 5:
            styleMask = NSDocModalWindowMask;
            break;
    }
    
    if ([_resizableMaskButton state])
        styleMask |= NSResizableWindowMask;
    
    if (type == 1)
        styleMask = 0;
    
    return [[SheetWindowController alloc] initWithStyleMask:styleMask];
}

-(void)newWindow:(id)sender
{
    SheetWindowController* controller = [self allocController];
    _childControllers = [_childControllers arrayByAddingObject:controller];
    [controller runNormalWindow];
}

-(void)runNormalWindow
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
	[self positionWindow];
	[[self window] setTitle:@"Normal Window"];	
	[_closeButton setTarget:[self window]];
	[_closeButton setAction:@selector(orderOut:)];
	[self showWindow:self];
}

-(void)newModalWindow:(id)sender
{
    SheetWindowController* controller = [self allocController];
    _childControllers = [_childControllers arrayByAddingObject:controller];
    [controller runModalWindow];
}

-(void)runModalWindow
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
	[[self window] setTitle:@"Modal Window"];
    [[self window] setDelegate:self];
	[_closeButton setTarget:self];
	[_closeButton setAction:@selector(endModalWindow:)];
	//[self showWindow:self];
	[NSApp runModalForWindow:[self window]];
}

-(void)endModalWindow:(id)sender
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
	[[self window] performClose:self];
}

-(void)windowWillClose:(NSNotification*)notification
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
 
    if ([NSApp modalWindow])
        [NSApp stopModal];
}

-(void)newSheet:(id)sender
{    
    SheetWindowController* controller = [self allocController];
    _childControllers = [_childControllers arrayByAddingObject:controller];
    [controller runSheetForWindow:[self window]];
}

-(void)runSheetForWindow:(NSWindow*)parentWindow
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
	NSWindow* sheet = [self window];
    [parentWindow setDelegate:self];
    _parentWindow = parentWindow;
    
	[_closeButton setTarget:self];
	[_closeButton setAction:@selector(closeSheet:)];
    [_altCloseButton setAction:@selector(closeSheetAndParent:)];
    [_otherCloseButton setAction:@selector(closeSheetAndRepeat:)];
    
	[NSApp beginSheet:sheet
       modalForWindow:parentWindow
		modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:(void*)self];
}

-(void)closeSheet:(id)sender
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
	
    // NOTE: orderOut is not required for Capp, but is for Cocoa. It does
    // not seem to matter when it is called in relation to endSheet:
    BOOL orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] close];
        //[[self window] orderOut:nil];
        
    [NSApp endSheet:[self window] returnCode:99];
    
    if (orderOutAfter)
        //[[self window] orderOut:nil];
        [[self window] close];
}

-(void)closeSheetAndParent:(id)sender
{
    // common use case is saving document in response to a close,
    // in this case we don't want to show the animation at all
    [_parentWindow close];
    
    BOOL orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];

    [NSApp endSheet:[self window] returnCode:99];
    
    if (orderOutAfter)
        [[self window] orderOut:nil];
}

-(void)closeSheetAndRepeat:(id)sender
{
    // common use case is showing a progress bar after a save command,
    // the orderout gets rid of the current sheet, 
    // the return code indicates to open another sheet up
    BOOL orderOutAfter = [_orderOutAfterCheckbox state];
    if (!orderOutAfter)
        [[self window] orderOut:nil];
    
    [NSApp endSheet:[self window] returnCode:77];
    if (orderOutAfter)
        [[self window] orderOut:nil];
}


-(void)newModalSheet:(id)sender
{
    SheetWindowController* controller = [self allocController];
    _childControllers = [_childControllers arrayByAddingObject:controller];
    [controller runModalSheetForWindow:[self window]];
}



-(void)runModalSheetForWindow:(NSWindow*)parentWindow
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
	NSWindow* sheet = [self window];
    [parentWindow setDelegate:self];
    _parentWindow = parentWindow;
    
	[_closeButton setTarget:self];
	[_closeButton setAction:@selector(closeModalSheet:)];
    
	[NSApp beginSheet:sheet
       modalForWindow:parentWindow
		modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:(void*)self];
    
	// what is the difference between these two approaches?		
	[NSApp runModalForWindow:sheet];
	
	//var session = [CPApp beginModalSessionForWindow:sheet];
	//[CPApp runModalSession:session];
}

-(void)closeModalSheet:(id)sender
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
	
    [[self window] orderOut:self];
    
    [NSApp endSheet:[self window]];
	
	// FIXME: there is no endModalSession: per Cocoa
	[NSApp stopModalWithCode:999];
}

-(void)newAlertSheet:(id)sender
{
    [[self window] setDelegate:self];
    _parentWindow = [self window];
    [self runAlertSheet:_parentWindow];
}

-(void)runAlertSheet:(NSWindow*)parentWindow
{
    NSAlert* alert = [NSAlert alertWithMessageText:@"Oops, something went wrong!" 
                                     defaultButton:@"DefaultButton" 
                                   alternateButton:@"AltButton" 
                                       otherButton:@"OtherButton" 
                         informativeTextWithFormat:@"If we knew why it went wrong, we would describe it here."];
    
    [alert beginSheetModalForWindow:[self window] 
                      modalDelegate:self
                     didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) 
                        contextInfo:nil];    
}


- (void)didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
    //NSAssert(sheet == [self window], @"sheet object is incorrect");
    
    // repeat with another sheet
    if (returnCode == 77)
        //[self runSheetForWindow:_parentWindow];
        [self runAlertSheet:_parentWindow];
}

- (void)windowWillBeginSheet:(NSNotification *)notification
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));

    NSAssert([notification object]==_parentWindow, @"notification object is not parent window");
}

- (void)windowDidEndSheet:(NSNotification *)notification
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));
    
    NSAssert([notification object]==_parentWindow, @"notification object is not parent window");
}

@end
