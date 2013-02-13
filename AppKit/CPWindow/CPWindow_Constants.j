/*
 * CPWindow_Constants.j
 * AppKit
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

/*
    Borderless window mask option.
    @global
    @class CPWindow
*/
CPBorderlessWindowMask          = 0;
/*
    Titled window mask option.
    @global
    @class CPWindow
*/
CPTitledWindowMask              = 1 << 0;
/*
    Closeable window mask option.
    @global
    @class CPWindow
*/
CPClosableWindowMask            = 1 << 1;
/*
    Miniaturizabe window mask option.
    @global
    @class CPWindow
*/
CPMiniaturizableWindowMask      = 1 << 2;
/*
    Resizable window mask option.
    @global
    @class CPWindow
*/
CPResizableWindowMask           = 1 << 3;
/*
    Textured window mask option.
    @global
    @class CPWindow
*/
CPTexturedBackgroundWindowMask  = 1 << 8;
/*
    @global
    @class CPWindow
*/
CPBorderlessBridgeWindowMask    = 1 << 20;
/*
    @global
    @class CPWindow
*/
CPHUDBackgroundWindowMask       = 1 << 21;

/*!
    @global
    @class CPWindow
*/
_CPModalWindowMask              = 1 << 22;

CPWindowNotSizable              = 0;
CPWindowMinXMargin              = 1;
CPWindowWidthSizable            = 2;
CPWindowMaxXMargin              = 4;
CPWindowMinYMargin              = 8;
CPWindowHeightSizable           = 16;
CPWindowMaxYMargin              = 32;

CPBackgroundWindowLevel         = -1;
/*
    Default level for windows
    @group CPWindowLevel
    @global
*/
CPNormalWindowLevel             = 0;
/*
    Floating palette type window
    @group CPWindowLevel
    @global
*/
CPFloatingWindowLevel           = 3;
/*
    Submenu type window
    @group CPWindowLevel
    @global
*/
CPSubmenuWindowLevel            = 3;
/*
    For a torn-off menu
    @group CPWindowLevel
    @global
*/
CPTornOffMenuWindowLevel        = 3;
/*
    For the application's main menu
    @group CPWindowLevel
    @global
*/
CPMainMenuWindowLevel           = 24;
/*
    Status window level
    @group CPWindowLevel
    @global
*/
CPStatusWindowLevel             = 25;
/*
    Level for a modal panel
    @group CPWindowLevel
    @global
*/
CPModalPanelWindowLevel         = 8;
/*
    Level for a pop up menu
    @group CPWindowLevel
    @global
*/
CPPopUpMenuWindowLevel          = 101;
/*
    Level for a window being dragged
    @group CPWindowLevel
    @global
*/
CPDraggingWindowLevel           = 500;
/*
    Level for the screens saver
    @group CPWindowLevel
    @global
*/
CPScreenSaverWindowLevel        = 1000;

/*
    The receiver is placed directly in front of the window specified.
    @global
    @class CPWindowOrderingMode
*/
CPWindowAbove                   = 1;
/*
    The receiver is placed directly behind the window specified.
    @global
    @class CPWindowOrderingMode
*/
CPWindowBelow                   = -1;
/*
    The receiver is removed from the screen list and hidden.
    @global
    @class CPWindowOrderingMode
*/
CPWindowOut                     = 0;

CPWindowWillCloseNotification                   = @"CPWindowWillCloseNotification";
CPWindowDidBecomeMainNotification               = @"CPWindowDidBecomeMainNotification";
CPWindowDidResignMainNotification               = @"CPWindowDidResignMainNotification";
CPWindowDidBecomeKeyNotification                = @"CPWindowDidBecomeKeyNotification";
CPWindowDidResignKeyNotification                = @"CPWindowDidResignKeyNotification";
CPWindowDidResizeNotification                   = @"CPWindowDidResizeNotification";
CPWindowDidMoveNotification                     = @"CPWindowDidMoveNotification";
CPWindowWillBeginSheetNotification              = @"CPWindowWillBeginSheetNotification";
CPWindowDidEndSheetNotification                 = @"CPWindowDidEndSheetNotification";
CPWindowDidMiniaturizeNotification              = @"CPWindowDidMiniaturizeNotification";
CPWindowWillMiniaturizeNotification             = @"CPWindowWillMiniaturizeNotification";
CPWindowDidDeminiaturizeNotification            = @"CPWindowDidDeminiaturizeNotification";

_CPWindowDidChangeFirstResponderNotification    = @"_CPWindowDidChangeFirstResponderNotification";

CPWindowShadowStyleStandard = 0;
CPWindowShadowStyleMenu     = 1;
CPWindowShadowStylePanel    = 2;

CPWindowResizeStyleModern = 0;
CPWindowResizeStyleLegacy = 1;
CPWindowResizeStyle = CPWindowResizeStyleModern;

CPWindowPositionFlexibleRight   = 1 << 19;
CPWindowPositionFlexibleLeft    = 1 << 20;
CPWindowPositionFlexibleBottom  = 1 << 21;
CPWindowPositionFlexibleTop     = 1 << 22;

CPStandardWindowShadowStyle = 0;
CPMenuWindowShadowStyle     = 1;
CPPanelWindowShadowStyle    = 2;
CPCustomWindowShadowStyle   = 3;
