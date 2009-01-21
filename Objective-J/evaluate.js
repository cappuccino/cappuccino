/*
 * evaluate.js
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

var objj_included_files = { };  
    
var FRAGMENT_CODE   = 1,

    FRAGMENT_FILE   = 1 << 2,
    FRAGMENT_LOCAL  = 1 << 3;
    
function objj_fragment()
{
    this.info       = NULL;
    this.type       = 0;
    this.context    = NULL;
    this.bundle     = NULL;
    this.file       = NULL;
}

#define EVALUATION_PERIOD 3000

function objj_context()
{
    this.fragments  = [];
    this.scheduled  = NO;
    this.blocked    = NO;
}

#define SET_CONTEXT(aFragment, aContext) aFragment.context = aContext
#define GET_CONTEXT(aFragment) aFragment.context

#define SET_TYPE(aFragment, aType) aFragment.type = (aType)
#define GET_TYPE(aFragment) aFragment.type

#define GET_CODE(aFragment) aFragment.info
#define SET_CODE(aFragment, aCode) aFragment.info = (aCode)

#define GET_PATH(aFragment) aFragment.info
#define SET_PATH(aFragment, aPath) aFragment.info = aPath

#define GET_BUNDLE(aFragment) aFragment.bundle
#define SET_BUNDLE(aFragment, aBundle) aFragment.bundle = aBundle

#define GET_FILE(aFragment) aFragment.file
#define SET_FILE(aFragment, aFile) aFragment.file = aFile

#define IS_FILE(aFragment) (aFragment.type & FRAGMENT_FILE)
#define IS_LOCAL(aFragment) (aFragment.type & FRAGMENT_LOCAL)

function fragment_create_code(aCode, aBundle, aFile)
{
    var fragment = new objj_fragment();
    
    SET_TYPE(fragment, FRAGMENT_CODE);
    SET_CODE(fragment, aCode);
    SET_BUNDLE(fragment, aBundle);
    SET_FILE(fragment, aFile);
    
    return fragment;
}

function fragment_create_file(aPath, aBundle, isLocal, aFile)
{
    var fragment = new objj_fragment();
    
    SET_TYPE(fragment, FRAGMENT_FILE | (FRAGMENT_LOCAL * isLocal));
    SET_PATH(fragment, aPath);
    SET_BUNDLE(fragment, aBundle);
    SET_FILE(fragment, aFile);
    
    return fragment;
}

objj_context.prototype.evaluate = function()
{
    this.scheduled = NO;

    // If we're blocked by IO, then just reschedule.
    if (this.blocked)
        return this.schedule();
    
    // If not, begin the evaluation loop.    
    var sleep = NO,
        start = new Date(),
        fragments = this.fragments;
    
    while (!sleep && fragments.length)
    {
        var fragment = fragments.pop();
            
        if (IS_FILE(fragment))
            sleep = fragment_evaluate_file(fragment);
        else
            sleep = fragment_evaluate_code(fragment);
        
        // Sleep evaluation if we've been at it too long to avoid 
        // unresponsive script errors.
        sleep = sleep || ((new Date() - start) > EVALUATION_PERIOD);
    }
    
    if (sleep)
        this.schedule();
    
    else if (this.didCompleteCallback)
        this.didCompleteCallback(this);
}

objj_context.prototype.schedule = function()
{
    if (this.scheduled)
        return;
    
    this.scheduled = YES;
    
    var context = this;
    
    window.setNativeTimeout(function () { context.evaluate(); }, 0);
}

objj_context.prototype.pushFragment = function(aFragment)
{
    SET_CONTEXT(aFragment, this);
    
    this.fragments.push(aFragment);
}

function fragment_evaluate_code(aFragment)
{
    var compiled;
    
    OBJJ_CURRENT_BUNDLE = GET_BUNDLE(aFragment);
    
    try
    {
#if RHINO
        compiled = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, "function(){"+GET_CODE(aFragment)+"}", GET_FILE(aFragment).path, 0, null);
#else
        compiled = new Function(GET_CODE(aFragment));
#endif
    }
    catch(anException)
    {
        objj_exception_report(anException, GET_FILE(aFragment));
    }
    
    try
    {
        compiled();
    }
    catch(anException)
    {
        objj_exception_report(anException, GET_FILE(aFragment));
    }
    
    return NO;
}

function fragment_evaluate_file(aFragment)
{
    var context = GET_CONTEXT(aFragment),
        requiresSleep = YES;
        
    // Make us IO Blocked until we receive the file.
    context.blocked = YES;
    
    objj_request_file(GET_PATH(aFragment), IS_LOCAL(aFragment), function(aFile)
    {
        // Use the captured value from the closure.  If objj_request_file 
        // returns immediately, then this will cause us to avoid breaking, 
        // but if it doesn't, then this will have no effect.
        requiresSleep = NO;
        
        // We've received the file, so no longer block execution.
        context.blocked = NO;
        
        // FIXME: We need to actually support this, and handle it better 
        // as well.
        if (aFile == OBJJ_NO_FILE)
            objj_alert("uh oh!");

        // If this file has already been included, skip it and bail.
        if (objj_included_files[aFile.path])
            return;
        
        // If not, then mark it as included, for future imports.
        objj_included_files[aFile.path] = YES;
        
        // Grab the file's fragments if it has them, or preprocess it if not.
        if (!aFile.fragments)
            aFile.fragments = objj_preprocess(aFile.contents, aFile.bundle, aFile, OBJJ_PREPROCESSOR_DEBUG_SYMBOLS);
        
        var fragments = aFile.fragments,
            count = fragments.length,
            directory = aFile.path.substr(0, aFile.path.lastIndexOf('/') + 1);

        // Put the individual fragments at the head of the evaluation 
        // stack to be evaluated.
        while (count--)
        {
            var fragment = fragments[count];
        
            if (IS_FILE(fragment))
            {
                if (IS_LOCAL(fragment))
                    SET_PATH(fragment, directory + GET_PATH(fragment));
                
                objj_request_file(GET_PATH(fragment), IS_LOCAL(fragment), NULL);
            }
    
            context.pushFragment(fragment);
        }
    });
    
    return requiresSleep;
}

function objj_import(aPath, isLocal, didCompleteCallback)
{
    var context = new objj_context();
    
    context.didCompleteCallback = didCompleteCallback;
    context.pushFragment(fragment_create_file(aPath, new objj_bundle(""), isLocal, NULL));
        
    context.evaluate();
}
