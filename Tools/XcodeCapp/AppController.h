/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2011  Antoine Mercadal (<primalmotion@archipelproject.org>)
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
#import "TNErrorDataView.h"

@interface AppController : NSObject <NSMenuDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSMenu                     *statusMenu;
    IBOutlet NSMenuItem                 *menuItemOpenXCode;
    IBOutlet NSMenuItem                 *menuItemStartStop;
    IBOutlet NSPanel                    *errorsPanel;
    IBOutlet NSTableView                *errorsTable;
    IBOutlet NSPanel                    *aboutWindow;
    IBOutlet NSWindow                   *helpWindow;
    IBOutlet NSTextView                 *helpTextView;
    IBOutlet NSTextField                *labelVersion;
    IBOutlet NSPopUpButton              *buttonPreferencesAPIMode;
    IBOutlet NSButton                   *checkBoxPreferencesReactMode;
    IBOutlet NSUserDefaultsController   *preferencesController;
    IBOutlet TNXCodeCapp                *__strong xcc;
    IBOutlet NSWindow                   *windowDebug;
    IBOutlet NSMenuItem                 *menuDebug;
    IBOutlet NSMenuItem                 *menuHistory;
    IBOutlet TNErrorDataView            *dataViewError;

    NSImage                             *_iconActive;
    NSImage                             *_iconInactive;
    NSImage                             *_iconWorking;
    NSStatusItem                        *_statusItem;
    PRHEmptyGrowlDelegate               *growlDelegateRef;
    NSData                              *_archivedDataView;
}

@property BOOL supportsFileModeListening;
@property (strong) TNXCodeCapp *xcc;

+ (AppController *)sharedAppController;

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;
- (void)registerDefaults;
- (void)growlWithTitle:(NSString *)aTitle message:(NSString *)aMessage;
- (void)openCenteredWindow:(NSWindow *)aWindow;
- (void)_prepareHistoryMenu;

- (IBAction)chooseFolder:(id)aSender;
- (IBAction)openErrors:(id)sender;
- (IBAction)clearErrors:(id)sender;
- (IBAction)openXCode:(id)aSender;
- (IBAction)stopListener:(id)aSender;
- (IBAction)openHelp:(id)aSender;
- (IBAction)openAbout:(id)aSender;
- (IBAction)updatePreferences:(id)aSender;
- (IBAction)switchProject:(id)aSender;
- (IBAction)clearProjectHistory:(id)aSender;

@end

