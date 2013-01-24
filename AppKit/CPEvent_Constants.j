/*
 * CPEvent_Constants.j
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

CPLeftMouseDown                         = 1;
CPLeftMouseUp                           = 2;
CPRightMouseDown                        = 3;
CPRightMouseUp                          = 4;
CPMouseMoved                            = 5;
CPLeftMouseDragged                      = 6;
CPRightMouseDragged                     = 7;
CPMouseEntered                          = 8;
CPMouseExited                           = 9;
CPKeyDown                               = 10;
CPKeyUp                                 = 11;
CPFlagsChanged                          = 12;
CPAppKitDefined                         = 13;
CPSystemDefined                         = 14;
CPApplicationDefined                    = 15;
CPPeriodic                              = 16;
CPCursorUpdate                          = 17;
CPScrollWheel                           = 22;
CPOtherMouseDown                        = 25;
CPOtherMouseUp                          = 26;
CPOtherMouseDragged                     = 27;

// iPhone Event Types
CPTouchStart                            = 28;
CPTouchMove                             = 29;
CPTouchEnd                              = 30;
CPTouchCancel                           = 31;

CPAlphaShiftKeyMask                     = 1 << 16;
CPShiftKeyMask                          = 1 << 17;
CPControlKeyMask                        = 1 << 18;
CPAlternateKeyMask                      = 1 << 19;
CPCommandKeyMask                        = 1 << 20;
CPNumericPadKeyMask                     = 1 << 21;
CPHelpKeyMask                           = 1 << 22;
CPFunctionKeyMask                       = 1 << 23;
CPDeviceIndependentModifierFlagsMask    = 0xffff0000;

CPLeftMouseDownMask                     = 1 << CPLeftMouseDown;
CPLeftMouseUpMask                       = 1 << CPLeftMouseUp;
CPRightMouseDownMask                    = 1 << CPRightMouseDown;
CPRightMouseUpMask                      = 1 << CPRightMouseUp;
CPOtherMouseDownMask                    = 1 << CPOtherMouseDown;
CPOtherMouseUpMask                      = 1 << CPOtherMouseUp;
CPMouseMovedMask                        = 1 << CPMouseMoved;
CPLeftMouseDraggedMask                  = 1 << CPLeftMouseDragged;
CPRightMouseDraggedMask                 = 1 << CPRightMouseDragged;
CPOtherMouseDragged                     = 1 << CPOtherMouseDragged;
CPMouseEnteredMask                      = 1 << CPMouseEntered;
CPMouseExitedMask                       = 1 << CPMouseExited;
CPCursorUpdateMask                      = 1 << CPCursorUpdate;
CPKeyDownMask                           = 1 << CPKeyDown;
CPKeyUpMask                             = 1 << CPKeyUp;
CPFlagsChangedMask                      = 1 << CPFlagsChanged;
CPAppKitDefinedMask                     = 1 << CPAppKitDefined;
CPSystemDefinedMask                     = 1 << CPSystemDefined;
CPApplicationDefinedMask                = 1 << CPApplicationDefined;
CPPeriodicMask                          = 1 << CPPeriodic;
CPScrollWheelMask                       = 1 << CPScrollWheel;
CPAnyEventMask                          = 0xffffffff;

CPUpArrowFunctionKey                    = "\uF700";
CPDownArrowFunctionKey                  = "\uF701";
CPLeftArrowFunctionKey                  = "\uF702";
CPRightArrowFunctionKey                 = "\uF703";
CPF1FunctionKey                         = "\uF704";
CPF2FunctionKey                         = "\uF705";
CPF3FunctionKey                         = "\uF706";
CPF4FunctionKey                         = "\uF707";
CPF5FunctionKey                         = "\uF708";
CPF6FunctionKey                         = "\uF709";
CPF7FunctionKey                         = "\uF70A";
CPF8FunctionKey                         = "\uF70B";
CPF9FunctionKey                         = "\uF70C";
CPF10FunctionKey                        = "\uF70D";
CPF11FunctionKey                        = "\uF70E";
CPF12FunctionKey                        = "\uF70F";
CPF13FunctionKey                        = "\uF710";
CPF14FunctionKey                        = "\uF711";
CPF15FunctionKey                        = "\uF712";
CPF16FunctionKey                        = "\uF713";
CPF17FunctionKey                        = "\uF714";
CPF18FunctionKey                        = "\uF715";
CPF19FunctionKey                        = "\uF716";
CPF20FunctionKey                        = "\uF717";
CPF21FunctionKey                        = "\uF718";
CPF22FunctionKey                        = "\uF719";
CPF23FunctionKey                        = "\uF71A";
CPF24FunctionKey                        = "\uF71B";
CPF25FunctionKey                        = "\uF71C";
CPF26FunctionKey                        = "\uF71D";
CPF27FunctionKey                        = "\uF71E";
CPF28FunctionKey                        = "\uF71F";
CPF29FunctionKey                        = "\uF720";
CPF30FunctionKey                        = "\uF721";
CPF31FunctionKey                        = "\uF722";
CPF32FunctionKey                        = "\uF723";
CPF33FunctionKey                        = "\uF724";
CPF34FunctionKey                        = "\uF725";
CPF35FunctionKey                        = "\uF726";
CPInsertFunctionKey                     = "\uF727";
CPDeleteFunctionKey                     = "\uF728";
CPHomeFunctionKey                       = "\uF729";
CPBeginFunctionKey                      = "\uF72A";
CPEndFunctionKey                        = "\uF72B";
CPPageUpFunctionKey                     = "\uF72C";
CPPageDownFunctionKey                   = "\uF72D";
CPPrintScreenFunctionKey                = "\uF72E";
CPScrollLockFunctionKey                 = "\uF72F";
CPPauseFunctionKey                      = "\uF730";
CPSysReqFunctionKey                     = "\uF731";
CPBreakFunctionKey                      = "\uF732";
CPResetFunctionKey                      = "\uF733";
CPStopFunctionKey                       = "\uF734";
CPMenuFunctionKey                       = "\uF735";
CPUserFunctionKey                       = "\uF736";
CPSystemFunctionKey                     = "\uF737";
CPPrintFunctionKey                      = "\uF738";
CPClearLineFunctionKey                  = "\uF739";
CPClearDisplayFunctionKey               = "\uF73A";
CPInsertLineFunctionKey                 = "\uF73B";
CPDeleteLineFunctionKey                 = "\uF73C";
CPInsertCharFunctionKey                 = "\uF73D";
CPDeleteCharFunctionKey                 = "\uF73E";
CPPrevFunctionKey                       = "\uF73F";
CPNextFunctionKey                       = "\uF740";
CPSelectFunctionKey                     = "\uF741";
CPExecuteFunctionKey                    = "\uF742";
CPUndoFunctionKey                       = "\uF743";
CPRedoFunctionKey                       = "\uF744";
CPFindFunctionKey                       = "\uF745";
CPHelpFunctionKey                       = "\uF746";
CPModeSwitchFunctionKey                 = "\uF747";
CPEscapeFunctionKey                     = "\u001B";
CPSpaceFunctionKey                      = "\u0020";


CPDOMEventDoubleClick                   = "dblclick";
CPDOMEventMouseDown                     = "mousedown";
CPDOMEventMouseUp                       = "mouseup";
CPDOMEventMouseMoved                    = "mousemove";
CPDOMEventMouseDragged                  = "mousedrag";
CPDOMEventKeyUp                         = "keyup";
CPDOMEventKeyDown                       = "keydown";
CPDOMEventKeyPress                      = "keypress";
CPDOMEventCopy                          = "copy";
CPDOMEventPaste                         = "paste";
CPDOMEventScrollWheel                   = "mousewheel";
CPDOMEventTouchStart                    = "touchstart";
CPDOMEventTouchMove                     = "touchmove";
CPDOMEventTouchEnd                      = "touchend";
CPDOMEventTouchCancel                   = "touchcancel";
