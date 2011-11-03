/*
 * This file is a part of program xcodecapp-cocoa
 * Copyright (C) 2011  Antoine Mercadal (primalmotion@archipelproject.org)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#import "PRHEmptyGrowlDelegate.h"
#import "TNXCodeCapp.h"

@interface AppController : NSObject <NSMenuDelegate>
{
    IBOutlet NSMenu                 *statusMenu;
    IBOutlet NSMenuItem             *menuItemOpenXCode;
    IBOutlet NSMenuItem             *menuItemStart;
    IBOutlet NSMenuItem             *menuItemStop;
    IBOutlet NSMenuItem             *menuItemProjectName;
    IBOutlet NSPanel                *errorsPanel;
    IBOutlet NSTableView            *errorsTable;
    IBOutlet NSWindow               *helpWindow;
    IBOutlet NSTextView             *helpTextView;
    IBOutlet NSTextField            *labelVersion;
    
    TNXCodeCapp                     *_xcc;
    NSImage                         *_iconActive;
    NSImage                         *_iconInactive;
    NSImage                         *_iconWorking;
    NSStatusItem                    *_statusItem;
    PRHEmptyGrowlDelegate           *growlDelegateRef;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
- (void)registerDefaults;
- (void)updateErrorTable;
- (void)growlWithTitle:(NSString *)aTitle message:(NSString *)aMessage;

- (IBAction)chooseFolder:(id)aSender;
- (IBAction)clearErrors:(id)sender;
- (IBAction)openXCode:(id)aSender;
- (IBAction)stopListener:(id)aSender;
- (IBAction)openHelp:(id)aSender;

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(int)aRow;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

@end

