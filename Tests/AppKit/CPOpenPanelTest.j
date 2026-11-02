/*
 *  CPOpenPanelTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPItemProvider.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPOpenPanel.j>
@import <AppKit/CPPlatformFilePanel.j>

@implementation CPOpenPanelTestDelegate : CPObject
{
    CPArray     validatedURLs;
}

- (id)init
{
    if (self = [super init])
        validatedURLs = [];

    return self;
}

- (CPArray)validatedURLs
{
    return validatedURLs;
}

- (BOOL)panel:(id)sender validateURL:(CPURL)aURL error:(CPError)outError
{
    validatedURLs.push([aURL relativeString]);
    return YES;
}

@end

@implementation CPOpenPanelTest : OJTestCase
{
}

- (void)setUp
{
    [[CPApplication alloc] init];
}

- (CPItemProvider)providerNamed:(CPString)aName type:(CPString)aType
{
    return [CPItemProvider _itemProviderWithFile:{ name: aName, type: aType }];
}

- (void)testDefaults
{
    var panel = [CPOpenPanel openPanel];

    [self assertTrue:[panel canChooseFiles]];
    [self assertFalse:[panel canChooseDirectories]];
    [self assertFalse:[panel allowsMultipleSelection]];
    [self assertFalse:[panel isAccessoryViewDisclosed]];
    [self assert:[] equals:[panel URLs]];
    [self assert:[] equals:[panel itemProviders]];
    [self assertNull:[panel URL]];
}

- (void)testRunModalRaises
{
    var panel = [CPOpenPanel openPanel];

    [self assertThrows:function()
    {
        [panel runModal];
    }];
}

- (void)testFileTypeMatching
{
    [self assertTrue:[CPOpenPanel _fileName:@"a.PNG" typeIdentifiers:[@"image/png"] matchesFileTypes:[@"png"]]];
    [self assertTrue:[CPOpenPanel _fileName:@"a.csv" typeIdentifiers:[@""] matchesFileTypes:[@".csv"]]];
    [self assertTrue:[CPOpenPanel _fileName:@"a" typeIdentifiers:[@"image/png"] matchesFileTypes:[@"image/*"]]];
    [self assertTrue:[CPOpenPanel _fileName:@"a" typeIdentifiers:[@"text/csv"] matchesFileTypes:[@"text/csv"]]];
    [self assertTrue:[CPOpenPanel _fileName:@"a.txt" typeIdentifiers:[@"text/plain"] matchesFileTypes:nil]];
    [self assertFalse:[CPOpenPanel _fileName:@"a.txt" typeIdentifiers:[@"text/plain"] matchesFileTypes:[@"csv", @"image/*"]]];
    [self assertFalse:[CPOpenPanel _fileName:@"csv" typeIdentifiers:[@""] matchesFileTypes:[@"csv"]]];
}

- (void)testURLForSuggestedName
{
    [self assert:@"my%20file.png" equals:[[CPOpenPanel _URLForSuggestedName:@"my file.png"] relativeString]];
    [self assert:@"folder/a%20b.csv" equals:[[CPOpenPanel _URLForSuggestedName:@"folder/a b.csv"] relativeString]];
}

- (void)testAcceptString
{
    [self assert:@"image/*,.png,.csv" equals:[CPPlatformFilePanel _acceptStringForFileTypes:[@"image/*", @"png", @".csv"]]];
    [self assert:@"" equals:[CPPlatformFilePanel _acceptStringForFileTypes:nil]];
}

/*
    The command-line runtime has no DOM, so the browser's file dialog cannot open. A panel with
    no visible window then ends at once, as cancelled.
*/
- (void)testBeginWithoutDOMCancels
{
    var panel = [CPOpenPanel openPanel],
        response = nil;

    [panel beginWithCompletionHandler:function(aResponse)
    {
        response = aResponse;
    }];

    [self assert:CPCancelButton equals:response];
    [self assert:[] equals:[panel itemProviders]];
}

- (void)testChosenFilesAreAccepted
{
    var panel = [CPOpenPanel openPanel],
        delegate = [[CPOpenPanelTestDelegate alloc] init],
        providers = [[self providerNamed:@"b.png" type:@"image/png"], [self providerNamed:@"a b.png" type:@"image/png"]],
        response = nil;

    [panel setAllowedFileTypes:[@"image/*"]];
    [panel setDelegate:delegate];
    panel._completionHandler = function(aResponse)
    {
        response = aResponse;
    };

    [panel _fileDialogDidEndWithItemProviders:providers];

    [self assert:CPOKButton equals:response];
    [self assert:providers equals:[panel itemProviders]];
    [self assert:[@"b.png", @"a%20b.png"] equals:[delegate validatedURLs]];
    [self assert:@"b.png" equals:[[panel URL] relativeString]];
}

- (void)testCancelledDialogWithoutWindowEnds
{
    var panel = [CPOpenPanel openPanel],
        response = nil;

    panel._completionHandler = function(aResponse)
    {
        response = aResponse;
    };

    [panel _fileDialogDidEndWithItemProviders:nil];

    [self assert:CPCancelButton equals:response];
}

@end
