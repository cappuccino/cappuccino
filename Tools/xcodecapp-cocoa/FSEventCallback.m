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

#import "AppController.h"
#import "FSEventCallback.h"


/*!
 This is the FSEvent callback for 10.7
 */
void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{    
    TNXCodeCapp *xcc = (TNXCodeCapp *)userData;
    BOOL useFileBasedListening = [xcc supportsFileBasedListening];
    size_t i;
    
    for (i = 0; i < numEvents; i++)
    {
        NSString *path = [[(NSArray *)eventPaths objectAtIndex:i] stringByStandardizingPath];

        if (useFileBasedListening)
        {
            // kFSEventStreamEventFlagItemIsFile = 0x00010000
            if (!(eventFlags[i] & 0x00010000)
                || [xcc isPathMatchingIgnoredPaths:path]
                || (![xcc isXIBFile:path] && ![xcc isObjJFile:path] && ![xcc isXCCIgnoreFile:path]))
                continue;
            
            // kFSEventStreamEventFlagItemRemoved = 0x00000200
            if (eventFlags[i] & 0x00000200)
                [xcc handleFileRemoval:path];
            else
                [xcc handleFileModification:path notify:YES];
        }
        else
        {
            NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];

            // Uncomment to test under 10.7
            // BOOL isDir;
            // [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
            // if (!isDir)
            //    continue;

            [xcc tidyShadowedFiles:path];

            for (NSString *subpath in subpaths)
            {
                NSString *fullPath = [[NSString stringWithFormat:@"%@/%@", path, subpath] stringByStandardizingPath];

                if ([xcc isPathMatchingIgnoredPaths:fullPath]
                    || (![xcc isXIBFile:fullPath] && ![xcc isObjJFile:fullPath] && ![xcc isXCCIgnoreFile:fullPath]))
                    continue;

                NSDate *lastModifiedDate = [xcc lastModificationDateForPath:fullPath];
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
                NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];

                if ([fileModDate compare:lastModifiedDate] == NSOrderedDescending)
                {
                    [xcc updateLastModificationDate:fileModDate forPath:fullPath];
                    [xcc handleFileModification:fullPath notify:YES];
                }
            }
        }

        [xcc updateLastEventId:eventIds[i]];
    }
}
