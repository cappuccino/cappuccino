/*
 * CPOpenPanel.j
 * AppKit
 *
 * Created by Ross Boucher.
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


@implementation CPOpenPanel : CPPanel
{
    BOOL    _canChooseFiles             @accessors(property=canChooseFiles);
    BOOL    _canChooseDirectories       @accessors(property=canChooseDirectories);
    BOOL    _allowsMultipleSelection    @accessors(property=allowsMultipleSelection);
    CPURL   _directoryURL               @accessors(property=directoryURL);
    CPArray _URLs;
}

+ (id)openPanel
{
    return [[CPOpenPanel alloc] init];
}

- (CPInteger)runModal
{
    if (typeof window["cpOpenPanel"] === "function")
    {
        // FIXME: Is this correct???
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

        var options = { directoryURL: [self directoryURL],
                        canChooseFiles: [self canChooseFiles],
                        canChooseDirectories: [self canChooseDirectories],
                        allowsMultipleSelection: [self allowsMultipleSelection] },

            result = window.cpOpenPanel(options);

        _URLs = result.URLs;

        return result.button;
    }

    throw "-runModal is unimplemented.";
}

- (CPArray)URLs
{
    return _URLs;
}

@end
