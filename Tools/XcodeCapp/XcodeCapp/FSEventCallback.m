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

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{    
    TNXcodeCapp *xcc = (__bridge  TNXcodeCapp *)userData;
    NSArray *paths = (__bridge  NSArray *)eventPaths;
    BOOL usingFileBasedListening = [xcc supportsFileBasedListening];

    for (size_t i = 0; i < numEvents; ++i)
    {
        [xcc updateLastEventId:eventIds[i]];

        FSEventStreamEventFlags flags = eventFlags[i];
        NSString *path = [[paths objectAtIndex:i] stringByStandardizingPath];

        if (usingFileBasedListening)
        {
            if ([xcc pathMatchesIgnoredPaths:path])
                continue;
            
            if ((flags & kFSEventStreamEventFlagItemIsFile) &&
                !([xcc isXibFile:path] || [xcc isObjjFile:path] || [xcc isXCCIgnoreFile:path]))
            {
                continue;
            }

            // Events are not so reliable. For example, moving a folder to the trash is not
            // a deletion. In order to simplify the code, we simply tidy up the project when we receive
            // an event.
            [xcc tidyShadowedFiles];

            BOOL isDirectory = NO;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];

            if (isDirectory)
                continue;

            if (!exists)
            {
                DLog(@"File removed: %@", path);
                [xcc handleFileRemovalAtPath:path];
            }
            else
            {
                DLog(@"File modified/added: %@", path);
                [xcc handleFileModificationAtPath:path notify:YES];
            }
        }
        else
        {
            // We should drop support for Snow Leopard soon.

            BOOL isDirectory = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];

            // If for some reasons the path is not a directory,
            // we don't want to deal with it in this mode.
            if (!isDirectory)
                continue;

            [xcc tidyShadowedFiles];

            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *subpaths = [fm contentsOfDirectoryAtPath:path error:NULL];

            for (NSString *subpath in subpaths)
            {
                NSString *fullPath = [path stringByAppendingPathComponent:subpath];

                if ([xcc pathMatchesIgnoredPaths:fullPath] ||
                    !([xcc isXibFile:fullPath] || [xcc isObjjFile:fullPath] || [xcc isXCCIgnoreFile:fullPath]))
                {
                    continue;
                }

                NSDate *lastModifiedDate = [xcc lastModificationDateForPath:fullPath];
                NSDictionary *fileAttributes = [fm attributesOfItemAtPath:fullPath error:nil];
                NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];

                if ([fileModDate compare:lastModifiedDate] == NSOrderedDescending)
                {
                    [xcc updateLastModificationDate:fileModDate forPath:fullPath];
                    [xcc handleFileModificationAtPath:fullPath notify:YES];
                }
            }
        }
    }

    [xcc updateUserDefaultsWithLastEventId];
}
