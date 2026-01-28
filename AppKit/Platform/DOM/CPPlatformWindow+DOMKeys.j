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
  WEBKIT_RIGHT_META: 93,    // WebKit (on Mac at least) fires this for the right Command key
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
 * The keypress event is deprecated, but this function helps manage legacy
 * event handling by predicting its behavior.
 *
 * @param {number} keyCode A key code.
 * @param {string} key The `key` property from the keyboard event.
 * @param {number} opt_heldKeyCode Key code of a currently-held key.
 * @param {boolean} opt_shiftKey Whether the shift key is held down.
 * @param {boolean} opt_ctrlKey Whether the control key is held down.
 * @param {boolean} opt_altKey Whether the alt key is held down.
 * @return {boolean} Returns YES if it's a key that fires a keypress event.
 */
CPKeyCodes.firesKeyPressEvent = function(keyCode, key, opt_heldKeyCode, opt_shiftKey, opt_ctrlKey, opt_altKey)
{
    // Modern approach: Use event.key if available, as it is the most reliable standard.
    if (key)
    {
        // Any key that produces a single, printable character fires a keypress event.
        if (key.length === 1)
            return true;

        // "Enter" is a special non-printable key that historically fires keypress for compatibility.
        if (key === "Enter")
            return true;

        // For all other non-printable keys (e.g., "ArrowLeft", "Escape", "F1"),
        // modern browsers do not fire a keypress event.
        return false;
    }

    // --- Legacy Fallback Logic (for browsers that don't support event.key) ---

    if (!CPFeatureIsCompatible(CPJavaScriptRemedialKeySupport))
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
        case CPKeyCodes.ESC:   return false;
    }

    return CPKeyCodes.isCharacterKey(keyCode);
};


/*!
 * Test for whether or not a given keyCode represents a character key.
 * NOTE: This is a legacy function for browsers that don't support `event.key`.
 * It is unreliable because `keyCode` represents a physical key, not the character produced.
 *
 * @param {number} keyCode A key code.
 * @return {boolean} Returns YES if the keyCode is a character key.
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
};
