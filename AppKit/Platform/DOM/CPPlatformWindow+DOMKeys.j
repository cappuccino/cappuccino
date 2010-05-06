/*
 * CPPlatformWindow+DOMKeys.j
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
 
// Keycodes taken and modified from Google Closure, available under Apache 2 License

CPKeyCodes = {
  BACKSPACE: 8,
  TAB: 9,
  NUM_CENTER: 12,
  ENTER: 13,
  SHIFT: 16,
  CTRL: 17,
  ALT: 18,
  PAUSE: 19,
  CAPS_LOCK: 20,
  ESC: 27,
  SPACE: 32,
  PAGE_UP: 33,     // also NUM_NORTH_EAST
  PAGE_DOWN: 34,   // also NUM_SOUTH_EAST
  END: 35,         // also NUM_SOUTH_WEST
  HOME: 36,        // also NUM_NORTH_WEST
  LEFT: 37,        // also NUM_WEST
  UP: 38,          // also NUM_NORTH
  RIGHT: 39,       // also NUM_EAST
  DOWN: 40,        // also NUM_SOUTH
  PRINT_SCREEN: 44,
  INSERT: 45,      // also NUM_INSERT
  DELETE: 46,      // also NUM_DELETE
  ZERO: 48,
  ONE: 49,
  TWO: 50,
  THREE: 51,
  FOUR: 52,
  FIVE: 53,
  SIX: 54,
  SEVEN: 55,
  EIGHT: 56,
  NINE: 57,
  QUESTION_MARK: 63, // needs localization
  A: 65,
  B: 66,
  C: 67,
  D: 68,
  E: 69,
  F: 70,
  G: 71,
  H: 72,
  I: 73,
  J: 74,
  K: 75,
  L: 76,
  M: 77,
  N: 78,
  O: 79,
  P: 80,
  Q: 81,
  R: 82,
  S: 83,
  T: 84,
  U: 85,
  V: 86,
  W: 87,
  X: 88,
  Y: 89,
  Z: 90,
  META: 91,
  CONTEXT_MENU: 93,
  NUM_ZERO: 96,
  NUM_ONE: 97,
  NUM_TWO: 98,
  NUM_THREE: 99,
  NUM_FOUR: 100,
  NUM_FIVE: 101,
  NUM_SIX: 102,
  NUM_SEVEN: 103,
  NUM_EIGHT: 104,
  NUM_NINE: 105,
  NUM_MULTIPLY: 106,
  NUM_PLUS: 107,
  NUM_MINUS: 109,
  NUM_PERIOD: 110,
  NUM_DIVISION: 111,
  F1: 112,
  F2: 113,
  F3: 114,
  F4: 115,
  F5: 116,
  F6: 117,
  F7: 118,
  F8: 119,
  F9: 120,
  F10: 121,
  F11: 122,
  F12: 123,
  NUMLOCK: 144,
  SEMICOLON: 186,            // needs localization
  DASH: 189,                 // needs localization
  EQUALS: 187,               // needs localization
  COMMA: 188,                // needs localization
  PERIOD: 190,               // needs localization
  SLASH: 191,                // needs localization
  APOSTROPHE: 192,           // needs localization
  SINGLE_QUOTE: 222,         // needs localization
  OPEN_SQUARE_BRACKET: 219,  // needs localization
  BACKSLASH: 220,            // needs localization
  CLOSE_SQUARE_BRACKET: 221, // needs localization
  WIN_KEY: 224,
  MAC_FF_META: 224,          // Firefox (Gecko) fires this for the meta key instead of 91
  WIN_IME: 229
};


/*!
 * Returns true if the key fires a keypress event in the current browser.
 *
 * Accoridng to MSDN [1] IE only fires keypress events for the following keys:
 * - Letters: A - Z (uppercase and lowercase)
 * - Numerals: 0 - 9
 * - Symbols: ! @ # $ % ^ & * ( ) _ - + = < [ ] { } , . / ? \ | ' ` " ~
 * - System: ESC, SPACEBAR, ENTER
 *
 * That's not entirely correct though, for instance there's no distinction
 * between upper and lower case letters.
 *
 * [1] http://msdn2.microsoft.com/en-us/library/ms536939(VS.85).aspx)
 *
 * Safari is similar to IE, but does not fire keypress for ESC.
 *
 * Additionally, IE6 does not fire keydown or keypress events for letters when
 * the control or alt keys are held down and the shift key is not. IE7 does
 * fire keydown in these cases, though, but not keypress.
 *
 * @param keyCode A key code.
 * @param opt_heldKeyCode Key code of a currently-held key.
 * @param opt_shiftKey Whether the shift key is held down.
 * @param opt_ctrlKey Whether the control key is held down.
 * @param opt_altKey Whether the alt key is held down.
 * @return Returns YES if it's a key that fires a keypress event.
 */
CPKeyCodes.firesKeyPressEvent = function(keyCode, opt_heldKeyCode, opt_shiftKey, opt_ctrlKey, opt_altKey) 
{
    if (!CPFeatureIsCompatible(CPJavascriptRemedialKeySupport))
        return true;

    if (CPBrowserIsOperatingSystem(CPMacOperatingSystem) && opt_altKey) 
        return CPKeyCodes.isCharacterKey(keyCode);

    // Alt but not AltGr which is represented as Alt+Ctrl.
    if (opt_altKey && !opt_ctrlKey)
        return false;

    // Saves Ctrl or Alt + key for IE7, which won't fire keypress.
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine) && !opt_shiftKey && (opt_ctrlKey || opt_altKey))
        return false;

    // When Ctrl+<somekey> is held in IE, it only fires a keypress once, but it
    // continues to fire keydown events as the event repeats.
    if (CPBrowserIsEngine(CPInternetExplorerBrowserEngine) && opt_ctrlKey && opt_heldKeyCode == keyCode)
        return false;

    switch (keyCode)
    {
        case CPKeyCodes.ENTER: return true;
        case CPKeyCodes.ESC:   return !CPBrowserIsEngine(CPWebKitBrowserEngine);
    }

    return CPKeyCodes.isCharacterKey(keyCode);
};


/*!
 * Test for whether or not a given keyCode represents a character key.
 *
 * @param keyCode A key code.
 * @return Returns YES if the keyCode is a character key.
 */
CPKeyCodes.isCharacterKey = function(keyCode) 
{
    if (keyCode >= CPKeyCodes.ZERO && keyCode <= CPKeyCodes.NINE)
        return true;

    if (keyCode >= CPKeyCodes.NUM_ZERO && keyCode <= CPKeyCodes.NUM_MULTIPLY)
        return true;

    if (keyCode >= CPKeyCodes.A && keyCode <= CPKeyCodes.Z)
        return true;

    switch (keyCode) 
    {
        case CPKeyCodes.SPACE:
        case CPKeyCodes.QUESTION_MARK:
        case CPKeyCodes.NUM_PLUS:
        case CPKeyCodes.NUM_MINUS:
        case CPKeyCodes.NUM_PERIOD:
        case CPKeyCodes.NUM_DIVISION:
        case CPKeyCodes.SEMICOLON:
        case CPKeyCodes.DASH:
        case CPKeyCodes.EQUALS:
        case CPKeyCodes.COMMA:
        case CPKeyCodes.PERIOD:
        case CPKeyCodes.SLASH:
        case CPKeyCodes.APOSTROPHE:
        case CPKeyCodes.SINGLE_QUOTE:
        case CPKeyCodes.OPEN_SQUARE_BRACKET:
        case CPKeyCodes.BACKSLASH:
        case CPKeyCodes.CLOSE_SQUARE_BRACKET:
            return true;

        default:
            return false;
    }
}
