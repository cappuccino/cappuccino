/*
 * CFError.js
 * Objective-J
 *
 * Created by Andrew Hankinson.
 * Copyright 2014, Andrew Hankinson.
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

GLOBAL(kCFErrorLocalizedDescriptionKey) = "CPLocalizedDescription";
GLOBAL(kCFErrorLocalizedFailureReasonKey) = "CPLocalizedFailureReason";
GLOBAL(kCFErrorLocalizedRecoverySuggestionKey) = "CPLocalizedRecoverySuggestion";
GLOBAL(kCFErrorDescriptionKey) = "CPDescription";
GLOBAL(kCFErrorUnderlyingErrorKey) = "CPUnderlyingError";

GLOBAL(kCFErrorURLKey) = "CPURL";
GLOBAL(kCFErrorFilePathKey) = "CPFilePath";

// GLOBAL(kCFErrorDomainPOSIX) = "";
// GLOBAL(kCFErrorDomainOSStatus) = "";
// GLOBAL(kCFErrorDomainMach) = "";
GLOBAL(kCFErrorDomainCappuccino) = "CPCappuccinoErrorDomain";
GLOBAL(kCFErrorDomainCocoa) = kCFErrorDomainCappuccino;


GLOBAL(CFError) = function(/* CFString */ domain, /* int */ code, /* CFDictionary */ userInfo)
{
    this._domain = domain || NULL;
    this._code = code || 0;
    this._userInfo = userInfo || new CFDictionary();
    this._UID = objj_generateObjectUID();
};

CFError.prototype.domain = function()
{
    return this._domain;
};

DISPLAY_NAME(CFError.prototype.domain);

CFError.prototype.code = function()
{
    return this._code;
};

DISPLAY_NAME(CFError.prototype.code);

/*
    This follows the same logic to generate a description as the "real" CFError.
*/
CFError.prototype.description = function()
{
    var localizedDesc = this._userInfo.valueForKey(kCFErrorLocalizedDescriptionKey);
    if (localizedDesc)
        return localizedDesc;

    var reason = this._userInfo.valueForKey(kCFErrorLocalizedFailureReasonKey);
    if (reason)
    {
        var operationFailedStr = "The operation couldn\u2019t be completed. " + reason;
        return operationFailedStr;
    }

    // @TODO Add the bundle localized domain handler.
    var result = "",
        desc = this._userInfo.valueForKey(kCFErrorDescriptionKey);
    if (desc)
    {
        // we have a description key.
        var result = "The operation couldn\u2019t be completed. (error " + this._code + " - " + desc + ")";
    }
    else
    {
        // just use error and code;
        var result = "The operation couldn\u2019t be completed. (error " + this._code + ")";
    }

    return result;
};

DISPLAY_NAME(CFError.prototype.description);

CFError.prototype.failureReason = function()
{
    return this._userInfo.valueForKey(kCFErrorLocalizedFailureReasonKey);
};

DISPLAY_NAME(CFError.prototype.failureReason);

CFError.prototype.recoverySuggestion = function()
{
    return this._userInfo.valueForKey(kCFErrorLocalizedRecoverySuggestionKey);
};

DISPLAY_NAME(CFError.prototype.recoverySuggestion);

CFError.prototype.userInfo = function ()
{
    return this._userInfo;
};

DISPLAY_NAME(CFError.prototype.userInfo);

/*
    CFError Bridge Functions
    The "Create" and "Copy" in the function names do not have any meaning
    in Cappuccino; they are bridged here for compatibility reasons only.
*/
GLOBAL(CFErrorCreate) = function(/* String */ domain, /*int */ code, /* CFDictionary */ userInfo)
{
    return new CFError(domain, code, userInfo);
};

GLOBAL(CFErrorCreateWithUserInfoKeysAndValues) = function(/* String */ domain, /* int */ code, /* array */ userInfoKeys, /* array */ userInfoValues, /* int */ numUserInfoValues)
{
    var userInfo = new CFMutableDictionary();
    while (numUserInfoValues--)
        userInfo.setValueForKey(userInfoKeys[numUserInfoValues], userInfoValues[numUserInfoValues]);

    return new CFError(domain, code, userInfo);
};

GLOBAL(CFErrorGetCode) = function(/* CFError */ err)
{
    return err.code();
};

GLOBAL(CFErrorGetDomain) = function(/* CFError */ err)
{
    return err.domain();
};

GLOBAL(CFErrorCopyDescription) = function(/* CFError */ err)
{
    return err.description();
};

GLOBAL(CFErrorCopyUserInfo) = function(/* CFError */ err)
{
    return err.userInfo();
};

GLOBAL(CFErrorCopyFailureReason) = function(/* CFError */ err)
{
    return err.failureReason();
};

GLOBAL(CFErrorCopyRecoverySuggestion) = function(/* CFError */err)
{
    return err.recoverySuggestion();
};
