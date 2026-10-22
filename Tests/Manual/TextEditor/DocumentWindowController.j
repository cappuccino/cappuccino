/*
 * DocumentWindowController.j
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


/*!
    Owns DocumentWindow.cib. The window's delegate outlet is connected to
    File's Owner in DocumentWindow.xib, so this controller is the window's
    delegate. windowDidLoad assigns it again, so the delegate is set even if
    the connection is missing from the xib.
*/
@implementation DocumentWindowController : CPWindowController <CPWindowDelegate>

- (id)init
{
    return [self initWithWindowCibName:@"DocumentWindow"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [[self window] setDelegate:self];
}

@end
