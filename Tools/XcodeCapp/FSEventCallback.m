/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2011  Antoine Mercadal (<primalmotion@archipelproject.org>)
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
#import "macros.h"


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
        [xcc updateLastEventId:eventIds[i]];

        FSEventStreamEventFlags flags = eventFlags[i];

        NSString *path = [[(NSArray *)eventPaths objectAtIndex:i] stringByStandardizingPath];

        if (useFileBasedListening)
        {
            BOOL conditionIsFile        = flags & kFSEventStreamEventFlagItemIsFile;
            BOOL conditionIsDirectory   = NO;
            BOOL conditionIsIgnored     = [xcc isPathMatchingIgnoredPaths:path];
            BOOL conditionIsValidFile   = [xcc isXIBFile:path] || [xcc isObjJFile:path] || [xcc isXCCIgnoreFile:path];
            BOOL conditionPathExists    = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&conditionIsDirectory];

            if (conditionIsIgnored)
                continue;

            if (conditionIsFile && !conditionIsValidFile)
                continue;

            // Events are not so reliable. For example, moving a folder to the trash is not
            // a deletion. In order to simplify the code, we simply tidyUp the project when we receive
            // an event.
            [xcc tidyShadowedFiles];

            if (conditionIsDirectory)
                continue;

            if (!conditionPathExists)
            {
                DLog(@"File removed: %@", path);
                [xcc handleFileRemoval:path];
            }
            else
            {
                DLog(@"File modified/added: %@", path);
                [xcc handleFileModification:path notify:YES];
            }
        }
        else
        {
            // We should drop support for Snow Leopard soon.

            BOOL isDir = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

            // If for some reasons the path is not a directory,
            // we don't want to deal with it in this mode.
            if (!isDir)
                continue;

            [xcc tidyShadowedFiles];

            NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];

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
    }

    [xcc updateUserDefaultsWithLastEventId];
}
