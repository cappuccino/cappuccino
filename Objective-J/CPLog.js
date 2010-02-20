/*
 * CPLog.js
 * Objective-J
 *
 * Created by Thomas Robinson.
 * Copyright 2008-2010, 280 North, Inc.
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

GLOBAL(CPLogDisable) = false;

var CPLogDefaultTitle = "Cappuccino";

var CPLogLevels = ["fatal", "error", "warn", "info", "debug", "trace"];
var CPLogDefaultLevel = CPLogLevels[3];

var _CPLogLevelsInverted = {};
for (var i = 0; i < CPLogLevels.length; i++)
    _CPLogLevelsInverted[CPLogLevels[i]] = i;

var _CPLogRegistrations = {};

// Register Functions:

// Register a logger for all levels, or up to an optional max level
GLOBAL(CPLogRegister) = function(aProvider, aMaxLevel)
{
    CPLogRegisterRange(aProvider, CPLogLevels[0], aMaxLevel || CPLogLevels[CPLogLevels.length-1]);
}

// Register a logger for a range of levels
GLOBAL(CPLogRegisterRange) = function(aProvider, aMinLevel, aMaxLevel)
{
    var min = _CPLogLevelsInverted[aMinLevel];
    var max = _CPLogLevelsInverted[aMaxLevel];

    if (min !== undefined && max !== undefined)
        for (var i = 0; i <= max; i++)
            CPLogRegisterSingle(aProvider, CPLogLevels[i]);
}

// Register a logger for a single level
GLOBAL(CPLogRegisterSingle) = function(aProvider, aLevel)
{
    if (!_CPLogRegistrations[aLevel])
        _CPLogRegistrations[aLevel] = [];

    // prevent duplicate registrations
    for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
        if (_CPLogRegistrations[aLevel][i] === aProvider)
            return;

    _CPLogRegistrations[aLevel].push(aProvider);
}

GLOBAL(CPLogUnregister) = function(aProvider) {
    for (var aLevel in _CPLogRegistrations)
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
            if (_CPLogRegistrations[aLevel][i] === aProvider)
                _CPLogRegistrations[aLevel].splice(i--, 1); // decrement since we're removing an element
}

// Main CPLog, which dispatches to individual loggers
function _CPLogDispatch(parameters, aLevel, aTitle)
{
    if (aTitle == undefined)
        aTitle = CPLogDefaultTitle;
    if (aLevel == undefined)
        aLevel = CPLogDefaultLevel;
    
    // use sprintf if param 0 is a string and there is more than one param. otherwise just convert param 0 to a string
    var message = (typeof parameters[0] == "string" && parameters.length > 1) ? sprintf.apply(null, parameters) : String(parameters[0]);
        
    if (_CPLogRegistrations[aLevel])
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
             _CPLogRegistrations[aLevel][i](message, aLevel, aTitle);
}

// Setup CPLog() and CPLog.xxx() aliases

GLOBAL(CPLog) = function() { _CPLogDispatch(arguments); }

for (var i = 0; i < CPLogLevels.length; i++)
    CPLog[CPLogLevels[i]] = (function(level) { return function() { _CPLogDispatch(arguments, level); }; })(CPLogLevels[i]);

// Helpers functions:

var _CPFormatLogMessage = function(aString, aLevel, aTitle)
{
    var now = new Date();
    aLevel = ( aLevel == null ? '' : ' [' + aLevel + ']' );

    if (typeof sprintf == "function")
        return sprintf("%4d-%02d-%02d %02d:%02d:%02d.%03d %s%s: %s",
            now.getFullYear(), now.getMonth(), now.getDate(),
            now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds(),
            aTitle, aLevel, aString);
    else
        return now + " " + aTitle + aLevel + ": " + aString;
}

// Loggers:

var ANSI_ESC            = String.fromCharCode(0x1B);
var ANSI_CSI            = ANSI_ESC + '[';
var ANSI_TEXT_PROP      = 'm';
var ANSI_RESET          = '0';
var ANSI_BOLD           = '1';
var ANSI_FAINT          = '2'; // unsupported?
var ANSI_NORMAL         = '22';
var ANSI_ITALIC         = '3'; // unsupported?
var ANSI_UNDER          = '4';
var ANSI_UNDER_DBL      = '21'; // unsupported?
var ANSI_UNDER_OFF      = '24';
var ANSI_BLINK          = '5';
var ANSI_BLINK_FAST     = '6'; // unsupported?
var ANSI_BLINK_OFF      = '25';
var ANSI_REVERSE        = '7';
var ANSI_POSITIVE       = '27';
var ANSI_CONCEAL        = '8';
var ANSI_REVEAL         = '28';
var ANSI_FG             = '3';
var ANSI_BG             = '4';
var ANSI_FG_INTENSE     = '9';
var ANSI_BG_INTENSE     = '10';
var ANSI_BLACK          = '0';
var ANSI_RED            = '1';
var ANSI_GREEN          = '2';
var ANSI_YELLOW         = '3';
var ANSI_BLUE           = '4';
var ANSI_MAGENTA        = '5';
var ANSI_CYAN           = '6';
var ANSI_WHITE          = '7';

var colorCodeMap = {
    "black"   : ANSI_BLACK,
    "red"     : ANSI_RED,
    "green"   : ANSI_GREEN,
    "yellow"  : ANSI_YELLOW,
    "blue"    : ANSI_BLUE,
    "magenta" : ANSI_MAGENTA,
    "cyan"    : ANSI_CYAN,
    "white"   : ANSI_WHITE
}

function ANSIControlCode(code, parameters)
{
    if (parameters == undefined)
        parameters = "";
    else if (typeof(parameters) == 'object' && (parameters instanceof Array))
        parameters = parameters.join(';');
    return ANSI_CSI + String(parameters) + String(code);
}

// simple text helpers:

function ANSITextApplyProperties(string, properties)
{
    return ANSIControlCode(ANSI_TEXT_PROP, properties) + String(string) + ANSIControlCode(ANSI_TEXT_PROP);
}

GLOBAL(ANSITextColorize) = function(string, color)
{
    if (colorCodeMap[color] == undefined)
        return string;
    return ANSITextApplyProperties(string, ANSI_FG + colorCodeMap[color]);
}

// CPLogPrint uses the print() functions present in many non-browser command line JavaScript interpreters
var levelColorMap = {
    "fatal": "red",
    "error": "red",
    "warn" : "yellow",
    "info" : "green",
    "debug": "cyan",
    "trace": "blue"
}

// CPLogConsole uses the built in "console" object
GLOBAL(CPLogConsole) = function(aString, aLevel, aTitle)
{
    if (typeof console != "undefined")
    {
        var message = _CPFormatLogMessage(aString, aLevel, aTitle);
        
        var logger = {
            "fatal": "error",
            "error": "error",
            "warn": "warn",
            "info": "info",
            "debug": "debug",
            "trace": "debug"
        }[aLevel];
        
        if (logger && console[logger])
            console[logger](message);
        else if (console.log)
            console.log(message);
    }
}

#if COMMONJS
GLOBAL(CPLogPrint) = function(aString, aLevel, aTitle)
{
    if (typeof print != "undefined")
    {
        if (aLevel == "fatal" || aLevel == "error" || aLevel == "warn")
            var message = ANSITextColorize(_CPFormatLogMessage(aString, aLevel, aTitle), levelColorMap[aLevel]);
        else
            var message = _CPFormatLogMessage(aString, ANSITextColorize(aLevel, levelColorMap[aLevel]), aTitle);

        require("system").stderr.print(message);
    }
}
#else

// CPLogAlert uses basic browser alert() functions
GLOBAL(CPLogAlert) = function(aString, aLevel, aTitle)
{
    if (typeof alert != "undefined" && !CPLogDisable)
    {
        var message = _CPFormatLogMessage(aString, aLevel, aTitle);
        CPLogDisable = !confirm(message + "\n\n(Click cancel to stop log alerts)");
    }
}

// CPLogPopup uses a slick popup window in the browser:
var CPLogWindow = null;
GLOBAL(CPLogPopup) = function(aString, aLevel, aTitle)
{
    try {
        if (CPLogDisable || window.open == undefined)
            return;
    
        if (!CPLogWindow || !CPLogWindow.document)
        {
            CPLogWindow = window.open("", "_blank", "width=600,height=400,status=no,resizable=yes,scrollbars=yes");
        
            if (!CPLogWindow) {
                CPLogDisable = !confirm(aString + "\n\n(Disable pop-up blocking for CPLog window; Click cancel to stop log alerts)");
                return;
            }
        
            _CPLogInitPopup(CPLogWindow);
        }
        
        var logDiv = CPLogWindow.document.createElement("div");
        logDiv.setAttribute("class", aLevel || "fatal");

        var message = _CPFormatLogMessage(aString, null, aTitle);
        
        logDiv.appendChild(CPLogWindow.document.createTextNode(message));
        CPLogWindow.log.appendChild(logDiv);
    
        if (CPLogWindow.focusEnabled.checked)
            CPLogWindow.focus();
        if (CPLogWindow.blockEnabled.checked)
            CPLogWindow.blockEnabled.checked = CPLogWindow.confirm(message+"\nContinue blocking?");
        if (CPLogWindow.scrollEnabled.checked)
            CPLogWindow.scrollToBottom();
    } catch(e) {
        // TODO: some error handling/reporting
    }
}

function _CPLogInitPopup(logWindow)
{
    var doc = logWindow.document;
    
    // HACK so that head is available below:
    doc.writeln("<html><head><title></title></head><body></body></html>");
    
    doc.title = CPLogDefaultTitle + " Run Log";
    
    var head = doc.getElementsByTagName("head")[0];
    var body = doc.getElementsByTagName("body")[0];
    
    var base = window.location.protocol + "//" + window.location.host + window.location.pathname;
    base = base.substring(0,base.lastIndexOf("/")+1);
    
    var link = doc.createElement("link");
    link.setAttribute("type", "text/css");
    link.setAttribute("rel", "stylesheet");
    link.setAttribute("href", base+"Frameworks/Foundation/Resources/log.css");
    link.setAttribute("media", "screen");
    head.appendChild(link);
    
    var div = doc.createElement("div");
    div.setAttribute("id", "header");
    body.appendChild(div);
    
    // Enablers
    var ul = doc.createElement("ul");
    ul.setAttribute("id", "enablers");
    div.appendChild(ul);
    
    for (var i = 0; i < CPLogLevels.length; i++) {
        var li = doc.createElement("li");
        li.setAttribute("id", "en"+CPLogLevels[i]);
        li.setAttribute("class", CPLogLevels[i]);
        li.setAttribute("onclick", "toggle(this);");
        li.setAttribute("enabled", "yes");
        li.appendChild(doc.createTextNode(CPLogLevels[i]));
        ul.appendChild(li);
    }
    
    // Options
    var ul = doc.createElement("ul");
    ul.setAttribute("id", "options");
    div.appendChild(ul);
    
    var options = {"focus":["Focus",false], "block":["Block",false], "wrap":["Wrap",false], "scroll":["Scroll",true], "close":["Close",true]};
    for (o in options) {
        var li = doc.createElement("li");
        ul.appendChild(li);
        
        logWindow[o+"Enabled"] = doc.createElement("input");
        logWindow[o+"Enabled"].setAttribute("id", o);
        logWindow[o+"Enabled"].setAttribute("type", "checkbox");
        if (options[o][1]) 
            logWindow[o+"Enabled"].setAttribute("checked", "checked");
        li.appendChild(logWindow[o+"Enabled"]);
        
        var label = doc.createElement("label");
        label.setAttribute("for", o);
        label.appendChild(doc.createTextNode(options[o][0]));
        li.appendChild(label);
    }
    
    // Log
    logWindow.log = doc.createElement("div");
    logWindow.log.setAttribute("class", "enerror endebug enwarn eninfo enfatal entrace");
    body.appendChild(logWindow.log);
    
    logWindow.toggle = function(elem) {
        var enabled = (elem.getAttribute("enabled") == "yes") ? "no" : "yes";
        elem.setAttribute("enabled", enabled);

        if (enabled == "yes")
            logWindow.log.className += " " + elem.id
        else
            logWindow.log.className = logWindow.log.className.replace(new RegExp("[\\s]*"+elem.id, "g"), "");
    }
    
    // Scroll
    logWindow.scrollToBottom = function() {
        logWindow.scrollTo(0, body.offsetHeight);
    }
    
    // Wrap
    logWindow.wrapEnabled.addEventListener("click", function() {
        logWindow.log.setAttribute("wrap", logWindow.wrapEnabled.checked ? "yes" : "no");
    }, false);
    
    // Clear
    logWindow.addEventListener("keydown", function(e) {
        var e = e || logWindow.event;
        if (e.keyCode == 75 && (e.ctrlKey || e.metaKey)) {
            while (logWindow.log.firstChild) {
                logWindow.log.removeChild(logWindow.log.firstChild);
            }
            e.preventDefault();
        }
    }, "false");
    
    // Parent closing
    window.addEventListener("unload", function() {
        if (logWindow && logWindow.closeEnabled && logWindow.closeEnabled.checked) {
            CPLogDisable = true;
            logWindow.close();
        }
    }, false);
    
    // Log popup closing
    logWindow.addEventListener("unload", function() {
        if (!CPLogDisable) {
            CPLogDisable = !confirm("Click cancel to stop logging");
        }
    }, false);
}
#endif
