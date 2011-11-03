/*
 * This file is a part of program xcodecapp-cocoa
 * Copyright (C) 2011  Antoine Mercadal (primalmotion@archipelproject.org)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "FSEventCallback.h"

/*!
 This is the FSEvent callback
 */
void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    TNXCodeCapp *xcc = (TNXCodeCapp *)userData;
    size_t i;
    
    for(i = 0; i < numEvents; i++)
    {
        NSString *path = [(NSArray *)eventPaths objectAtIndex:i];
        
        if (!(eventFlags[i] & 0x00010000)
            || [xcc isPathMatchingIgnoredPaths:path]
            || (![xcc isXIBFile:path] && ![xcc isObjJFile:path] && ![xcc isXCCIgnoreFile:path]))
            continue;
        
        // 0x00000200 should be  kFSEventStreamEventFlagItemRemoved but for some reason
        // xCode mark this as not recognized.
        if (eventFlags[i] & 0x00000200)
        {
            [xcc handleFileRemoval:path];
        }
        
        else
        {
            NSLog(@"this file has been modified or created");
            [xcc handleFileModification:path notify:YES];
        }
        [xcc updateLastEventId:eventIds[i]];
    }
}