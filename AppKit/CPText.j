/*
 * CPText.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
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

CPEnterCharacter                = "\u0003";
CPBackspaceCharacter            = "\u0008";
CPTabCharacter                  = "\u0009";
CPNewlineCharacter              = "\u000a";
CPFormFeedCharacter             = "\u000c";
CPCarriageReturnCharacter       = "\u000d";
CPBackTabCharacter              = "\u0019";
CPDeleteCharacter               = "\u007f";

CPIllegalTextMovement           = 0;
CPOtherTextMovement             = 0;
CPReturnTextMovement            = 16;
CPTabTextMovement               = 17;
CPBacktabTextMovement           = 18;
CPLeftTextMovement              = 19;
CPRightTextMovement             = 20;
CPUpTextMovement                = 21;
CPDownTextMovement              = 22;
CPCancelTextMovement            = 23;