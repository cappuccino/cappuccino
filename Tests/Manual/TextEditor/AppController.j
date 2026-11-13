/*
 * AppController.j
 * TextEditor
 *
 * Copyright (c) 2026 David Richardson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "SettingsWindowController.j"


@implementation AppController : CPObject
{
    SettingsWindowController    _settingsWindowController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    /*
        Apply the appearance chosen in the Settings window, kept from an earlier session.
        Every window, open or not yet open, takes it.
    */
    [SettingsWindowController applySavedAppearance];

    // This is called when the application is done loading.
    // Uncomment the following line to hide the standard menu bar.
    // [CPMenu setMenuBarVisible:NO];
}

/*
    The action of the Settings… menu item in MainMenu.xib, sent to the first responder. The
    application delegate is the last stop of the responder chain, so it receives it. The
    Settings window is made on first use and kept.
*/
- (void)showSettings:(id)aSender
{
    if (!_settingsWindowController)
        _settingsWindowController = [[SettingsWindowController alloc] init];

    [_settingsWindowController showWindow:self];
}

@end
