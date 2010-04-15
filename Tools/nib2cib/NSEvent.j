/*
 * NSEvent.j
 * nib2cib
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

NSAlphaShiftKeyMask                     = 1 << 16;
NSShiftKeyMask                          = 1 << 17;
NSControlKeyMask                        = 1 << 18;
NSAlternateKeyMask                      = 1 << 19;
NSCommandKeyMask                        = 1 << 20;
NSNumericPadKeyMask                     = 1 << 21;
NSHelpKeyMask                           = 1 << 22;
NSFunctionKeyMask                       = 1 << 23;
NSDeviceIndependentModifierFlagsMask    = 0xffff0000;

function CP_NSMapKeyMask(anNSKeyMask)
{
    var keyMask = 0;

    if (anNSKeyMask & NSAlphaShiftKeyMask)
        keyMask |= CPAlphaShiftKeyMask;

    if (anNSKeyMask & NSShiftKeyMask)
        keyMask |= CPShiftKeyMask;

    if (anNSKeyMask & NSControlKeyMask)
        keyMask |= CPControlKeyMask;

    if (anNSKeyMask & NSAlternateKeyMask)
        keyMask |= CPAlternateKeyMask;

    if (anNSKeyMask & NSCommandKeyMask)
        keyMask |= CPCommandKeyMask;

    if (anNSKeyMask & NSNumericPadKeyMask)
        keyMask |= CPNumericPadKeyMask;

    if (anNSKeyMask & NSHelpKeyMask)
        keyMask |= CPHelpKeyMask;

    if (anNSKeyMask & NSFunctionKeyMask)
        keyMask |= CPFunctionKeyMask;

    return keyMask;
}
