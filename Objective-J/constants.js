/*
 * constants.js
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

    // Objective-J Constants
var NO      = false,
    YES     = true,
    
    nil     = null,
    Nil     = null,
    NULL    = null,
    
    // In IE, it is much faster to call these global methods than their Math. equivalents.
    // We var them in order to make them DontDelete globals, which are known to be much faster in Safari.
    ABS     = Math.abs,
    
    ASIN    = Math.asin,
    ACOS    = Math.acos,
    ATAN    = Math.atan,
    ATAN2   = Math.atan2,
    
    SIN     = Math.sin,
    COS     = Math.cos,
    TAN     = Math.tan,
    
    EXP     = Math.exp,
    POW     = Math.pow,
    
    CEIL    = Math.ceil,
    FLOOR   = Math.floor,
    ROUND   = Math.round,
    
    MIN     = Math.min,
    MAX     = Math.max,
    
    RAND    = Math.random,
    SQRT    = Math.sqrt,
    
    E       = Math.E,
    
    LN2     = Math.LN2,
    LN10    = Math.LN10,
    LOG2E   = Math.LOG2E,
    LOG10E  = Math.LOG10E,
    
    PI      = Math.PI,
    PI2     = Math.PI * 2.0,
    PI_2    = Math.PI / 2.0,
    
    SQRT1_2 = Math.SQRT1_2,
    SQRT2   = Math.SQRT2;

window.setNativeTimeout = window.setTimeout;
window.clearNativeTimeout = window.clearTimeout;
window.setNativeInterval = window.setInterval;
window.clearNativeInterval = window.clearInterval;

// Detecting Browser Features
#define ACTIVE_X                window.ActiveXObject
#define OPERA                   window.opera
#define NATIVE_XMLHTTPREQUEST   window.XMLHttpRequest

#define IF(FEATURE) if (FEATURE) {
#define ELSE } else { 
#define ELIF(FEATURE) } else if (FEATURE) {
#define ENDIF }

//
// FIXME: Should we just override normal alerts?
var objj_continue_alerting = NO;

function objj_alert(aString)
{
    if (!objj_continue_alerting)
        return;
    
    objj_continue_alerting = confirm(aString + "\n\nClick cancel to prevent further alerts.");
}

function objj_fprintf(stream, string)
{
    stream(string);
}

function objj_printf(string)
{
    objj_fprintf(alert, string);
}

#if RHINO
importPackage(java.lang);

warning_stream = function (aString) { System.out.println(aString) };

#else
if (window.console && window.console.warn)
    warning_stream = function(aString) { window.console.warn(aString); }
else
    warning_stream = function(){};
#endif
