/*
 * Includes.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

#if DEBUG
#define DISPLAY_NAME(name) name.displayName = #name
#else
#define DISPLAY_NAME(name)
#endif

#define GLOBAL(name) name

#include "OldBrowserCompatibility.js"
#include "DebugOptions.js"
#include "json2.js"
#include "sprintf.js"
#include "CPLog.js"
#include "Constants.js"
#include "EventDispatcher.js"
#include "CFHTTPRequest.js"
#include "CFPropertyList.js"
#include "CFDictionary.js"
#include "CFData.js"
#include "CFURL.js"
#include "MarkedStream.js"
#include "CFBundle.js"
#include "StaticResource.js"
#include "Preprocessor.js"
#include "acorn.js"
#include "acornwalk.js"
#include "ObjJAcornCompiler.js"
#include "FileDependency.js"
#include "Executable.js"
#include "FileExecutable.js"
#include "Runtime.js"
#include "Eval.js"
#if defined(DEBUG) || defined(COMMONJS)
#include "Debug.js"
#endif
#include "Bootstrap.js"
