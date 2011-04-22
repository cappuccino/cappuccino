/*
 * CPSavePanel.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPPanel.j"


@implementation CPSavePanel : CPPanel
{
    CPURL   _URL;

    BOOL    _isExtensionHidden @accessors(getter=isExtensionHidden, setter=setExtensionHidden:);
    BOOL    _canSelectHiddenExtension @accessors(property=canSelectHiddenExtension);
    BOOL    _allowsOtherFileTypes @accessors(property=allowsOtherFileTypes);
    BOOL    _canCreateDirectories @accessors(property=canCreateDirectories);

    CPArray _allowedFileTypes @accessors(property=allowedFileTypes);
}

+ (id)savePanel
{
    return [[CPSavePanel alloc] init];
}

- (id)init
{
    if (self = [super init])
    {
        _canCreateDirectories = YES;
    }

    return self;
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    if (typeof window["cpSavePanel"] === "function")
    {
        var resultObject = window.cpSavePanel({
                isExtensionHidden: _isExtensionHidden,
                canSelectHiddenExtension: _canSelectHiddenExtension,
                allowsOtherFileTypes: _allowsOtherFileTypes,
                canCreateDirectories: _canCreateDirectories,
                allowedFileTypes: _allowedFileTypes
            }),
            result = resultObject.button;

        _URL = result ? [CPURL URLWithString:resultObject.URL] : nil;
    }
    else
    {
        // FIXME: This is not the best way to do this.
        var documentName = window.prompt("Document Name:"),
            result = documentName !== null;

        _URL = result ? [[self class] proposedFileURLWithDocumentName:documentName] : nil;
    }

    return result;
}

- (CPURL)URL
{
    return _URL;
}

@end
