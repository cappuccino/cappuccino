/*
* Copyright (c) 2014 Nuage Networks
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/


// Import this Categories from your application
// You can now user -(void)setCucappIdentifier: and -(CPString)cucappIdentifier
// to set and get your cucapp IDs.
// Then from a test, you can use it as a selector like //CPView[cucappIdentifier="my-button"]

@import <AppKit/CPResponder.j>
@import <AppKit/CPMenuItem.j>

@implementation CPResponder (cucappAdditions)

- (void)setCucappIdentifier:(CPString)anIdentifier
{
    self.__cucappIdentifier = anIdentifier;
}

- (CPString)cucappIdentifier
{
    return self.__cucappIdentifier;
}

@end

@implementation CPMenuItem (cucappAdditionsMenu)

- (void)setCucappIdentifier:(CPString)anIdentifier
{
    [[self _menuItemView] setCucappIdentifier:anIdentifier];
}

- (CPString)cucappIdentifier
{
    [[self _menuItemView] cucappIdentifier];
}

@end

function load_cucapp_CLI(path)
{
    if (!path)
        path = "Cucapp/lib/Cucumber.j"

    try {
        objj_importFile(path, true, function() {
            [Cucumber stopCucumber];
            CPLog.debug("Cucapp CLI has been well loaded");
            _addition_cpapplication_send_event_method();
        });

    }
    catch(e)
    {
        [CPException raise:CPInvalidArgumentException reason:@"Invalid path for the lib Cucumber"];
    }
}


function load_cucapp_record(path)
{
    if (!path)
        path = "CuCapp+Record.j"

    try {
        objj_importFile(path, true, function() {
            CPLog.debug("Cucapp record has been well loaded");
        });
    }
    catch(e)
    {
        [CPException raise:CPInvalidArgumentException reason:@"Invalid path for the lib Cucapp+Record.j"];
    }
}
