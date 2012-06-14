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
            if (!(flags & kFSEventStreamEventFlagItemIsFile) || 
                [xcc isPathMatchingIgnoredPaths:path]        ||
                (![xcc isXIBFile:path] && ![xcc isObjJFile:path] && ![xcc isXCCIgnoreFile:path]))
            {
                continue;
            }

            if (flags & kFSEventStreamEventFlagItemIsFile &&
                flags & kFSEventStreamEventFlagItemRemoved)
            {
                if ([xcc isObjJFile:path])
                {
                    [xcc tidyShadowedFiles];
                    continue;
                }
            }

            if (flags & kFSEventStreamEventFlagItemRemoved)
            {
                DLog(@"event type: kFSEventStreamEventFlagItemRemoved for path %@", path);
                [xcc handleFileRemoval:path];
            }

            if (flags & kFSEventStreamEventFlagItemCreated ||
                     flags & kFSEventStreamEventFlagItemModified)
            {
                DLog(@"event type: kFSEventStreamEventFlagItemCreated or kFSEventStreamEventFlagItemModified for path %@", path);
                [xcc handleFileModification:path notify:YES];
            }

            else if ([xcc reactToInodeModification] && 
                     (flags & kFSEventStreamEventFlagItemFinderInfoMod ||
                      flags & kFSEventStreamEventFlagItemXattrMod      ||
                      flags & kFSEventStreamEventFlagItemChangeOwner))
            {
                DLog(@"event type: %@ for path %@", flags, path);
                [xcc handleFileModification:path notify:YES];
            }

            else if ([xcc reactToInodeModification] && 
                     flags & kFSEventStreamEventFlagItemInodeMetaMod)
            {
                DLog(@"event type: kFSEventStreamEventFlagItemInodeMetaMod for path %@", path);
                [xcc handleFileModification:path notify:YES];
            }

            else if (flags & kFSEventStreamEventFlagItemRenamed)
            {
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    DLog(@"event type: kFSEventStreamEventFlagItemRenamed for path %@ (removed origin)", path);
                    [xcc handleFileRemoval:path];
                }
                else
                {
                    DLog(@"event type: kFSEventStreamEventFlagItemRenamed for path %@ (added destination)", path);
                    [xcc handleFileModification:path notify:YES];
                }
            }
        }
        else
        {
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
