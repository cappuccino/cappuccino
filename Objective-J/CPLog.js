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
GLOBAL(CPLogRegister) = function(aProvider, aMaxLevel, aFormatter)
{
    CPLogRegisterRange(aProvider, CPLogLevels[0], aMaxLevel || CPLogLevels[CPLogLevels.length-1], aFormatter);
}

// Register a logger for a range of levels
GLOBAL(CPLogRegisterRange) = function(aProvider, aMinLevel, aMaxLevel, aFormatter)
{
    var min = _CPLogLevelsInverted[aMinLevel];
    var max = _CPLogLevelsInverted[aMaxLevel];

    if (min !== undefined && max !== undefined && min <= max)
        for (var i = min; i <= max; i++)
            CPLogRegisterSingle(aProvider, CPLogLevels[i], aFormatter);
}

// Register a logger for a single level
GLOBAL(CPLogRegisterSingle) = function(aProvider, aLevel, aFormatter)
{
    if (!_CPLogRegistrations[aLevel])
        _CPLogRegistrations[aLevel] = [];

    // prevent duplicate registrations, but change formatter
    for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
        if (_CPLogRegistrations[aLevel][i][0] === aProvider)
        {
            _CPLogRegistrations[aLevel][i][1] = aFormatter;
            return;
        }

    _CPLogRegistrations[aLevel].push([aProvider, aFormatter]);
}

GLOBAL(CPLogUnregister) = function(aProvider) {
    for (var aLevel in _CPLogRegistrations)
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
            if (_CPLogRegistrations[aLevel][i][0] === aProvider)
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
    var message = (typeof parameters[0] == "string" && parameters.length > 1) ? exports.sprintf.apply(null, parameters) : String(parameters[0]);

    if (_CPLogRegistrations[aLevel])
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
        {
            var logger = _CPLogRegistrations[aLevel][i];
            logger[0](message, aLevel, aTitle, logger[1]);
        }
}

// Setup CPLog() and CPLog.xxx() aliases

GLOBAL(CPLog) = function() { _CPLogDispatch(arguments); }

for (var i = 0; i < CPLogLevels.length; i++)
    CPLog[CPLogLevels[i]] = (function(level) { return function() { _CPLogDispatch(arguments, level); }; })(CPLogLevels[i]);

// Helpers functions:

var _CPFormatLogMessage = function(aString, aLevel, aTitle)
{
    var now = new Date();
    aLevel = ( aLevel == null ? '' : ' [' + CPLogColorize(aLevel, aLevel) + ']' );

    if (typeof exports.sprintf == "function")
        return exports.sprintf("%4d-%02d-%02d %02d:%02d:%02d.%03d %s%s: %s",
            now.getFullYear(), now.getMonth() + 1, now.getDate(),
            now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds(),
            aTitle, aLevel, aString);
    else
        return now + " " + aTitle + aLevel + ": " + aString;
}

// Loggers:

// CPLogConsole uses the built in "console" object
GLOBAL(CPLogConsole) = function(aString, aLevel, aTitle, aFormatter)
{
    if (typeof console != "undefined")
    {
        var message = (aFormatter || _CPFormatLogMessage)(aString, aLevel, aTitle);

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

var levelColorMap = {
    "fatal": "red",
    "error": "red",
    "warn" : "yellow",
    "info" : "green",
    "debug": "cyan",
    "trace": "blue"
}

try {
    var SYSTEM = require("system");
    var FILE = require("file");
    if (SYSTEM.args[0])
        CPLogDefaultTitle = FILE.basename(SYSTEM.args[0]);
} catch (e) {
}

var stream;

GLOBAL(CPLogColorize) = function(aString, aLevel)
{
    if (stream)
    {
        // Try to determine if a colorizing stanza is already open, they can't be nested
        if (/^.*\x00\w+\([^\x00]*$/.test(aString))
            return aString;
        else
            return "\0" + (levelColorMap[aLevel] || "info") + "(" + aString + "\0)";
    }
    else
        return aString;
}

GLOBAL(CPLogPrint) = function(aString, aLevel, aTitle, aFormatter)
{
    if (stream === undefined) {
        try {
            stream = require("narwhal/term").stream;
        } catch (e) {
            stream = null;
        }
    }

    var formatter = aFormatter || _CPFormatLogMessage;

    if (stream) {
        if (aLevel == "fatal" || aLevel == "error" || aLevel == "warn")
            stream.print(CPLogColorize(formatter(aString, aLevel, aTitle), aLevel));
        else
            stream.print(formatter(aString, aLevel, aTitle));
    } else if (typeof print != "undefined") {
        print(formatter(aString, aLevel, aTitle))
    }
}

#else

// A stub to allow the same formatter to be used for both stream and browser output
GLOBAL(CPLogColorize) = function(aString, aLevel)
{
    return aString;
}

// CPLogAlert uses basic browser alert() functions
GLOBAL(CPLogAlert) = function(aString, aLevel, aTitle, aFormatter)
{
    if (typeof alert != "undefined" && !CPLogDisable)
    {
        var message = (aFormatter || _CPFormatLogMessage)(aString, aLevel, aTitle);
        CPLogDisable = !confirm(message + "\n\n(Click cancel to stop log alerts)");
    }
}

// CPLogPopup uses a slick popup window in the browser:
var CPLogWindow = null;
GLOBAL(CPLogPopup) = function(aString, aLevel, aTitle, aFormatter)
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

        var message = (aFormatter || _CPFormatLogMessage)(aString, aFormatter ? aLevel : null, aTitle);

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

var CPLogPopupStyle ='<style type="text/css" media="screen"> \
body{font:10px Monaco,Courier,"Courier New",monospace,mono;padding-top:15px;} \
div > .fatal,div > .error,div > .warn,div > .info,div > .debug,div > .trace{display:none;overflow:hidden;white-space:pre;padding:0px 5px 0px 5px;margin-top:2px;-moz-border-radius:5px;-webkit-border-radius:5px;} \
div[wrap="yes"] > div{white-space:normal;} \
.fatal{background-color:#ffb2b3;} \
.error{background-color:#ffe2b2;} \
.warn{background-color:#fdffb2;} \
.info{background-color:#e4ffb2;} \
.debug{background-color:#a0e5a0;} \
.trace{background-color:#99b9ff;} \
.enfatal .fatal,.enerror .error,.enwarn .warn,.eninfo .info,.endebug .debug,.entrace .trace{display:block;} \
div#header{background-color:rgba(240,240,240,0.82);position:fixed;top:0px;left:0px;width:100%;border-bottom:1px solid rgba(0,0,0,0.33);text-align:center;} \
ul#enablers{display:inline-block;margin:1px 15px 0 15px;padding:2px 0 2px 0;} \
ul#enablers li{display:inline;padding:0px 5px 0px 5px;margin-left:4px;-moz-border-radius:5px;-webkit-border-radius:5px;} \
[enabled="no"]{opacity:0.25;} \
ul#options{display:inline-block;margin:0 15px 0px 15px;padding:0 0px;} \
ul#options li{margin:0 0 0 0;padding:0 0 0 0;display:inline;} \
</style>';

function _CPLogInitPopup(logWindow)
{
    var doc = logWindow.document;

    // HACK so that head is available below:
    doc.writeln("<html><head><title></title>"+CPLogPopupStyle+"</head><body></body></html>");

    doc.title = CPLogDefaultTitle + " Run Log";

    var head = doc.getElementsByTagName("head")[0];
    var body = doc.getElementsByTagName("body")[0];

    var base = window.location.protocol + "//" + window.location.host + window.location.pathname;
    base = base.substring(0,base.lastIndexOf("/")+1);

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


#if COMMONJS
CPLogDefault = CPLogPrint;
#else
CPLogDefault = (typeof window === "object" && window.console) ? CPLogConsole : CPLogPopup;
#endif
