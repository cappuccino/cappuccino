//
//  macros.h
//  xcodecapp-cocoa
//
//  Created by Aparajita Fishman on 11/3/11.
//  Copyright (c) 2011 Victory-Heart Productions. All rights reserved.
//

#ifndef xcodecapp_cocoa_macros_h
#define xcodecapp_cocoa_macros_h

#if DEBUG
#   define DLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

#endif
