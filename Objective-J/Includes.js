
#define GLOBAL(object) object

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
#include "MarkedStream.js"
#include "CFBundle.js"
#include "StaticResource.js"
#include "Preprocessor.js"
#include "FileDependency.js"
#include "Executable.js"
#include "FileExecutable.js"
#include "FileExecutableSearch.js"
#include "Runtime.js"
#if DEBUG
#include "Debug.js"
#endif
#include "Bootstrap.js"
