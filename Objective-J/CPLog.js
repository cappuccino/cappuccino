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

var CPLogLevels = ["fatal", "error", "warn", "info", "debug", "trace"];
var _CPLogLevelsInverted = {};
for (var i = 0; i < CPLogLevels.length; i++)
    _CPLogLevelsInverted[CPLogLevels[i]] = i;

// defaults:

var CPLogDefaultTitle = "Cappuccino";
var CPLogDefaultLevel = CPLogLevels[3];
var CPLogDefaultFormatter = function(aParameters, aLevel, aTitle, useColor)
{
    var color = useColor && defaultFormatterColorMap[aLevel];
    var important = {"fatal":true,"error":true,"warn":true}[aLevel];

    // for unimportant messages colorize just the level
    if (!important && color)
        aLevel = "\0"+color+"(" + aLevel + "\0)";

    aLevel = aLevel ? ' [' + aLevel + ']' : '';

    // use sprintf if param 0 is a string and there is more than one param. otherwise just convert param 0 to a string
    var aString = (typeof aParameters[0] === "string" && aParameters.length > 1) ? exports.sprintf.apply(null, aParameters) : String(aParameters[0]);

    var now = new Date();
    var message = exports.sprintf("%4d-%02d-%02d %02d:%02d:%02d.%03d %s%s: %s",
        now.getFullYear(), now.getMonth(), now.getDate(),
        now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds(),
        aTitle, aLevel, aString);

    // for important messages colorize entire message
    if (important && color)
        message = "\0"+color+"(" + message + "\0)";

    return message;
}

var defaultFormatterColorMap = {
    "fatal": "red",
    "error": "red",
    "warn" : "yellow",
    "info" : "green",
    "debug": "cyan",
    "trace": "blue"
};

#if COMMONJS
// attempt to get a better default title based on the command line name
try {
    if (require("system").args[0])
        CPLogDefaultTitle = require("file").basename(require("system").args[0]);
} catch (e) {
}
#endif

// main Logger constructor / API:
function CreateLogger(aTitle)
{
    // public

    var self = function() { self._dispatch(arguments, null, _title); };

    // logger.error, logger.info, logger.warn
    for (var i = 0; i < CPLogLevels.length; i++)
        self[CPLogLevels[i]] = (function(level) { return function() { self._dispatch(arguments, level, _title); }; })(CPLogLevels[i]);

    self.createLogger = function()
    {
        return CreateLogger.apply(this, arguments);;
    }

    // Register a logger for all levels, or up to an optional max level
    self.register = function(aProvider, aMaxLevel)
    {
        if (aMaxLevel === undefined) aMaxLevel = CPLogLevels.length;

        self.registerRange(aProvider, 0, aMaxLevel);
    }

    // Register a logger for a range of levels
    self.registerRange = function(aProvider, aMinLevel, aMaxLevel)
    {
        if (typeof aMinLevel !== "number") aMinLevel = _CPLogLevelsInverted[aMinLevel];
        if (typeof aMaxLevel !== "number") aMaxLevel = _CPLogLevelsInverted[aMaxLevel];

        if (aMinLevel !== undefined && aMaxLevel !== undefined)
            for (var level = aMinLevel; level <= aMaxLevel; level++)
                self.registerSingle(aProvider, level);
    }

    // Register a logger for a single level
    self.registerSingle = function(aProvider, aLevel)
    {
        if (typeof aLevel === "number") aLevel = CPLogLevels[aLevel];

        if (!_registrations[aLevel])
            _registrations[aLevel] = [];

        // prevent duplicate _registrations
        for (var i = 0; i < _registrations[aLevel].length; i++)
            if (_registrations[aLevel][i] === aProvider)
                return;

        _registrations[aLevel].push(aProvider);
    }

    // Unregister a logger for all levels
    self.unregister = function(aProvider)
    {
        for (var aLevel in _registrations)
            for (var i = 0; i < _registrations[aLevel].length; i++)
                if (_registrations[aLevel][i] === aProvider)
                    _registrations[aLevel].splice(i--, 1); // decrement since we're removing an element
    }

    self.setDefaultTitle = function(aTitle)
    {
        CPLogDefaultTitle = aTitle;
    }

    self.setDefaultLevel = function(aLevel)
    {
        CPLogDefaultLevel = aLevel;
    }

    self.setDefaultFormatter = function(aFormatter)
    {
        CPLogDefaultFormatter = aFormatter;
    }

    // private

    var _registrations = {};
    var _title = aTitle;

    self._dispatch = function(aParameters, aLevel, aTitle)
    {
        aParameters = Array.prototype.slice.call(aParameters);

        if (aTitle == undefined) aTitle = CPLogDefaultTitle;
        if (aLevel == undefined) aLevel = CPLogDefaultLevel;

        if (_registrations[aLevel])
            for (var i = 0; i < _registrations[aLevel].length; i++)
                 _registrations[aLevel][i](aParameters, aLevel, aTitle);
    }

    return self;
}

// Default CPLog:
GLOBAL(CPLog) = CreateLogger();

// Deprecated global registration functions
GLOBAL(CPLogRegister)       = function() { CPLog.register.apply(CPLog, arguments); CPLog("CPLogRegister() is deprecated, use CPLog.register()"); };
GLOBAL(CPLogRegisterRange)  = function() { CPLog.registerRange.apply(CPLog, arguments); CPLog("CPLogRegisterRange() is deprecated, use CPLog.registerRange()"); };
GLOBAL(CPLogRegisterSingle) = function() { CPLog.registerSingle.apply(CPLog, arguments); CPLog("CPLogRegisterSingle() is deprecated, use CPLog.registerSingle()"); };

// Included loggers:

// CPLogConsole uses the built in "console" object
// (possibly available in CommonJS environments?)
function CPLogConsoleCreate(formatter)
{
    return function(aString, aLevel, aTitle) {
        if (typeof console === "undefined")
            return;

        var message = (formatter || CPLogDefaultFormatter)(aString, aLevel, aTitle, false);

        var logger = {
            "fatal": "error",
            "error": "error",
            "warn": "warn",
            "info": "info",
            "debug": "debug",
            "trace": "debug"
        }[aLevel] || "log";

        if (console[logger])
            console[logger](message);
    }
}

GLOBAL(CPLogConsole) = CPLogConsoleCreate();
CPLogConsole.create = CPLogConsoleCreate;

// CommonJS specific loggers
#if COMMONJS

// CPLogPrint uses STDOUT to print to console
function CPLogPrintCreate(formatter, stream, useColor)
{
    if (!stream) {
        try {
            stream = require("term").stream;
            useColor = true;
        } catch (e) {
            useColor = false;
            if (typeof print != "undefined")
                stream = { print : print };
        }
    }

    return function(aParameters, aLevel, aTitle) {
        var message = (formatter || CPLogDefaultFormatter)(aParameters, aLevel, aTitle, useColor);
        stream.print(message);
    }
}

GLOBAL(CPLogPrint) = CPLogPrintCreate();
CPLogPrint.create = CPLogPrintCreate;

// Browser specific loggers
#else

// TODO: should this not be global?
GLOBAL(CPLogDisable) = false;

// CPLogAlert uses basic browser confirm()
function CPLogAlertCreate(formatter)
{
    return function(aParameters, aLevel, aTitle) {
        if (typeof confirm != "undefined" && !CPLogDisable) {
            var message = (formatter || CPLogDefaultFormatter)(aParameters, aLevel, aTitle);
            CPLogDisable = !confirm(message + "\n\n(Click cancel to stop log alerts)");
        }
    }
}

GLOBAL(CPLogAlert) = CPLogAlertCreate();
CPLogAlert.create = CPLogAlertCreate;

// CPLogPopup uses a slick popup window in the browser
// TODO: move this into DebugKit
function CPLogPopupCreate(formatter)
{
    var logWindow = null;
    return function(aParameters, aLevel, aTitle) {
        var message = (formatter || CPLogDefaultFormatter)(aString, null, aTitle);

        try {
            if (CPLogDisable || window.open == undefined)
                return;

            if (!logWindow || !logWindow.document)
            {
                logWindow = window.open("", "_blank", "width=600,height=400,status=no,resizable=yes,scrollbars=yes");

                if (!logWindow) {
                    CPLogDisable = !confirm(message + "\n\n(Disable pop-up blocking for CPLog window; Click cancel to stop log alerts)");
                    return;
                }

                _CPLogPopupInit(logWindow);
            }

            var logDiv = logWindow.document.createElement("div");
            logDiv.setAttribute("class", aLevel || "fatal");

            logDiv.appendChild(logWindow.document.createTextNode(message));
            logWindow.log.appendChild(logDiv);

            if (logWindow.focusEnabled.checked)
                logWindow.focus();
            if (logWindow.blockEnabled.checked)
                logWindow.blockEnabled.checked = logWindow.confirm(message+"\nContinue blocking?");
            if (logWindow.scrollEnabled.checked)
                logWindow.scrollToBottom();
        } catch(e) {
            // TODO: some error handling/reporting
        }
    }
}

GLOBAL(CPLogPopup) = CPLogPopupCreate();
CPLogPopup.create = CPLogPopupCreate;

// private CPLogPopup

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

function _CPLogPopupInit(logWindow)
{
    var doc = logWindow.document;
    doc.writeln("<html><head><title></title>"+CPLogPopupStyle+"</head><body></body></html>");

    doc.title = CPLogDefaultTitle + " Run Log";

    var body = doc.getElementsByTagName("body")[0];

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

// guess a good default logger:
#if COMMONJS
GLOBAL(CPLogDefault) = CPLogPrint;
#else
GLOBAL(CPLogDefault) = (typeof console !== "undefined") ? CPLogConsole : CPLogPopup;
#endif
