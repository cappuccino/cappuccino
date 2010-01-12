/*
 * bootstrap.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

if (window.OBJJ_MAIN_FILE)
{
    var addOnload = function(handler)
    {
        if (window.addEventListener)
            window.addEventListener("load", handler, false);
        else if (window.attachEvent)
            window.attachEvent("onload", handler);
    }

    var documentLoaded = NO;
    var defaultHandler = function()
    {
        documentLoaded = YES;
    }

    addOnload(defaultHandler);

    objj_import(OBJJ_MAIN_FILE, YES, function()
    {
        if (documentLoaded)
            main();
        else
            addOnload(main);
    });
}
