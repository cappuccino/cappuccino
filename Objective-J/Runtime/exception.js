/*
 * exception.js
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

var OBJJ_EXCEPTION_OUTPUT_STREAM = NULL;

function objj_exception(aName, aReason, aUserInfo)
{
    this.name = aName;
    this.message = aReason;
    this.userInfo = aUserInfo;
    this.__address = _objj_generateObjectHash();
    
    // add rhinoException to get better stack traces
    if (typeof Packages !== "undefined" && Packages && Packages.org)
        this.rhinoException = Packages.org.mozilla.javascript.JavaScriptException(this, null, 0);
}

// make objj_exception a subclass of Error
// later we toll-free bridge Error to CPException
objj_exception.prototype = new Error();

function objj_exception_throw(anException)
{
    throw anException;
}

function objj_exception_report(anException, aSourceFile)
{
    objj_fprintf(OBJJ_EXCEPTION_OUTPUT_STREAM, aSourceFile.path + "\n" + anException);
    
    throw anException;
}

function objj_exception_setOutputStream(aStream)
{
    OBJJ_EXCEPTION_OUTPUT_STREAM = aStream;
}

#if RHINO
objj_exception_setOutputStream(warning_stream);
#elif DEBUG
if (window.console && window.console.error)
    objj_exception_setOutputStream(function (aString) { console.error(aString) } );
else
    objj_exception_setOutputStream(alert);
#else
objj_exception_setOutputStream(function(aString) { });
#endif
