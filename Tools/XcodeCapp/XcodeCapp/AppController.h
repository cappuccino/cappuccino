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

#import "TNXcodeCapp.h"

@interface AppController : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property (strong) IBOutlet NSMenu     *statusMenu;
@property (assign) IBOutlet NSMenuItem *menuItemHistory;
@property (assign) IBOutlet NSMenuItem *menuItemOpenInXcode;
@property (assign) IBOutlet NSMenuItem *menuItemListen;

@property (strong) IBOutlet NSPanel    *aboutWindow;
@property (strong) IBOutlet NSWindow   *preferencesWindow;

@property (strong) IBOutlet NSWindow   *helpWindow;
@property (assign) IBOutlet NSTextView *helpTextView;

@property (strong) IBOutlet NSUserDefaultsController	*preferencesController;
@property (strong) IBOutlet TNXcodeCapp                	*xcc;

+ (AppController *)sharedAppController;

- (IBAction)listenToProject:(id)aSender;
- (IBAction)openHelp:(id)aSender;
- (IBAction)openAbout:(id)aSender;

@end

